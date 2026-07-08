'use client';

import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import dynamic from 'next/dynamic';
import {
  Play,
  Pause,
  Square,
  MapPin,
  PersonSimpleRun,
  Heartbeat,
  Warning,
  ArrowsOut,
  SpeakerHigh,
  SpeakerSlash,
  PersonSimpleWalk,
} from '@phosphor-icons/react';
import { useRunTracker } from '@/hooks/useRunTracker';
import { addSyncJob } from '@/lib/db';
import { triggerSync } from '@/lib/syncManager';
import { clearClientCache } from '@/lib/clientCache';

const Map = dynamic(() => import('@/components/Map'), { ssr: false });

const springConfig = { type: 'spring' as const, stiffness: 400, damping: 17 };

function formatPace(paceSecPerKm: number): string {
  if (!paceSecPerKm || paceSecPerKm <= 0 || paceSecPerKm > 3600) return '-:--';
  const mins = Math.floor(paceSecPerKm / 60);
  const secs = Math.floor(paceSecPerKm % 60);
  return `${mins}:${String(secs).padStart(2, '0')}`;
}

function formatDuration(durationS: number): string {
  const hrs = Math.floor(durationS / 3600);
  const mins = Math.floor((durationS % 3600) / 60);
  const secs = Math.floor(durationS % 60);
  return [
    String(hrs).padStart(2, '0'),
    String(mins).padStart(2, '0'),
    String(secs).padStart(2, '0')
  ].join(':');
}

