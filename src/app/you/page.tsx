'use client';

import { useState, useEffect, useMemo } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { useUser, UserButton } from '@clerk/nextjs';
import dynamic from 'next/dynamic';
import {
  MagnifyingGlass,
  Gear,
  Heartbeat,
  MapPin,
  Timer,
  Calendar,
  DotsThree,
  Flame,
  ShareNetwork,
  Trophy,
  Medal,
  CaretRight,
  PersonSimpleRun,
} from '@phosphor-icons/react';

import { getClientCache, setClientCache } from '@/lib/clientCache';

const CATEGORY_METADATA: Record<string, { title: string; unit: string; isDuration: boolean }> = {
  '100m': { title: '100m Run', unit: 's', isDuration: true },
  '1k': { title: '1k Run', unit: 's', isDuration: true },
  '5k': { title: '5k Run', unit: 's', isDuration: true },
  '10k': { title: '10k Run', unit: 's', isDuration: true },
  'half': { title: 'Half Marathon', unit: 's', isDuration: true },
  'marathon': { title: 'Marathon', unit: 's', isDuration: true },
  'longest_run': { title: 'Longest Run', unit: 'KM', isDuration: false },
  'longest_duration': { title: 'Longest Duration', unit: 's', isDuration: true },
  'max_elevation': { title: 'Max Elevation Gain', unit: 'M', isDuration: false },
};

