'use client';

import { useState, useEffect, useCallback } from 'react';
import { useUser } from '@clerk/nextjs';
import { motion, AnimatePresence } from 'framer-motion';
import dynamic from 'next/dynamic';
import {
  MapPin,
  ThumbsUp,
  ChatCircle,
  ShareNetwork,
  Bell,
  MagnifyingGlass,
  DotsThree,
  Heartbeat,
  Trophy,
  WifiSlash,
} from '@phosphor-icons/react';
import { triggerSync, subscribeToSyncStatus } from '@/lib/syncManager';
import { useRouter } from 'next/navigation';

const FeedMap = dynamic(() => import('@/components/FeedMap'), { ssr: false });

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
  if (hrs > 0) return `${hrs}h ${mins}m ${secs}s`;
  return `${mins}m ${String(secs).padStart(2, '0')}s`;
}

interface Run {
  id: string;
  startTime: string;
  endTime: string;
  distanceM: number;
  durationS: number;
  avgPaceSPerKm: number;
  elevationGainM: number | null;
  title: string | null;
}

export default function Home() {
  const { user } = useUser();
  const router = useRouter();
  const [runs, setRuns] = useState<Run[]>([]);
  const [loading, setLoading] = useState(true);
  const [isOnline, setIsOnline] = useState(true);

  // Connection state
  useEffect(() => {
    if (typeof window !== 'undefined') {
      setIsOnline(window.navigator.onLine);
      const handleOnline = () => { setIsOnline(true); triggerSync(); };
      const handleOffline = () => setIsOnline(false);
      window.addEventListener('online', handleOnline);
      window.addEventListener('offline', handleOffline);
      return () => {
        window.removeEventListener('online', handleOnline);
        window.removeEventListener('offline', handleOffline);
      };
    }
  }, []);

  const loadRuns = useCallback(async () => {
    try {
      const res = await fetch('/api/runs?limit=20');
      if (res.ok) {
        const data = await res.json();
        setRuns(data.runs || []);
      }
    } catch (e) {
      console.error('Failed to load runs:', e);
    } finally {
      setLoading(false);
    }
  }, []);

  // Subscribe to sync to auto-refresh
  useEffect(() => {
    let lastSyncing = false;
    const unsub = subscribeToSyncStatus((status) => {
      if (lastSyncing && !status.isSyncing && status.pendingCount === 0) {
        loadRuns();
      }
      lastSyncing = status.isSyncing;
    });
    triggerSync();
    return unsub;
  }, [loadRuns]);

  useEffect(() => {
    loadRuns();
  }, [loadRuns]);

  const userName = user?.fullName || user?.firstName || 'Runner';

  return (
    <div className="flex flex-col min-h-screen bg-background text-foreground select-none">
      {/* Offline Banner */}
      <AnimatePresence>
        {!isOnline && (
          <motion.div
            initial={{ y: -40, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            exit={{ y: -40, opacity: 0 }}
            transition={springConfig}
            className="bg-amber-600 text-white px-4 py-2 flex items-center justify-center gap-2 text-xs font-bold"
          >
            <WifiSlash size={14} />
            <span>Offline — runs will sync when connection returns</span>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Top Header */}
      <header className="flex items-center justify-between px-4 py-3">
        <h1 className="text-xl font-bold text-foreground">Home</h1>
        <div className="flex items-center gap-4">
          <MagnifyingGlass size={22} className="text-muted-foreground" />
          <div className="relative">
            <Bell size={22} className="text-muted-foreground" />
          </div>
        </div>
      </header>

      {/* Feed */}
      <main className="flex-1 overflow-y-auto hide-scrollbar">
        {loading ? (
          <div className="flex flex-col items-center justify-center py-32 gap-3">
            <Heartbeat className="animate-spin text-primary" size={28} />
            <span className="text-xs text-muted-foreground">Loading activities...</span>
          </div>
        ) : runs.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-32 text-center px-8">
            <MapPin size={48} className="text-muted-foreground mb-4" />
            <p className="font-semibold text-foreground mb-1">No activities yet</p>
            <p className="text-xs text-muted-foreground max-w-xs">
              Head to the Record tab to start your first run. Your activities will appear here.
            </p>
          </div>
        ) : (
          <motion.div
            initial="hidden"
            animate="visible"
            variants={{ visible: { transition: { staggerChildren: 0.06 } } }}
            className="flex flex-col"
          >
            {runs.map((run) => {
              const date = new Date(run.startTime);
              const dateStr = date.toLocaleDateString('en-US', {
                month: 'long',
                day: 'numeric',
                year: 'numeric',
              });
              const timeStr = date.toLocaleTimeString('en-US', {
                hour: 'numeric',
                minute: '2-digit',
                hour12: true,
              });

              const title = run.title || (date.getHours() < 12 ? 'Morning Run' : date.getHours() < 17 ? 'Afternoon Run' : 'Evening Run');

              return (
                <motion.article
                  key={run.id}
                  variants={{
                    hidden: { opacity: 0, y: 20 },
                    visible: { opacity: 1, y: 0 },
                  }}
                  transition={springConfig}
                  className="border-b border-border cursor-pointer active:bg-secondary/50 focus-visible:bg-secondary/50 outline-none transition-colors"
                  onClick={() => router.push(`/runs/${run.id}`)}
                  tabIndex={0}
                  role="button"
                  aria-label={`View details for ${title || 'run'} on ${dateStr}`}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' || e.key === ' ') {
                      e.preventDefault();
                      router.push(`/runs/${run.id}`);
                    }
                  }}
                >
                  {/* Athlete Header */}
                  <div className="flex items-start justify-between px-4 pt-4 pb-2">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full bg-secondary border border-border flex items-center justify-center overflow-hidden">
                        {user?.imageUrl ? (
                          <img src={user.imageUrl} alt="" className="w-full h-full object-cover" />
                        ) : (
                          <span className="text-sm font-bold text-muted-foreground">
                            {userName.charAt(0).toUpperCase()}
                          </span>
                        )}
                      </div>
                      <div className="flex flex-col">
                        <span className="text-sm font-bold text-foreground uppercase tracking-wide">
                          {userName}
                        </span>
                        <span className="text-[11px] text-muted-foreground">
                          {dateStr} at {timeStr} &middot; Trailhead
                        </span>
                      </div>
                    </div>
                    <button className="p-1 text-muted-foreground">
                      <DotsThree size={20} weight="bold" />
                    </button>
                  </div>

                  {/* Activity Title & Stats */}
                  <div className="px-4 pb-3">
                    <h2 className="text-base font-bold text-foreground mb-2">{title}</h2>
                    <div className="flex items-end gap-6">
                      <div>
                        <span className="text-[10px] text-muted-foreground font-medium block uppercase tracking-wider">Distance</span>
                        <span className="text-lg font-black text-foreground tabular-nums">
                          {(run.distanceM / 1000).toFixed(2)} <span className="text-[10px] font-bold">km</span>
                        </span>
                      </div>
                      <div>
                        <span className="text-[10px] text-muted-foreground font-medium block uppercase tracking-wider">Elev Gain</span>
                        <span className="text-lg font-black text-foreground tabular-nums">
                          {run.elevationGainM ? `${Math.round(run.elevationGainM)}` : '0'} <span className="text-[10px] font-bold">m</span>
                        </span>
                      </div>
                      <div>
                        <span className="text-[10px] text-muted-foreground font-medium block uppercase tracking-wider">Pace</span>
                        <span className="text-lg font-black text-foreground tabular-nums">
                          {formatPace(run.avgPaceSPerKm)} <span className="text-[10px] font-bold">/km</span>
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* Map Preview */}
                  <div className="w-full aspect-[16/10] bg-secondary">
                    <FeedMap runId={run.id} />
                  </div>

                </motion.article>
              );
            })}
          </motion.div>
        )}
      </main>
    </div>
  );
}
