'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import { 
  saveRunDraft, 
  getActiveRunDraft, 
  deleteRunDraft, 
  addRunPoints, 
  getRunPoints, 
  verifyDraftIntegrity, 
  RunPointDraft, 
  RunDraft 
} from '@/lib/db';

// Haversine formula to compute distance in meters between two coordinates
function haversineDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371e3; // Earth radius in meters
  const phi1 = (lat1 * Math.PI) / 180;
  const phi2 = (lat2 * Math.PI) / 180;
  const deltaPhi = ((lat2 - lat1) * Math.PI) / 180;
  const deltaLambda = ((lon2 - lon1) * Math.PI) / 180;

  const a = 
    Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c; // in meters
}

// Generate simple unique ID
function generateId(): string {
  return typeof crypto !== 'undefined' && crypto.randomUUID 
    ? crypto.randomUUID() 
    : Math.random().toString(36).substring(2, 15);
}

export type RunState = 'idle' | 'running' | 'paused' | 'stopped';

export function useRunTracker(
  onCorruptionDetected?: () => void,
  voiceFeedbackEnabled: boolean = true
) {
  const [runState, setRunState] = useState<RunState>('idle');
  const [currentRunId, setCurrentRunId] = useState<string | null>(null);
  
  // Stats
  const [distanceM, setDistanceM] = useState<number>(0);
  const [durationS, setDurationS] = useState<number>(0);
  const [currentPace, setCurrentPace] = useState<number>(0); // seconds per km
  const [rawPoints, setRawPoints] = useState<RunPointDraft[]>([]);
  const [smoothedPoints, setSmoothedPoints] = useState<{ lat: number; lng: number; timestamp: number }[]>([]);
  
  // Recovery notification state
  const [isRecovering, setIsRecovering] = useState<boolean>(false);
  const [recoveryError, setRecoveryError] = useState<string | null>(null);

  // Splits and Voice feedback tracking refs
  const lastKilometerCrossedRef = useRef<number>(0);
  const elapsedAtLastKmRef = useRef<number>(0);
  const voiceFeedbackEnabledRef = useRef<boolean>(voiceFeedbackEnabled);
  const durationSRef = useRef<number>(0);

  useEffect(() => {
    voiceFeedbackEnabledRef.current = voiceFeedbackEnabled;
  }, [voiceFeedbackEnabled]);

  useEffect(() => {
    durationSRef.current = durationS;
  }, [durationS]);

  // Refs for tracking
  const watchIdRef = useRef<number | null>(null);
  const wakeLockRef = useRef<any>(null); // WakeLockSentinel
  const startTimeRef = useRef<number | null>(null);
  const elapsedBeforePauseRef = useRef<number>(0);
  const tickIntervalRef = useRef<NodeJS.Timeout | null>(null);
  const heartbeatIntervalRef = useRef<NodeJS.Timeout | null>(null);
  
  // Pending points to batch write
  const pendingPointsRef = useRef<RunPointDraft[]>([]);
  const nextSequenceRef = useRef<number>(0);

  // Wake Lock helpers
  const requestWakeLock = useCallback(async () => {
    if (typeof window === 'undefined' || !('wakeLock' in navigator)) return;
    if (document.visibilityState !== 'visible') return;
    try {
      wakeLockRef.current = await (navigator as any).wakeLock.request('screen');
    } catch (err) {
      console.warn('Wake Lock request failed:', err);
    }
  }, []);

  const releaseWakeLock = useCallback(async () => {
    if (wakeLockRef.current) {
      try {
        await wakeLockRef.current.release();
        wakeLockRef.current = null;
      } catch (err) {
        console.warn('Wake Lock release failed:', err);
      }
    }
  }, []);

  // Handle visibility change to re-acquire wake lock
  useEffect(() => {
    const handleVisibilityChange = async () => {
      if (document.visibilityState === 'visible' && runState === 'running') {
        await requestWakeLock();
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);
    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    };
  }, [runState, requestWakeLock]);

  // Heartbeat signal to service worker
  useEffect(() => {
    if (runState === 'running') {
      heartbeatIntervalRef.current = setInterval(() => {
        if ('serviceWorker' in navigator && navigator.serviceWorker.controller) {
          navigator.serviceWorker.controller.postMessage({
            type: 'HEARTBEAT',
            timestamp: Date.now(),
            runId: currentRunId,
          });
        }
      }, 15000); // 15s heartbeat
    } else {
      if (heartbeatIntervalRef.current) {
        clearInterval(heartbeatIntervalRef.current);
        heartbeatIntervalRef.current = null;
      }
    }

    return () => {
      if (heartbeatIntervalRef.current) {
        clearInterval(heartbeatIntervalRef.current);
      }
    };
  }, [runState, currentRunId]);

  // Timer Tick
  useEffect(() => {
    if (runState === 'running') {
      tickIntervalRef.current = setInterval(() => {
        if (startTimeRef.current !== null) {
          const elapsed = Math.floor((Date.now() - startTimeRef.current) / 1000);
          setDurationS(elapsedBeforePauseRef.current + elapsed);
        }
      }, 1000);
    } else {
      if (tickIntervalRef.current) {
        clearInterval(tickIntervalRef.current);
        tickIntervalRef.current = null;
      }
    }

    return () => {
      if (tickIntervalRef.current) {
        clearInterval(tickIntervalRef.current);
      }
    };
  }, [runState]);

  // Save draft run metadata helper
  const saveCurrentDraft = useCallback(async (
    id: string,
    start: number,
    state: RunState,
    dist: number,
    dur: number
  ) => {
    const statusMap: Record<RunState, RunDraft['status']> = {
      idle: 'active',
      running: 'active',
      paused: 'paused',
      stopped: 'completed',
    };
    
    await saveRunDraft({
      id,
      startTime: start,
      endTime: state === 'stopped' ? Date.now() : null,
      distanceM: dist,
      durationS: dur,
      status: statusMap[state] || 'active',
      version: 1,
    });
  }, []);

  // Periodic draft persistence
  useEffect(() => {
    if ((runState === 'running' || runState === 'paused') && currentRunId && startTimeRef.current) {
      const interval = setInterval(() => {
        saveCurrentDraft(
          currentRunId,
          startTimeRef.current!,
          runState,
          distanceM,
          durationS
        );
      }, 5000); // Save state every 5s

      return () => clearInterval(interval);
    }
  }, [runState, currentRunId, distanceM, durationS, saveCurrentDraft]);

  // Coordinates smoothing logic (Moving Average)
  const computeSmoothedPoints = useCallback((points: RunPointDraft[]) => {
    const windowSize = 5;
    const smoothed = points.map((p, idx) => {
      const start = Math.max(0, idx - windowSize + 1);
      const sub = points.slice(start, idx + 1);
      const latAvg = sub.reduce((sum, pt) => sum + pt.lat, 0) / sub.length;
      const lngAvg = sub.reduce((sum, pt) => sum + pt.lng, 0) / sub.length;
      return {
        lat: latAvg,
        lng: lngAvg,
        timestamp: p.timestamp,
      };
    });
    setSmoothedPoints(smoothed);
  }, []);

  // Rolling pace calculation (10-second window)
  const updateRollingPace = useCallback((points: RunPointDraft[]) => {
    if (points.length < 2) {
      setCurrentPace(0);
      return;
    }
    const now = Date.now();
    const windowStart = now - 10000; // last 10 seconds
    const windowPoints = points.filter(p => p.timestamp >= windowStart);

    if (windowPoints.length < 2) {
      // Fallback: use last 2 points overall if not enough points in last 10s
      const lastPoints = points.slice(-2);
      const dist = haversineDistance(
        lastPoints[0].lat,
        lastPoints[0].lng,
        lastPoints[1].lat,
        lastPoints[1].lng
      );
      const timeDiff = (lastPoints[1].timestamp - lastPoints[0].timestamp) / 1000;
      if (dist > 0.1 && timeDiff > 0) {
        const pace = timeDiff / (dist / 1000); // s/km
        setCurrentPace(isFinite(pace) ? pace : 0);
      } else {
        setCurrentPace(0);
      }
      return;
    }

    // Compute total distance covered in the 10s window
    let windowDist = 0;
    for (let i = 1; i < windowPoints.length; i++) {
      windowDist += haversineDistance(
        windowPoints[i-1].lat,
        windowPoints[i-1].lng,
        windowPoints[i].lat,
        windowPoints[i].lng
      );
    }
    const windowTime = (windowPoints[windowPoints.length - 1].timestamp - windowPoints[0].timestamp) / 1000;

    if (windowDist > 0.5 && windowTime > 0) {
      const pace = windowTime / (windowDist / 1000);
      setCurrentPace(isFinite(pace) ? pace : 0);
    } else {
      setCurrentPace(0);
    }
  }, []);

  // Geolocation watch callback handler
  const handleNewPosition = useCallback((position: GeolocationPosition) => {
    const { latitude: lat, longitude: lng, accuracy, speed } = position.coords;
    const timestamp = position.timestamp;

    // Filters:
    // Reject points with poor accuracy (> 30m)
    if (accuracy !== null && accuracy > 30) return;

    // Reject points where computed speed looks like a GPS jump (> 12 m/s)
    if (speed !== null && speed > 12) return;

    setRawPoints((prev) => {
      let deltaD = 0;
      if (prev.length > 0) {
        const lastPt = prev[prev.length - 1];
        deltaD = haversineDistance(lastPt.lat, lastPt.lng, lat, lng);
        
        // Additional protection: calculate speed from last coordinate time delta
        const timeDelta = (timestamp - lastPt.timestamp) / 1000;
        if (timeDelta > 0) {
          const computedSpeed = deltaD / timeDelta;
          if (computedSpeed > 12) {
            // Reject jump
            return prev;
          }
        }
      }

      const newPoint: RunPointDraft = {
        id: generateId(),
        runId: currentRunId || '',
        lat,
        lng,
        elevation: position.coords.altitude,
        timestamp,
        accuracy,
        speed,
        sequence: nextSequenceRef.current++,
      };

      const updated = [...prev, newPoint];
      setDistanceM((d) => {
        const newD = d + deltaD;
        const currentKm = Math.floor(newD / 1000);
        if (currentKm > lastKilometerCrossedRef.current) {
          const kmNumber = currentKm;
          const currentDuration = durationSRef.current;
          const completedSplitDuration = currentDuration - elapsedAtLastKmRef.current;
          
          elapsedAtLastKmRef.current = currentDuration;
          lastKilometerCrossedRef.current = currentKm;

          // Announce via Web Speech API
          if (voiceFeedbackEnabledRef.current && typeof window !== 'undefined' && 'speechSynthesis' in window) {
            const mins = Math.floor(completedSplitDuration / 60);
            const secs = Math.floor(completedSplitDuration % 60);
            const overallPaceMin = Math.floor((currentDuration / (newD / 1000)) / 60);
            const overallPaceSec = Math.floor((currentDuration / (newD / 1000)) % 60);
            
            const message = `Kilometer ${kmNumber} completed in ${mins} minute${mins !== 1 ? 's' : ''} and ${secs} second${secs !== 1 ? 's' : ''}. Current pace is ${overallPaceMin} minute${overallPaceMin !== 1 ? 's' : ''} and ${overallPaceSec} second${overallPaceSec !== 1 ? 's' : ''} per kilometer.`;
            
            const utterance = new SpeechSynthesisUtterance(message);
            window.speechSynthesis.speak(utterance);
          }
        }
        return newD;
      });
      updateRollingPace(updated);
      computeSmoothedPoints(updated);

      // Add to batch queue
      pendingPointsRef.current.push(newPoint);
      if (pendingPointsRef.current.length >= 5) {
        const toSave = [...pendingPointsRef.current];
        pendingPointsRef.current = [];
        addRunPoints(toSave);
      }

      return updated;
    });
  }, [currentRunId, updateRollingPace, computeSmoothedPoints]);

  // Start active run tracking
  const startRun = useCallback(async () => {
    if (runState !== 'idle') return;

    const newId = generateId();
    setCurrentRunId(newId);
    setDistanceM(0);
    setDurationS(0);
    setRawPoints([]);
    setSmoothedPoints([]);
    setCurrentPace(0);
    elapsedBeforePauseRef.current = 0;
    startTimeRef.current = Date.now();
    nextSequenceRef.current = 0;
    pendingPointsRef.current = [];
    lastKilometerCrossedRef.current = 0;
    elapsedAtLastKmRef.current = 0;

    setRunState('running');
    await requestWakeLock();
    await saveCurrentDraft(newId, startTimeRef.current, 'running', 0, 0);

    if (typeof window !== 'undefined' && 'geolocation' in navigator) {
      watchIdRef.current = navigator.geolocation.watchPosition(
        handleNewPosition,
        (err) => console.warn('GPS Watch Error:', err),
        { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
      );
    }
  }, [runState, handleNewPosition, requestWakeLock, saveCurrentDraft]);

  // Pause active run
  const pauseRun = useCallback(async () => {
    if (runState !== 'running') return;

    if (watchIdRef.current !== null) {
      navigator.geolocation.clearWatch(watchIdRef.current);
      watchIdRef.current = null;
    }

    if (startTimeRef.current !== null) {
      elapsedBeforePauseRef.current += Math.floor((Date.now() - startTimeRef.current) / 1000);
      startTimeRef.current = null;
    }

    setRunState('paused');
    await releaseWakeLock();
    
    if (currentRunId) {
      await saveCurrentDraft(
        currentRunId,
        Date.now(), // dummy start to satisfy types, won't corrupt duration
        'paused',
        distanceM,
        durationS
      );
    }
  }, [runState, currentRunId, distanceM, durationS, releaseWakeLock, saveCurrentDraft]);

  // Resume paused run
  const resumeRun = useCallback(async () => {
    if (runState !== 'paused' || !currentRunId) return;

    startTimeRef.current = Date.now();
    setRunState('running');
    await requestWakeLock();

    if (typeof window !== 'undefined' && 'geolocation' in navigator) {
      watchIdRef.current = navigator.geolocation.watchPosition(
        handleNewPosition,
        (err) => console.warn('GPS Watch Error:', err),
        { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
      );
    }
  }, [runState, currentRunId, handleNewPosition, requestWakeLock]);

  // Stop/Finish run tracking
  const stopRun = useCallback(async () => {
    if (runState !== 'running' && runState !== 'paused') return;

    if (watchIdRef.current !== null) {
      navigator.geolocation.clearWatch(watchIdRef.current);
      watchIdRef.current = null;
    }

    await releaseWakeLock();

    // Flush any pending points
    if (pendingPointsRef.current.length > 0) {
      await addRunPoints(pendingPointsRef.current);
      pendingPointsRef.current = [];
    }

    // Save final status as completed
    if (currentRunId) {
      const finalStart = startTimeRef.current || Date.now();
      await saveCurrentDraft(currentRunId, finalStart, 'stopped', distanceM, durationS);
    }

    setRunState('stopped');
  }, [runState, currentRunId, distanceM, durationS, releaseWakeLock, saveCurrentDraft]);

  // Reset tracker state back to idle
  const resetTracker = useCallback(() => {
    setRunState('idle');
    setCurrentRunId(null);
    setDistanceM(0);
    setDurationS(0);
    setRawPoints([]);
    setSmoothedPoints([]);
    setCurrentPace(0);
    setIsRecovering(false);
  }, []);

  const hasRecoveredRef = useRef(false);

  // Recover active/paused drafts on mount
  useEffect(() => {
    if (hasRecoveredRef.current) return;
    
    async function recoverDraft() {
      hasRecoveredRef.current = true;
      setIsRecovering(true);
      try {
        const activeDraft = await getActiveRunDraft();
        if (activeDraft) {
          // Verify integrity checksum
          const isValid = verifyDraftIntegrity(activeDraft);
          if (!isValid) {
            console.warn('Corrupt run draft detected. Deleting.');
            await deleteRunDraft(activeDraft.id);
            if (onCorruptionDetected) onCorruptionDetected();
            setRecoveryError('Corrupt run data was detected and cleared.');
            setIsRecovering(false);
            return;
          }

          // Restore state
          setCurrentRunId(activeDraft.id);
          setDistanceM(activeDraft.distanceM);
          setDurationS(activeDraft.durationS);
          elapsedBeforePauseRef.current = activeDraft.durationS;
          lastKilometerCrossedRef.current = Math.floor(activeDraft.distanceM / 1000);
          elapsedAtLastKmRef.current = activeDraft.durationS;
          
          const points = await getRunPoints(activeDraft.id);
          setRawPoints(points);
          computeSmoothedPoints(points);
          nextSequenceRef.current = points.length;

          if (activeDraft.status === 'active') {
            // Resume tracking automatically
            startTimeRef.current = Date.now();
            setRunState('running');
            await requestWakeLock();
            if (typeof window !== 'undefined' && 'geolocation' in navigator) {
              watchIdRef.current = navigator.geolocation.watchPosition(
                handleNewPosition,
                (err) => console.warn('GPS Watch Error:', err),
                { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
              );
            }
          } else {
            setRunState('paused');
          }
        }
      } catch (err) {
        console.error('Draft recovery failed:', err);
      } finally {
        setIsRecovering(false);
      }
    }

    recoverDraft();

    // Clean up watches on unmount
    return () => {
      if (watchIdRef.current !== null) {
        navigator.geolocation.clearWatch(watchIdRef.current);
      }
    };
  }, [handleNewPosition, computeSmoothedPoints, requestWakeLock, onCorruptionDetected]);

  return {
    runState,
    currentRunId,
    distanceM,
    durationS,
    currentPace,
    rawPoints,
    smoothedPoints,
    isRecovering,
    recoveryError,
    startRun,
    pauseRun,
    resumeRun,
    stopRun,
    resetTracker,
  };
}
