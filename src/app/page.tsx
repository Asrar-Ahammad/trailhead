'use client';

import { useState, useEffect, useCallback } from 'react';
import { useUser } from '@clerk/nextjs';
import Link from 'next/link';
import dynamic from 'next/dynamic';
import {
  MapPin,
  Heartbeat,
  Trophy,
  WifiSlash,
  Flame,
  TrendUp,
  CaretRight,
  PersonSimpleRun,
} from '@phosphor-icons/react';
import { triggerSync, subscribeToSyncStatus } from '@/lib/syncManager';
import { useRouter } from 'next/navigation';
import { getClientCache, setClientCache } from '@/lib/clientCache';

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


  // Subscribe to sync to auto-refresh
  const [streak, setStreak] = useState<{ currentCount: number } | null>(null);

  const loadData = useCallback(async (forceRefresh = false) => {
    if (!forceRefresh) {
      const cachedRuns = getClientCache<Run[]>('home_runs');
      const cachedStreak = getClientCache<{ currentCount: number }>('home_streak');
      if (cachedRuns && cachedStreak) {
        setRuns(cachedRuns);
        setStreak(cachedStreak);
        setLoading(false);
        return;
      }
    }
    try {
      const [runsRes, streakRes] = await Promise.all([
        fetch('/api/runs?limit=20'),
        fetch('/api/streak'),
      ]);

      let runsData = [];
      let streakData = null;

      if (runsRes.ok) {
        const data = await runsRes.json();
        runsData = data.runs || [];
        setRuns(runsData);
        setClientCache('home_runs', runsData);
      }

      if (streakRes.ok) {
        streakData = await streakRes.json();
        setStreak(streakData);
        setClientCache('home_streak', streakData);
      }
    } catch (e) {
      console.error('Failed to load dashboard data:', e);
    } finally {
      setLoading(false);
    }
  }, []);

  // Subscribe to sync to auto-refresh
  useEffect(() => {
    let lastSyncing = false;
    const unsub = subscribeToSyncStatus((status) => {
      if (lastSyncing && !status.isSyncing && status.pendingCount === 0) {
        loadData(true);
      }
      lastSyncing = status.isSyncing;
    });
    triggerSync();
    return unsub;
  }, [loadData]);

  useEffect(() => {
    loadData(false);
  }, [loadData]);

  const userName = user?.fullName || user?.firstName || 'Runner';
  const greeting = (() => {
    const hour = new Date().getHours();
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  })();
  const mostRecentRun = runs[0];

  // Aggregated Stats
  const totalDistanceKm = (runs.reduce((sum, r) => sum + r.distanceM, 0) / 1000).toFixed(1);
  const totalWorkouts = runs.length;
  const streakCount = streak?.currentCount || 0;

  return (
    <div className="flex flex-col min-h-screen bg-background text-foreground select-none">
      {/* Offline Banner */}
      {!isOnline && (
        <div className="bg-amber-600 text-white px-4 py-2 flex items-center justify-center gap-2 text-xs font-bold transition-all duration-300">
          <WifiSlash size={14} />
          <span>Offline — runs will sync when connection returns</span>
        </div>
      )}

      {/* Greeting Header */}
      <header className="px-6 pt-8 pb-4 flex items-center justify-between">
        <div className="flex flex-col">
          <span className="text-xs text-muted-foreground font-bold uppercase tracking-wider">Welcome back</span>
          <h1 className="text-lg sm:text-2xl font-black tracking-tight text-foreground mt-0.5 leading-tight">
            {greeting}, {userName}!
          </h1>
        </div>
        <Link
          href="/you"
          className="w-10 h-10 rounded-full bg-secondary border border-border flex items-center justify-center overflow-hidden cursor-pointer active:scale-95 transition-transform"
          aria-label="View Profile"
        >
          {user?.imageUrl ? (
            <img src={user.imageUrl} alt="" className="w-full h-full object-cover" />
          ) : (
            <span className="text-sm font-bold text-muted-foreground">
              {userName.charAt(0).toUpperCase()}
            </span>
          )}
        </Link>
      </header>

      <main className="flex-1 overflow-y-auto hide-scrollbar px-6 pb-24 flex flex-col gap-6">
        {loading ? (
          <div className="flex flex-col items-center justify-center py-32 gap-3">
            <Heartbeat className="animate-spin text-primary" size={28} />
            <span className="text-xs text-muted-foreground">Loading dashboard...</span>
          </div>
        ) : (
          <>
            {/* Stats Dashboard Grid */}
            <section className="flex flex-col gap-3">
              <h2 className="text-xs font-black text-muted-foreground uppercase tracking-widest">
                Workout Stats
              </h2>
              <div className="grid grid-cols-3 gap-3">
                {/* Distance Widget */}
                <div className="bg-[#1a1a1a]/40 border border-white/[0.04] rounded-2xl p-4 flex flex-col gap-2 relative overflow-hidden">
                  <div className="flex items-center justify-between text-muted-foreground">
                    <span className="text-[9px] font-bold uppercase tracking-wider">Distance</span>
                    <TrendUp size={16} className="text-primary" />
                  </div>
                  <div className="flex items-baseline gap-0.5 mt-1">
                    <span className="text-lg font-black tracking-tight">{totalDistanceKm}</span>
                    <span className="text-[10px] text-muted-foreground font-bold">km</span>
                  </div>
                </div>

                {/* Workouts Widget */}
                <div className="bg-[#1a1a1a]/40 border border-white/[0.04] rounded-2xl p-4 flex flex-col gap-2 relative overflow-hidden">
                  <div className="flex items-center justify-between text-muted-foreground">
                    <span className="text-[9px] font-bold uppercase tracking-wider">Runs</span>
                    <Trophy size={16} className="text-amber-500" />
                  </div>
                  <div className="flex items-baseline gap-0.5 mt-1">
                    <span className="text-lg font-black tracking-tight">{totalWorkouts}</span>
                    <span className="text-[10px] text-muted-foreground font-bold">logged</span>
                  </div>
                </div>

                {/* Streak Widget */}
                <div className="bg-[#1a1a1a]/40 border border-white/[0.04] rounded-2xl p-4 flex flex-col gap-2 relative overflow-hidden">
                  <div className="flex items-center justify-between text-muted-foreground">
                    <span className="text-[9px] font-bold uppercase tracking-wider">Streak</span>
                    <Flame size={16} weight="fill" className="text-orange-500" />
                  </div>
                  <div className="flex items-baseline gap-0.5 mt-1">
                    <span className="text-lg font-black tracking-tight">{streakCount}</span>
                    <span className="text-[10px] text-muted-foreground font-bold">days</span>
                  </div>
                </div>
              </div>
            </section>

            {/* Most Recent Run Widget */}
            <section className="flex flex-col gap-3">
              <h2 className="text-xs font-black text-muted-foreground uppercase tracking-widest">
                Most Recent Activity
              </h2>
              {mostRecentRun ? (
                <div className="bg-[#1a1a1a]/70 border border-white/[0.06] rounded-2xl p-5 flex flex-col gap-4 shadow-xl">
                  {/* Header info */}
                  <div className="flex items-start justify-between">
                    <div className="flex flex-col gap-0.5">
                      <span className="text-[10px] text-primary font-black uppercase tracking-wider">
                        {new Date(mostRecentRun.startTime).toLocaleDateString('en-US', {
                          month: 'short',
                          day: 'numeric',
                          year: 'numeric',
                        })}
                      </span>
                      <h3 className="text-lg font-black tracking-tight text-foreground">
                        {mostRecentRun.title || 'Workout Session'}
                      </h3>
                    </div>
                    <div className="w-8 h-8 rounded-full bg-primary/10 border border-primary/20 flex items-center justify-center text-primary">
                      <PersonSimpleRun size={18} weight="fill" />
                    </div>
                  </div>

                  {/* Metrics grid */}
                  <div className="grid grid-cols-2 gap-4 py-2 border-y border-white/[0.04]">
                    <div className="flex flex-col">
                      <span className="text-[9px] text-muted-foreground font-bold uppercase tracking-wider">Distance</span>
                      <span className="text-base font-black text-foreground mt-0.5">
                        {(mostRecentRun.distanceM / 1000).toFixed(2)} km
                      </span>
                    </div>
                    <div className="flex flex-col">
                      <span className="text-[9px] text-muted-foreground font-bold uppercase tracking-wider">Duration</span>
                      <span className="text-base font-black text-foreground mt-0.5">
                        {formatDuration(mostRecentRun.durationS)}
                      </span>
                    </div>
                    <div className="flex flex-col">
                      <span className="text-[9px] text-muted-foreground font-bold uppercase tracking-wider">Average Pace</span>
                      <span className="text-base font-black text-foreground mt-0.5">
                        {formatPace(mostRecentRun.avgPaceSPerKm)} /km
                      </span>
                    </div>
                    <div className="flex flex-col">
                      <span className="text-[9px] text-muted-foreground font-bold uppercase tracking-wider">Elev Gain</span>
                      <span className="text-base font-black text-foreground mt-0.5">
                        {mostRecentRun.elevationGainM ? `${Math.round(mostRecentRun.elevationGainM)}m` : '0m'}
                      </span>
                    </div>
                  </div>

                  {/* Navigation Button */}
                  <button
                    onClick={() => router.push(`/runs/${mostRecentRun.id}`)}
                    className="w-full bg-primary hover:bg-primary-hover text-white py-3 rounded-xl font-bold text-xs flex items-center justify-center gap-1.5 transition-all shadow-md shadow-primary/20"
                  >
                    <span>View Activity Details & Map</span>
                    <CaretRight size={14} weight="bold" />
                  </button>
                </div>
              ) : (
                <div className="bg-[#1a1a1a]/40 border border-dashed border-white/[0.08] rounded-2xl p-8 flex flex-col items-center text-center gap-4">
                  <MapPin size={32} className="text-muted-foreground" />
                  <div className="flex flex-col gap-1">
                    <p className="font-bold text-foreground text-sm">No activity recorded yet</p>
                    <p className="text-xs text-muted-foreground max-w-xs leading-normal">
                      Track your first run or walk using the recording tool to generate stats and see your details here.
                    </p>
                  </div>
                  <button
                    onClick={() => router.push('/record')}
                    className="bg-primary hover:bg-primary/95 text-white px-5 py-2.5 rounded-xl font-bold text-xs shadow-md shadow-primary/25"
                  >
                    Start Recording
                  </button>
                </div>
              )}
            </section>
          </>
        )}
      </main>
    </div>
  );
}