export default function RecordPage() {
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [activityType, setActivityType] = useState<'run' | 'walk'>('run');
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const [voiceFeedbackEnabled, setVoiceFeedbackEnabled] = useState(() => {
    if (typeof window !== 'undefined') {
      const saved = localStorage.getItem('voice_feedback_enabled');
      return saved !== null ? saved === 'true' : true;
    }
    return true;
  });

  const handleToggleVoice = () => {
    const next = !voiceFeedbackEnabled;
    setVoiceFeedbackEnabled(next);
    if (typeof window !== 'undefined') {
      localStorage.setItem('voice_feedback_enabled', String(next));
    }
  };

  const [initialLocation, setInitialLocation] = useState<{ lat: number; lng: number; timestamp: number } | null>(null);

  useEffect(() => {
    if (typeof window !== 'undefined' && 'geolocation' in navigator) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setInitialLocation({
            lat: position.coords.latitude,
            lng: position.coords.longitude,
            timestamp: position.timestamp,
          });
        },
        (error) => {
          console.warn('Error fetching initial location:', error);
        },
        { enableHighAccuracy: true, timeout: 5000, maximumAge: 0 }
      );
    }
  }, []);

  const {
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
  } = useRunTracker(() => {
    setErrorMessage('Local draft run was corrupt and had to be cleared.');
  }, voiceFeedbackEnabled);

  const handleStopRun = async () => {
    await stopRun();
    clearClientCache();
    if (currentRunId) {
      await addSyncJob({
        runId: currentRunId,
        attempts: 0,
        lastAttemptTime: 0,
        status: 'pending',
      });
      triggerSync();
    }
  };

  const displayDistance = (distanceM / 1000).toFixed(2);
  const displayPace = formatPace(currentPace);
  const displayDuration = formatDuration(durationS);

  const isActive = runState !== 'idle';

  return (
    <div className="flex flex-col flex-1 min-h-0 w-full bg-background text-foreground select-none relative overflow-hidden">
      {/* Map fills the top section */}
      <div className="relative flex-1 min-h-0 bg-background">
        <div className="absolute inset-0">
          <Map points={isActive ? smoothedPoints : (initialLocation ? [initialLocation] : [])} isFinished={runState === 'stopped'} rounded={false} showLocateButton />
        </div>

        {/* Floating GPS Status Badge */}
        {isActive && (
          <div className="absolute top-4 left-1/2 -translate-x-1/2 z-20">
            <div className="flex items-center gap-2 bg-emerald-900/90 backdrop-blur-sm border border-emerald-700 rounded-full px-4 py-1.5 text-xs font-bold text-emerald-400">
              <div className="flex gap-0.5">
                <div className="w-1 h-3 bg-emerald-400 rounded-sm" />
                <div className="w-1 h-4 bg-emerald-400 rounded-sm" />
                <div className="w-1 h-2.5 bg-emerald-400 rounded-sm" />
                <div className="w-1 h-4 bg-emerald-400 rounded-sm" />
              </div>
              <span>GPS Acquired</span>
            </div>
          </div>
        )}

        {/* Floating expand and voice buttons */}
        <div className="absolute top-4 right-4 z-20 flex flex-col gap-2">
          <button
            onClick={handleToggleVoice}
            aria-label="Toggle voice feedback"
            className="w-10 h-10 rounded-full bg-background/80 backdrop-blur-sm border border-border flex items-center justify-center"
          >
            {voiceFeedbackEnabled ? (
              <SpeakerHigh size={18} className="text-foreground" />
            ) : (
              <SpeakerSlash size={18} className="text-muted-foreground" />
            )}
          </button>
        </div>

        {/* Recovery / Error banners */}
        <AnimatePresence>
          {isRecovering && (
            <motion.div
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              className="absolute top-16 left-4 right-4 z-20 flex items-center gap-2 px-4 py-2 bg-secondary/90 border border-border rounded-xl text-xs"
            >
              <Heartbeat size={14} className="text-primary animate-spin" />
              <span>Recovering previous run...</span>
            </motion.div>
          )}
          {(recoveryError || errorMessage) && (
            <motion.div
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              className="absolute top-16 left-4 right-4 z-20 flex items-center gap-2 px-4 py-2 bg-red-950/80 border border-red-900/50 rounded-xl text-xs text-red-400"
            >
              <Warning size={14} />
              <span>{recoveryError || errorMessage}</span>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Stats Bar */}
      <div className="bg-card border-t border-border px-4 py-3">
        <div className="flex items-center justify-between">
          <div className="flex flex-col items-center flex-1">
            <span className="text-2xl font-black tabular-nums text-foreground">{displayDuration}</span>
            <span className="text-[10px] text-muted-foreground font-medium mt-0.5">Time</span>
          </div>
          <div className="w-px h-8 bg-border" />
          <div className="flex flex-col items-center flex-1">
            <span className="text-2xl font-black tabular-nums text-foreground">{displayPace}</span>
            <span className="text-[10px] text-muted-foreground font-medium mt-0.5">Split avg. (/km)</span>
          </div>
          <div className="w-px h-8 bg-border" />
          <div className="flex flex-col items-center flex-1">
            <span className="text-2xl font-black tabular-nums text-foreground">{displayDistance}</span>
            <span className="text-[10px] text-muted-foreground font-medium mt-0.5">Distance (km)</span>
          </div>
        </div>
      </div>

      {/* Control Area */}
      <div className="bg-card border-t border-border px-6 pt-3 pb-10 flex flex-col items-center gap-3">
        {/* GPS Points counter when active */}
        {isActive && (
          <div className="flex items-center gap-1.5 text-[10px] text-muted-foreground mb-1">
            <MapPin size={10} />
            <span>{rawPoints.length} GPS points captured</span>
          </div>
        )}

        <div className="flex items-center justify-center gap-6">
          {/* Run Type Indicator (left) */}
          <div className="w-16 h-16 flex flex-col items-center justify-center relative">
            {runState === 'idle' && (
              <>
                <button
                  onClick={() => setDropdownOpen(!dropdownOpen)}
                  className="flex flex-col items-center gap-1 focus:outline-none"
                >
                  <div className="w-12 h-12 rounded-full bg-amber-800/80 hover:bg-amber-800 transition-colors flex items-center justify-center border border-amber-600/30">
                    {activityType === 'run' ? (
                      <PersonSimpleRun size={24} className="text-amber-200" />
                    ) : (
                      <PersonSimpleWalk size={24} className="text-amber-200" />
                    )}
                  </div>
                  <span className="text-[9px] text-muted-foreground font-semibold capitalize">{activityType}</span>
                </button>

                {dropdownOpen && (
                  <div className="absolute bottom-16 left-1/2 -translate-x-1/2 bg-popover border border-border shadow-xl rounded-xl py-1.5 min-w-[90px] z-50 flex flex-col">
                    <button
                      onClick={() => {
                        setActivityType('run');
                        setDropdownOpen(false);
                      }}
                      className={`flex items-center gap-2 px-3 py-2 text-xs hover:bg-muted text-left w-full ${activityType === 'run' ? 'text-primary font-bold' : 'text-foreground'}`}
                    >
                      <PersonSimpleRun size={16} />
                      <span>Run</span>
                    </button>
                    <button
                      onClick={() => {
                        setActivityType('walk');
                        setDropdownOpen(false);
                      }}
                      className={`flex items-center gap-2 px-3 py-2 text-xs hover:bg-muted text-left w-full ${activityType === 'walk' ? 'text-primary font-bold' : 'text-foreground'}`}
                    >
                      <PersonSimpleWalk size={16} />
                      <span>Walk</span>
                    </button>
                  </div>
                )}
              </>
            )}
          </div>

          {/* Main Action Button (center) */}
          {runState === 'idle' && (
            <motion.button
              onClick={startRun}
              whileTap={{ scale: 0.95 }}
              transition={springConfig}
              className="w-20 h-20 rounded-full bg-primary flex items-center justify-center shadow-lg shadow-primary/30"
              aria-label="Start run"
            >
              <Play size={36} weight="fill" className="text-white" />
            </motion.button>
          )}

          {runState === 'running' && (
            <motion.button
              onClick={pauseRun}
              whileTap={{ scale: 0.95 }}
              transition={springConfig}
              className="w-20 h-20 rounded-full bg-foreground flex items-center justify-center shadow-lg"
              aria-label="Pause run"
            >
              <Pause size={36} weight="fill" className="text-background" />
            </motion.button>
          )}

          {runState === 'paused' && (
            <div className="flex items-center gap-5">
              <motion.button
                onClick={resumeRun}
                whileTap={{ scale: 0.95 }}
                transition={springConfig}
                className="w-20 h-20 rounded-full bg-primary flex items-center justify-center shadow-lg shadow-primary/30"
                aria-label="Resume run"
              >
                <Play size={36} weight="fill" className="text-white" />
              </motion.button>
              <motion.button
                onClick={handleStopRun}
                whileTap={{ scale: 0.95 }}
                transition={springConfig}
                className="w-16 h-16 rounded-full bg-secondary border border-border flex items-center justify-center"
                aria-label="Stop run"
              >
                <Square size={24} weight="fill" className="text-foreground" />
              </motion.button>
            </div>
          )}

          {runState === 'stopped' && (
            <motion.button
              onClick={resetTracker}
              whileTap={{ scale: 0.95 }}
              transition={springConfig}
              className="px-6 py-3 rounded-full bg-primary text-white text-sm font-bold flex items-center gap-2"
              aria-label="Start new run"
            >
              <PersonSimpleRun size={16} />
              <span>New Run</span>
            </motion.button>
          )}

          {/* Right Placeholder */}
          <div className="w-16 h-16" />
        </div>

        {/* Status pills */}
        <AnimatePresence>
          {runState === 'running' && (
            <motion.span
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.9 }}
              className="flex items-center gap-1.5 px-3 py-1 bg-green-500/10 border border-green-500/30 rounded-full text-[10px] font-semibold text-green-400"
            >
              <span className="w-1.5 h-1.5 rounded-full bg-green-500 animate-gps-pulse" />
              Recording
            </motion.span>
          )}
          {runState === 'paused' && (
            <motion.span
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.9 }}
              className="flex items-center gap-1.5 px-3 py-1 bg-amber-500/10 border border-amber-500/30 rounded-full text-[10px] font-semibold text-amber-400"
            >
              <span className="w-1.5 h-1.5 rounded-full bg-amber-500" />
              Paused
            </motion.span>
          )}
          {runState === 'stopped' && (
            <motion.span
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.9 }}
              className="flex items-center gap-1.5 px-3 py-1 bg-primary/10 border border-primary/30 rounded-full text-[10px] font-semibold text-primary"
            >
              Workout Saved
            </motion.span>
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}