function formatRecordValue(value: number, isDuration: boolean, unit: string): string {
  if (isDuration) {
    const hrs = Math.floor(value / 3600);
    const mins = Math.floor((value % 3600) / 60);
    const secs = Math.floor(value % 60);
    if (hrs > 0) return `${hrs}:${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
    return `${mins}:${String(secs).padStart(2, '0')}`;
  }
  if (unit === 'KM') return `${(value / 1000).toFixed(2)} KM`;
  return `${value.toFixed(0)} ${unit}`;
}

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

type Tab = 'Progress' | 'Activities' | 'Records';

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

interface WeeklySummary {
  dateRange: string;
  stats: {
    distanceKm: number;
    durationS: number;
    avgPaceSPerKm: number;
  };
}

interface StreakInfo {
  currentCount: number;
  longestCount: number;
  lastRunDate: string | null;
}

interface RecordEntry {
  id: string;
  category: string;
  runId: string;
  value: number;
  achievedAt: string;
  rank: number;
}

export default function YouPage() {
  const { user } = useUser();
  const [activeTab, setActiveTab] = useState<Tab>('Progress');
  const [runs, setRuns] = useState<Run[]>([]);
  const [loading, setLoading] = useState(true);
  const [weeklySummary, setWeeklySummary] = useState<WeeklySummary | null>(null);
  const [streakInfo, setStreakInfo] = useState<StreakInfo | null>(null);
  const [records, setRecords] = useState<RecordEntry[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedDate, setSelectedDate] = useState<{ year: number; month: number; day: number } | null>(null);

  useEffect(() => {
    const cachedRuns = getClientCache('you_runs');
    const cachedSummary = getClientCache('you_summary');
    const cachedStreak = getClientCache('you_streak');
    const cachedRecords = getClientCache('you_records');

    if (cachedRuns && cachedSummary && cachedStreak && cachedRecords) {
      setRuns(cachedRuns);
      setWeeklySummary(cachedSummary);
      setStreakInfo(cachedStreak);
      setRecords(cachedRecords);
      setLoading(false);
      return;
    }

    const loadData = async () => {
      try {
        const tz = typeof Intl !== 'undefined' ? Intl.DateTimeFormat().resolvedOptions().timeZone : 'UTC';
        const results = await Promise.allSettled([
          fetch('/api/runs?limit=50'),
          fetch(`/api/summary/weekly?tz=${encodeURIComponent(tz)}`),
          fetch('/api/streak'),
          fetch('/api/records'),
        ]);
        const [runsResult, summaryResult, streakResult, recordsResult] = results;
        if (runsResult.status === 'fulfilled' && runsResult.value.ok) {
          const data = await runsResult.value.json();
          const runsData = data.runs || [];
          setRuns(runsData);
          setClientCache('you_runs', runsData);
        }
        if (summaryResult.status === 'fulfilled' && summaryResult.value.ok) {
          const summaryData = await summaryResult.value.json();
          setWeeklySummary(summaryData);
          setClientCache('you_summary', summaryData);
        }
        if (streakResult.status === 'fulfilled' && streakResult.value.ok) {
          const streakData = await streakResult.value.json();
          setStreakInfo(streakData);
          setClientCache('you_streak', streakData);
        }
        if (recordsResult.status === 'fulfilled' && recordsResult.value.ok) {
          const recordsData = await recordsResult.value.json();
          setRecords(recordsData);
          setClientCache('you_records', recordsData);
        }
      } catch (e) {
        console.error('Failed to load data:', e);
      } finally {
        setLoading(false);
      }
    };
    loadData();
  }, []);

  const userName = user?.fullName || user?.firstName || 'Runner';

  // Build calendar data for current month
  const now = new Date();
  const currentYear = now.getFullYear();
  const currentMonth = now.getMonth();
  const monthName = now.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });

  const runDates = useMemo(() => {
    const dates = new Set<string>();
    runs.forEach(r => {
      const d = new Date(r.startTime);
      dates.add(`${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`);
    });
    return dates;
  }, [runs]);

  const calendarDays = useMemo(() => {
    const firstDay = new Date(currentYear, currentMonth, 1);
    const lastDay = new Date(currentYear, currentMonth + 1, 0);
    const startOffset = (firstDay.getDay() + 6) % 7; // Monday-based
    const days: { date: number; inMonth: boolean; hasRun: boolean; isToday: boolean }[] = [];

    // Prev month padding
    const prevMonth = new Date(currentYear, currentMonth, 0);
    for (let i = startOffset - 1; i >= 0; i--) {
      days.push({
        date: prevMonth.getDate() - i,
        inMonth: false,
        hasRun: false,
        isToday: false,
      });
    }

    // Current month
    for (let d = 1; d <= lastDay.getDate(); d++) {
      const key = `${currentYear}-${currentMonth}-${d}`;
      days.push({
        date: d,
        inMonth: true,
        hasRun: runDates.has(key),
        isToday: d === now.getDate(),
      });
    }

    // Next month padding to fill remaining cells
    const remaining = 7 - (days.length % 7);
    if (remaining < 7) {
      for (let d = 1; d <= remaining; d++) {
        days.push({ date: d, inMonth: false, hasRun: false, isToday: false });
      }
    }

    return days;
  }, [currentYear, currentMonth, runDates]);

  // Weekly distance chart data (past 12 weeks)
  const weeklyDistances = useMemo(() => {
    const weeks: { label: string; km: number }[] = [];
    for (let w = 11; w >= 0; w--) {
      const weekEnd = new Date();
      weekEnd.setDate(weekEnd.getDate() - w * 7);
      const weekStart = new Date(weekEnd);
      weekStart.setDate(weekStart.getDate() - 7);

      let totalKm = 0;
      runs.forEach(r => {
        const d = new Date(r.startTime);
        if (d >= weekStart && d < weekEnd) {
          totalKm += r.distanceM / 1000;
        }
      });

      const monthLabel = weekEnd.toLocaleDateString('en-US', { month: 'short' }).toUpperCase();
      weeks.push({ label: monthLabel, km: totalKm });
    }
    return weeks;
  }, [runs]);

  const maxKm = Math.max(...weeklyDistances.map(w => w.km), 0.1);

  // Filter activities for search
  const filteredRuns = useMemo(() => {
    let list = runs;
    if (selectedDate) {
      list = list.filter(r => {
        const d = new Date(r.startTime);
        return d.getFullYear() === selectedDate.year &&
               d.getMonth() === selectedDate.month &&
               d.getDate() === selectedDate.day;
      });
    }
    if (!searchQuery.trim()) return list;
    const q = searchQuery.toLowerCase();
    return list.filter(r => {
      const title = r.title || '';
      const date = new Date(r.startTime).toLocaleDateString();
      return title.toLowerCase().includes(q) || date.includes(q);
    });
  }, [runs, searchQuery, selectedDate]);

  // Count streak activities this month
  const streakActivities = runs.filter(r => {
    const d = new Date(r.startTime);
    return d.getMonth() === currentMonth && d.getFullYear() === currentYear;
  }).length;

  const tabs: Tab[] = ['Progress', 'Activities', 'Records'];

  return (
    <div className="flex flex-col min-h-screen bg-background text-foreground select-none">
      {/* Header */}
      <header className="flex items-center justify-between px-4 py-3">
        <h1 className="text-xl font-bold text-foreground">You</h1>
        <div className="flex items-center gap-4">
          <UserButton
            appearance={{
              elements: {
                userButtonAvatarBox: "w-7 h-7"
              }
            }}
          />
          <Gear size={22} className="text-muted-foreground" />
        </div>
      </header>

      {/* Tab Switcher */}
      <div className="flex items-center border-b border-border px-4">
        {tabs.map(tab => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`flex-1 py-2.5 text-center text-sm font-semibold transition-colors relative ${
              activeTab === tab ? 'text-foreground' : 'text-muted-foreground'
            }`}
          >
            {tab}
            {activeTab === tab && (
              <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-primary" />
            )}
          </button>
        ))}
      </div>

      {/* Tab Content */}
      <main className="flex-1 overflow-y-auto hide-scrollbar">
        {loading ? (
          <div className="flex flex-col items-center justify-center py-32 gap-3">
            <Heartbeat className="animate-spin text-primary" size={28} />
            <span className="text-xs text-muted-foreground">Loading...</span>
          </div>
        ) : (
          <>
            {/* PROGRESS TAB */}
            {activeTab === 'Progress' && (
              <div className="flex flex-col pt-6 pb-24">
                {/* This Week Summary */}
                <div className="px-4 pb-4">
                  <h3 className="text-base font-bold text-foreground mb-2">This week</h3>
                  <div className="flex items-end gap-6">
                    <div>
                      <span className="text-[10px] text-muted-foreground font-medium block uppercase tracking-wider">Distance</span>
                      <span className="text-lg font-black text-foreground tabular-nums">
                        {weeklySummary ? weeklySummary.stats.distanceKm.toFixed(1) : '0'} <span className="text-[10px] font-bold">km</span>
                      </span>
                    </div>
                    <div>
                      <span className="text-[10px] text-muted-foreground font-medium block uppercase tracking-wider">Time</span>
                      <span className="text-lg font-black text-foreground tabular-nums">
                        {weeklySummary ? formatDuration(weeklySummary.stats.durationS) : '0m'}
                      </span>
                    </div>
                    <div>
                      <span className="text-[10px] text-muted-foreground font-medium block uppercase tracking-wider">Elev Gain</span>
                      <span className="text-lg font-black text-foreground tabular-nums">
                        0 <span className="text-[10px] font-bold">m</span>
                      </span>
                    </div>
                  </div>
                </div>

                {/* Bar Chart — Past 12 Weeks */}
                <div className="px-4 pb-4 border-b border-border">
                  <span className="text-[10px] text-muted-foreground font-semibold uppercase tracking-wider block mb-3">Past 12 weeks</span>
                  <div className="relative h-32 flex items-end gap-1">
                    {/* Y-axis labels */}
                    <div className="absolute right-0 top-0 bottom-0 flex flex-col justify-between text-[9px] text-muted-foreground tabular-nums">
                      <span>{maxKm.toFixed(1)} km</span>
                      <span>{(maxKm / 2).toFixed(1)} km</span>
                      <span>0 km</span>
                    </div>

                    {/* Bars */}
                    <div className="flex items-end gap-0.5 flex-1 pr-12">
                      {weeklyDistances.map((week, i) => {
                        const heightPct = maxKm > 0 ? (week.km / maxKm) * 100 : 0;
                        return (
                          <div key={i} className="flex-1 flex flex-col items-center gap-1">
                            <div className="w-full relative" style={{ height: '100px' }}>
                              <div
                                style={{ height: `${heightPct}%` }}
                                className="absolute bottom-0 w-full bg-primary rounded-t-sm transition-all duration-300"
                              />
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                  {/* X-axis labels */}
                  <div className="flex gap-0.5 mt-1 pr-12">
                    {weeklyDistances.map((week, i) => (
                      <div key={i} className="flex-1 text-center">
                        {i % 4 === 0 && (
                          <span className="text-[8px] text-muted-foreground">{week.label}</span>
                        )}
                      </div>
                    ))}
                  </div>
                </div>

                {/* Calendar */}
                <div className="px-4 py-4">
                  <div className="flex items-center justify-between mb-3">
                    <h3 className="text-base font-bold text-foreground">{monthName}</h3>
                  </div>

                  {/* Streak Info */}
                  <div className="flex gap-6 mb-4">
                    <div>
                      <span className="text-[10px] text-muted-foreground font-medium block uppercase tracking-wider">Your Streak</span>
                      <span className="text-base font-black text-foreground tabular-nums">
                        {streakInfo?.currentCount || 0} <span className="text-[10px] font-bold">Weeks</span>
                      </span>
                    </div>
                    <div>
                      <span className="text-[10px] text-muted-foreground font-medium block uppercase tracking-wider">Streak Activities</span>
                      <span className="text-base font-black text-foreground tabular-nums">{streakActivities}</span>
                    </div>
                  </div>

                  {/* Calendar Grid */}
                  <div className="grid grid-cols-7 gap-y-1.5 text-center">
                    {['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d, i) => (
                      <span key={i} className="text-[10px] font-semibold text-muted-foreground mb-1">{d}</span>
                    ))}
                    {calendarDays.map((day, i) => (
                      <button
                        key={i}
                        onClick={() => {
                          if (day.inMonth) {
                            setSelectedDate({ year: currentYear, month: currentMonth, day: day.date });
                            setActiveTab('Activities');
                          }
                        }}
                        disabled={!day.inMonth}
                        className="flex items-center justify-center h-9 w-full focus:outline-none cursor-pointer"
                      >
                        <div
                          className={`w-8 h-8 rounded-full flex items-center justify-center text-xs font-semibold transition-colors ${
                            !day.inMonth
                              ? 'text-muted-foreground/40'
                              : day.isToday
                              ? 'border-2 border-primary text-primary font-bold'
                              : day.hasRun
                              ? 'bg-primary text-white hover:bg-primary/90'
                              : 'text-foreground hover:bg-secondary'
                          }`}
                        >
                          {day.date}
                        </div>
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* RECORDS TAB */}
            {activeTab === 'Records' && (
              <div className="flex flex-col gap-3 px-4 pt-4 pb-24 animate-page-enter">
                {records.length === 0 ? (
                  <div className="flex flex-col items-center justify-center py-20 text-center">
                    <Trophy size={48} className="text-muted-foreground mb-4" />
                    <p className="font-semibold text-foreground mb-1">No personal records yet</p>
                    <p className="text-xs text-muted-foreground max-w-xs leading-normal">
                      Complete a run with distance tracking to set your first personal best.
                    </p>
                  </div>
                ) : (
                  <div className="flex flex-col gap-2">
                    {records.map((rec) => {
                      const meta = CATEGORY_METADATA[rec.category] || { title: rec.category, unit: '', isDuration: false };
                      return (
                        <div
                          key={rec.id}
                          className="bg-[#1a1a1a]/40 border border-white/[0.04] rounded-2xl p-4 flex items-center justify-between transition-colors hover:bg-white/[0.02]"
                        >
                          <div className="flex items-center gap-3">
                            <div className="w-10 h-10 rounded-full bg-primary/10 border border-primary/20 flex items-center justify-center text-primary">
                              <Medal size={20} weight="fill" />
                            </div>
                            <div className="flex flex-col">
                              <span className="text-[10px] text-muted-foreground font-bold uppercase tracking-wider">
                                {meta.title}
                              </span>
                              <span className="text-sm font-black text-foreground mt-0.5">
                                {formatRecordValue(rec.value, meta.isDuration, meta.unit)}
                              </span>
                            </div>
                          </div>
                          {rec.runId && (
                            <Link
                              href={`/runs/${rec.runId}`}
                              className="text-muted-foreground hover:text-foreground flex items-center gap-1 text-xs font-semibold"
                            >
                              <span>View Run</span>
                              <CaretRight size={14} weight="bold" />
                            </Link>
                          )}
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
            )}

            {/* ACTIVITIES TAB */}
            {activeTab === 'Activities' && (
              <div className="flex flex-col pb-24">
                {/* Calendar Date filter active */}
                {selectedDate && (
                  <div className="px-4 pt-3 pb-1 flex items-center justify-between">
                    <span className="text-xs text-muted-foreground">
                      Showing activities on{' '}
                      <span className="font-bold text-foreground">
                        {new Date(selectedDate.year, selectedDate.month, selectedDate.day).toLocaleDateString('en-US', {
                          month: 'short',
                          day: 'numeric',
                          year: 'numeric',
                        })}
                      </span>
                    </span>
                    <button
                      onClick={() => setSelectedDate(null)}
                      className="text-xs text-primary font-bold hover:underline"
                    >
                      Clear Filter
                    </button>
                  </div>
                )}

                {/* Search */}
                <div className="px-4 pt-3 pb-2">
                  <div className="flex items-center gap-2 bg-secondary border border-border rounded-lg px-3 py-2">
                    <MagnifyingGlass size={16} className="text-muted-foreground" />
                    <input
                      type="text"
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      placeholder="Search by keyword"
                      className="bg-transparent text-sm text-foreground placeholder:text-muted-foreground outline-none flex-1"
                    />
                  </div>
                </div>

                {filteredRuns.length === 0 ? (
                  <div className="flex flex-col items-center justify-center py-32 text-center px-8">
                    <MapPin size={48} className="text-muted-foreground mb-4" />
                    <p className="font-semibold text-foreground mb-1">No activities found</p>
                  </div>
                ) : (
                  <div className="flex flex-col animate-page-enter">
                    {filteredRuns.map((run) => {
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
                        <Link
                          key={run.id}
                          href={`/runs/${run.id}`}
                          className="border-b border-border block hover:bg-white/[0.01] active:bg-white/[0.02] transition-colors cursor-pointer"
                        >
                          <article>
                            {/* Athlete line */}
                            <div className="flex items-start justify-between px-4 pt-3 pb-1.5">
                              <div className="flex items-center gap-3">
                                <div className="w-9 h-9 rounded-full bg-secondary border border-border flex items-center justify-center overflow-hidden">
                                  {user?.imageUrl ? (
                                    <img src={user.imageUrl} alt={`${userName}'s profile photo`} className="w-full h-full object-cover" />
                                  ) : (
                                    <span className="text-xs font-bold text-muted-foreground">
                                      {userName.charAt(0).toUpperCase()}
                                    </span>
                                  )}
                                </div>
                                <div className="flex flex-col">
                                  <span className="text-xs font-bold text-foreground uppercase tracking-wide">{userName}</span>
                                  <span className="text-[10px] text-muted-foreground">
                                    {dateStr} at {timeStr} &middot; Trailhead
                                  </span>
                                </div>
                              </div>
                              <button className="p-1 text-muted-foreground"><DotsThree size={18} weight="bold" /></button>
                            </div>

                            {/* Stats */}
                            <div className="px-4 pb-2">
                              <h3 className="text-sm font-bold text-foreground mb-1.5">{title}</h3>
                              <div className="flex gap-5 text-xs">
                                <div>
                                  <span className="text-[9px] text-muted-foreground uppercase block">Distance</span>
                                  <span className="font-black text-foreground tabular-nums">{(run.distanceM / 1000).toFixed(2)} km</span>
                                </div>
                                <div>
                                  <span className="text-[9px] text-muted-foreground uppercase block">Pace</span>
                                  <span className="font-black text-foreground tabular-nums">{formatPace(run.avgPaceSPerKm)}</span>
                                </div>
                                <div>
                                  <span className="text-[9px] text-muted-foreground uppercase block">Time</span>
                                  <span className="font-black text-foreground tabular-nums">{formatDuration(run.durationS)}</span>
                                </div>
                              </div>
                            </div>

                            {/* Map Preview */}
                            <div className="w-full aspect-[16/10] bg-secondary">
                              <FeedMap runId={run.id} />
                            </div>
                          </article>
                        </Link>
                      );
                    })}
                  </div>
                )}
              </div>
            )}
          </>
        )}
      </main>
    </div>
  );
}
