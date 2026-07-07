'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { 
  ArrowLeft, 
  Trophy, 
  Medal, 
  Calendar, 
  MapPin, 
  Timer, 
  Compass, 
  Heartbeat 
} from '@phosphor-icons/react';

interface RecordEntry {
  id: string;
  category: string;
  runId: string;
  value: number;
  achievedAt: string;
  rank: number;
}

const CATEGORY_METADATA: Record<string, { title: string; unit: string; isDuration: boolean }> = {
  // Standalone Run categories
  '100m': { title: '100m Run', unit: 's', isDuration: true },
  '1k': { title: '1k Run', unit: 's', isDuration: true },
  '5k': { title: '5k Run', unit: 's', isDuration: true },
  '10k': { title: '10k Run', unit: 's', isDuration: true },
  'half': { title: 'Half Marathon', unit: 's', isDuration: true },
  'marathon': { title: 'Marathon', unit: 's', isDuration: true },
  
  // Best-Effort Segment categories
  '100m_segment': { title: 'Fastest 100m Segment', unit: 's', isDuration: true },
  '1k_segment': { title: 'Fastest 1k Segment', unit: 's', isDuration: true },
  '5k_segment': { title: 'Fastest 5k Segment', unit: 's', isDuration: true },
  '10k_segment': { title: 'Fastest 10k Segment', unit: 's', isDuration: true },
  
  // Custom categories
  'longest_run': { title: 'Longest Run', unit: 'KM', isDuration: false },
  'longest_duration': { title: 'Longest Duration', unit: 's', isDuration: true },
  'max_elevation': { title: 'Max Elevation Gain', unit: 'M', isDuration: false },
};

function formatRecordValue(value: number, isDuration: boolean, unit: string): string {
  if (isDuration) {
    const hrs = Math.floor(value / 3600);
    const mins = Math.floor((value % 3600) / 60);
    const secs = Math.floor(value % 60);
    
    if (hrs > 0) {
      return `${hrs}:${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
    }
    return `${mins}:${String(secs).padStart(2, '0')}`;
  }
  if (unit === 'KM') {
    return `${(value / 1000).toFixed(2)} KM`;
  }
  return `${value.toFixed(0)} ${unit}`;
}

export default function LeaderboardPage() {
  const [records, setRecords] = useState<RecordEntry[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadRecords() {
      try {
        const res = await fetch('/api/records');
        if (res.ok) {
          const data = await res.json();
          setRecords(data);
        }
      } catch (err) {
        console.error('Error fetching personal records:', err);
      } finally {
        setLoading(false);
      }
    }
    loadRecords();
  }, []);

  // Group records by category
  const groupedRecords: Record<string, RecordEntry[]> = {};
  
  // Initialize all defined categories
  Object.keys(CATEGORY_METADATA).forEach(cat => {
    groupedRecords[cat] = [];
  });

  records.forEach(rec => {
    if (groupedRecords[rec.category]) {
      groupedRecords[rec.category].push(rec);
    }
  });

  return (
    <div className="flex flex-col items-center justify-between min-h-screen bg-background text-foreground transition-colors duration-300 px-4 py-8 relative select-none">
      {/* Header */}
      <header className="w-full max-w-md flex items-center justify-between mb-6 z-10">
        <Link href="/" className="p-3 rounded-full bg-secondary hover:bg-muted border border-border">
          <ArrowLeft size={20} />
        </Link>
        <span className="text-lg font-bold uppercase tracking-wider text-primary">Records Leaderboard</span>
        <div className="w-11" />
      </header>

      {/* Main Container */}
      <main className="w-full max-w-md flex-1 flex flex-col gap-6 relative overflow-y-auto mb-16">
        {loading ? (
          <div className="flex-grow flex flex-col items-center justify-center gap-2 py-32">
            <Heartbeat className="animate-spin text-primary" size={32} />
            <span className="text-xs text-muted-foreground">Retrieving personal records...</span>
          </div>
        ) : (
          <div className="flex flex-col gap-6">
            {Object.entries(groupedRecords).map(([category, entries]) => {
              const meta = CATEGORY_METADATA[category];
              if (!meta) return null;

              return (
                <div 
                  key={category} 
                  className="w-full p-5 bg-card border border-border rounded-2xl shadow-sm flex flex-col gap-4"
                >
                  {/* Category Title */}
                  <div className="flex items-center gap-2 border-b border-border/40 pb-3">
                    <Trophy size={18} className="text-primary" />
                    <span className="text-xs font-black uppercase tracking-wider text-foreground">
                      {meta.title}
                    </span>
                  </div>

                  {/* Leaderboard Ranks */}
                  {entries.length === 0 ? (
                    <div className="text-center py-4 text-xs text-muted-foreground italic leading-normal">
                      No records achieved yet.
                    </div>
                  ) : (
                    <div className="flex flex-col gap-3">
                      {entries.slice(0, 3).map((entry, idx) => {
                        const dateStr = new Date(entry.achievedAt).toLocaleDateString('en-US', {
                          month: 'short',
                          day: 'numeric',
                          year: 'numeric',
                        });
                        
                        // Rank color badges
                        const rankColors = [
                          'text-amber-500 bg-amber-500/10 border-amber-500/30', // Gold
                          'text-slate-400 bg-slate-400/10 border-slate-400/30', // Silver
                          'text-amber-700 bg-amber-700/10 border-amber-700/30', // Bronze
                        ];

                        return (
                          <div 
                            key={entry.id} 
                            className="flex items-center justify-between py-1 text-xs"
                          >
                            <div className="flex items-center gap-2.5">
                              <span className={`w-6 h-6 rounded-full border flex items-center justify-center font-bold text-[10px] ${rankColors[entry.rank - 1] || 'text-muted-foreground'}`}>
                                {entry.rank}
                              </span>
                              <div className="flex flex-col">
                                <span className="font-bold text-foreground">
                                  {formatRecordValue(entry.value, meta.isDuration, meta.unit)}
                                </span>
                                <span className="text-[9px] text-muted-foreground flex items-center gap-1 mt-0.5">
                                  <Calendar size={10} /> {dateStr}
                                </span>
                              </div>
                            </div>

                            <Link 
                              href={`/history`}
                              className="text-[10px] font-bold text-primary hover:underline"
                            >
                              View Run
                            </Link>
                          </div>
                        );
                      })}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </main>
    </div>
  );
}
