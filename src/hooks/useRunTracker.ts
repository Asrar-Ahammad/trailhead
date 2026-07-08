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
interface WakeLockSentinel {
  release(): Promise<void>;
}
interface WakeLock {
  request(type: 'screen'): Promise<WakeLockSentinel>;
}
interface NavigatorWithWakeLock extends Omit<Navigator, 'wakeLock'> {
  wakeLock?: WakeLock;
}

  const [currentPace, setCurrentPace] = useState<number>(0); // seconds per km
  const [rawPoints, setRawPoints] = useState<RunPointDraft[]>([]);
  const [smoothedPoints, setSmoothedPoints] = useState<{ lat: number; lng: number; timestamp: number }[]>([]);

  const currentRunIdRef = useRef<string | null>(null);
  useEffect(() => {
    currentRunIdRef.current = currentRunId;
  }, [currentRunId]);

  const distanceMRef = useRef<number>(0);
  useEffect(() => {
    distanceMRef.current = distanceM;
  }, [distanceM]);

  const rawPointsRef = useRef<RunPointDraft[]>([]);
  useEffect(() => {
    rawPointsRef.current = rawPoints;
  }, [rawPoints]);
  
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
  const wakeLockRef = useRef<WakeLockSentinel | null>(null);
  const startTimeRef = useRef<number | null>(null);
  const runStartTimeRef = useRef<number | null>(null);
  const elapsedBeforePauseRef = useRef<number>(0);
  const tickIntervalRef = useRef<NodeJS.Timeout | null>(null);
  const heartbeatIntervalRef = useRef<NodeJS.Timeout | null>(null);
  
  // Pending points to batch write
  const pendingPointsRef = useRef<RunPointDraft[]>([]);
  const nextSequenceRef = useRef<number>(0);

  const requestWakeLock = useCallback(async () => {
    if (typeof window === 'undefined' || !('wakeLock' in navigator)) return;
    if (document.visibilityState !== 'visible') return;
    try {
      wakeLockRef.current = await (navigator as NavigatorWithWakeLock).wakeLock!.request('screen');
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

  // Geolocation watch callback handler
  const handleNewPosition = useCallback((position: GeolocationPosition) => {
    const { latitude: lat, longitude: lng, accuracy, speed } = position.coords;
    const timestamp = position.timestamp;

    // Filters:
    // Reject points with poor accuracy (> 30m)
    if (accuracy !== null && accuracy > 30) return;

    // Reject points where computed speed looks like a GPS jump (> 12 m/s)
    if (speed !== null && speed > 12) return;

    const prevPoints = rawPointsRef.current;
    let deltaD = 0;
    if (prevPoints.length > 0) {
      const lastPt = prevPoints[prevPoints.length - 1];
      deltaD = haversineDistance(lastPt.lat, lastPt.lng, lat, lng);
      
      const timeDelta = (timestamp - lastPt.timestamp) / 1000;
      if (timeDelta > 0) {
        const computedSpeed = deltaD / timeDelta;
        if (computedSpeed > 12) return; // Reject jump
      }
    }

    const newPoint: RunPointDraft = {
      id: generateId(),
      runId: currentRunIdRef.current || '',
      lat,
      lng,
      elevation: position.coords.altitude,
      timestamp,
      accuracy,
      speed,
      sequence: nextSequenceRef.current++,
    };

    // Incremental smoothed point calculation (O(1) sliding window of 5)
    const windowSize = 5;
    const lastRawPoints = [...prevPoints.slice(-(windowSize - 1)), newPoint];
    const latAvg = lastRawPoints.reduce((sum, pt) => sum + pt.lat, 0) / lastRawPoints.length;
    const lngAvg = lastRawPoints.reduce((sum, pt) => sum + pt.lng, 0) / lastRawPoints.length;
    const newSmoothedPt = {
      lat: latAvg,
      lng: lngAvg,
      timestamp: newPoint.timestamp,
    };

    // Incremental pace calculation (O(1) sliding window of 10s)
    const tenSecsAgo = Date.now() - 10000;
    const lastRawPointsWithNew = [...prevPoints, newPoint];
    const windowPoints = lastRawPointsWithNew.filter(p => p.timestamp >= tenSecsAgo);
    let pace = 0;
    if (windowPoints.length < 2) {
      const last2 = lastRawPointsWithNew.slice(-2);
      if (last2.length === 2) {
        const dist = haversineDistance(last2[0].lat, last2[0].lng, last2[1].lat, last2[1].lng);
        const timeDiff = (last2[1].timestamp - last2[0].timestamp) / 1000;
        if (dist > 0.1 && timeDiff > 0) {
          const p = timeDiff / (dist / 1000);
          pace = isFinite(p) ? p : 0;
        }
      }
    } else {
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
        const p = windowTime / (windowDist / 1000);
        pace = isFinite(p) ? p : 0;
      }
    }

    // Pure state updates
    setRawPoints(prev => [...prev, newPoint]);
    setSmoothedPoints(prev => [...prev, newSmoothedPt]);
    setCurrentPace(pace);
    setDistanceM(d => d + deltaD);

    // Async side effects (persistence and announcements) outside state updaters
    const newD = distanceMRef.current + deltaD;
    const currentKm = Math.floor(newD / 1000);
    if (currentKm > lastKilometerCrossedRef.current) {
      const kmNumber = currentKm;
      const currentDuration = durationSRef.current;
      const completedSplitDuration = currentDuration - elapsedAtLastKmRef.current;
      
      elapsedAtLastKmRef.current = currentDuration;
      lastKilometerCrossedRef.current = currentKm;

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

    pendingPointsRef.current.push(newPoint);
    if (pendingPointsRef.current.length >= 5) {
      const toSave = [...pendingPointsRef.current];
      pendingPointsRef.current = [];
      addRunPoints(toSave).catch((err) => {
        console.error('Failed to persist points to IndexedDB:', err);
      });
    }
  }, [currentRunId]);

  // Start active run tracking
  const startRun = useCallback(async () => {
    if (runState !== 'idle') return;

    const newId = generateId();
    setCurrentRunId(newId);
    currentRunIdRef.current = newId;
    setDistanceM(0);
    setDurationS(0);
    setRawPoints([]);
    setSmoothedPoints([]);
    setCurrentPace(0);
    elapsedBeforePauseRef.current = 0;
    startTimeRef.current = Date.now();
    runStartTimeRef.current = startTimeRef.current;
    nextSequenceRef.current = 0;
    pendingPointsRef.current = [];
    lastKilometerCrossedRef.current = 0;
    elapsedAtLastKmRef.current = 0;

    setRunState('running');
    await requestWakeLock();
    await saveCurrentDraft(newId, runStartTimeRef.current, 'running', 0, 0);

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
        runStartTimeRef.current || Date.now(),
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
      const finalStart = runStartTimeRef.current || startTimeRef.current || Date.now();
      await saveCurrentDraft(currentRunId, finalStart, 'stopped', distanceM, durationS);
    }

    setRunState('stopped');
  }, [runState, currentRunId, distanceM, durationS, releaseWakeLock, saveCurrentDraft]);

  // Reset tracker state back to idle
  const resetTracker = useCallback(() => {
    setRunState('idle');
    setCurrentRunId(null);
    currentRunIdRef.current = null;
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
          currentRunIdRef.current = activeDraft.id;
          setDistanceM(activeDraft.distanceM);
          setDurationS(activeDraft.durationS);
          runStartTimeRef.current = activeDraft.startTime;
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
  }, [handleNewPosition, computeSmoothedPoints, requestWakeLock, onCorruptionDetected]);

  // Clean up watches on unmount
  useEffect(() => {
    return () => {
      if (watchIdRef.current !== null) {
        navigator.geolocation.clearWatch(watchIdRef.current);
      }
    };
  }, []);

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
