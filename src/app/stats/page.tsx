'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useTheme } from 'next-themes';
import { 
  ArrowLeft, 
  Heartbeat, 
  TrendUp, 
  TrendDown, 
  MapPin, 
  Timer, 
  Compass, 
  Calendar 
} from '@phosphor-icons/react';
import { 
  LineChart, 
  Line, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer 
} from 'recharts';

interface Run {
  id: string;
  startTime: string;
  distanceM: number;
  durationS: number;
  avgPaceSPerKm: number;
}

export default function StatsPage() {
  const { theme } = useTheme();
  const [runs, setRuns] = useState<Run[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadStatsData() {
      try {
        const res = await fetch('/api/runs?limit=100'); // Fetch up to 100 recent runs for trends
        if (res.ok) {
          const data = await res.json();
          // Sort chronologically for chart display
          const chronological = [...data.runs].reverse();
          setRuns(chronological);
        }
      } catch (err) {
        console.error('Error loading stats data:', err);
      } finally {
        setLoading(false);
      }
    }
    loadStatsData();
  }, []);

  // Aggregates
  const totalRuns = runs.length;
  const totalDistanceKm = runs.reduce((sum, r) => sum + r.distanceM, 0) / 1000;
  const totalDurationS = runs.reduce((sum, r) => sum + r.durationS, 0);
  
  // Average pace overall
  const avgPaceOverallS = totalDistanceKm > 0 ? totalDurationS / totalDistanceKm : 0;
  
  const formatPace = (paceSecPerKm: number): string => {
    if (!paceSecPerKm || paceSecPerKm <= 0) return '-:--';
    const mins = Math.floor(paceSecPerKm / 60);
    const secs = Math.floor(paceSecPerKm % 60);
    return `${mins}:${String(secs).padStart(2, '0')}`;
  };

  const formatHours = (seconds: number): string => {
    const hrs = (seconds / 3600).toFixed(1);
    return `${hrs}h`;
  };

  // Chart data formatting
  const chartData = runs.map((run) => {
    const dateObj = new Date(run.startTime);
    const dateLabel = dateObj.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    const distKm = parseFloat((run.distanceM / 1000).toFixed(2));
    const paceMin = parseFloat((run.avgPaceSPerKm / 60).toFixed(2));
    
    return {
      date: dateLabel,
      distance: distKm,
      pace: paceMin,
    };
  });

  // Recharts styling tokens based on theme
  const gridColor = theme === 'dark' ? '#2d2d2d' : '#e0e0e0';
  const textColor = theme === 'dark' ? '#a0a0a0' : '#666666';
  const tooltipBg = theme === 'dark' ? '#1e1e1e' : '#ffffff';
  const tooltipBorder = theme === 'dark' ? '#2d2d2d' : '#e0e0e0';

  return (
    <div className="flex flex-col items-center justify-between min-h-screen bg-background text-foreground transition-colors duration-300 px-4 py-8 relative select-none">
      {/* Header */}
      <header className="w-full max-w-md flex items-center justify-between mb-6 z-10">
        <Link href="/" className="p-3 rounded-full bg-secondary hover:bg-muted border border-border">
          <ArrowLeft size={20} />
        </Link>
        <span className="text-lg font-bold uppercase tracking-wider text-primary">Analytics</span>
        <div className="w-11" />
      </header>

      {/* Main stats layout */}
      <main className="w-full max-w-md flex-1 flex flex-col gap-6 relative overflow-y-auto mb-16">
        {loading ? (
          <div className="flex-grow flex flex-col items-center justify-center gap-2 py-32">
            <Heartbeat className="animate-spin text-primary" size={32} />
            <span className="text-xs text-muted-foreground">Generating metrics...</span>
          </div>
        ) : totalRuns === 0 ? (
          <div className="flex-grow flex flex-col items-center justify-center py-32 text-center">
            <Compass size={48} className="text-muted-foreground mb-4 animate-bounce" />
            <p className="font-semibold text-muted-foreground">No data points collected</p>
            <p className="text-xs text-muted-foreground/60 max-w-xs mt-1">Metrics and pace charts will render once you complete a run.</p>
          </div>
        ) : (
          <>
            {/* Overview Aggregates Card */}
            <div className="w-full p-5 bg-card border border-border rounded-2xl shadow-sm flex flex-col gap-4">
              <span className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider mb-1">Lifetime Summary</span>
              <div className="grid grid-cols-3 gap-2 divide-x divide-border/40">
                <div className="flex flex-col items-center">
                  <span className="text-[10px] font-semibold text-muted-foreground mb-1">Distance</span>
                  <span className="font-black text-xl text-primary tabular-nums">
                    {totalDistanceKm.toFixed(1)} <span className="text-[10px] font-bold">KM</span>
                  </span>
                </div>
                <div className="flex flex-col items-center">
                  <span className="text-[10px] font-semibold text-muted-foreground mb-1">Time</span>
                  <span className="font-black text-xl text-foreground tabular-nums">
                    {formatHours(totalDurationS)}
                  </span>
                </div>
                <div className="flex flex-col items-center">
                  <span className="text-[10px] font-semibold text-muted-foreground mb-1">Runs</span>
                  <span className="font-black text-xl text-foreground tabular-nums">
                    {totalRuns}
                  </span>
                </div>
              </div>

              <div className="border-t border-border/40 pt-4 flex justify-between items-center text-xs">
                <span className="font-semibold text-muted-foreground flex items-center gap-1">
                  <Compass size={14} /> Overall Avg Pace
                </span>
                <span className="font-bold text-foreground">{formatPace(avgPaceOverallS)} /KM</span>
              </div>
            </div>

            {/* Distance trend chart */}
            <div className="w-full p-5 bg-card border border-border rounded-2xl shadow-sm flex flex-col gap-3">
              <span className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Distance over time (KM)</span>
              <div className="w-full h-48 mt-2 text-xs">
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={chartData} margin={{ top: 5, right: 5, left: -20, bottom: 5 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke={gridColor} />
                    <XAxis dataKey="date" stroke={textColor} tickLine={false} />
                    <YAxis stroke={textColor} tickLine={false} />
                    <Tooltip 
                      contentStyle={{ backgroundColor: tooltipBg, borderColor: tooltipBorder, borderRadius: '8px', color: theme === 'dark' ? '#fff' : '#000' }}
                      labelClassName="font-semibold text-[10px] text-muted-foreground"
                    />
                    <Line 
                      type="monotone" 
                      dataKey="distance" 
                      stroke="#ff5a3c" 
                      strokeWidth={3} 
                      activeDot={{ r: 6 }} 
                      dot={{ r: 3 }}
                    />
                  </LineChart>
                </ResponsiveContainer>
              </div>
            </div>

            {/* Pace trend chart */}
            <div className="w-full p-5 bg-card border border-border rounded-2xl shadow-sm flex flex-col gap-3">
              <span className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider">Pace trend (MIN/KM)</span>
              <div className="w-full h-48 mt-2 text-xs">
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={chartData} margin={{ top: 5, right: 5, left: -20, bottom: 5 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke={gridColor} />
                    <XAxis dataKey="date" stroke={textColor} tickLine={false} />
                    <YAxis stroke={textColor} tickLine={false} domain={['auto', 'auto']} reversed />
                    <Tooltip 
                      contentStyle={{ backgroundColor: tooltipBg, borderColor: tooltipBorder, borderRadius: '8px', color: theme === 'dark' ? '#fff' : '#000' }}
                      labelClassName="font-semibold text-[10px] text-muted-foreground"
                    />
                    <Line 
                      type="monotone" 
                      dataKey="pace" 
                      stroke="#ff5a3c" 
                      strokeWidth={3} 
                      activeDot={{ r: 6 }} 
                      dot={{ r: 3 }}
                    />
                  </LineChart>
                </ResponsiveContainer>
              </div>
              <p className="text-[9px] text-muted-foreground text-center italic leading-normal">
                Pace chart is inverted: a lower line represents a faster speed (fewer minutes per kilometer).
              </p>
            </div>
          </>
        )}
      </main>
    </div>
  );
}
