'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import dynamic from 'next/dynamic';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  ArrowLeft, 
  Calendar, 
  MapPin, 
  Timer, 
  Compass, 
  X, 
  ArrowUp, 
  ArrowDown, 
  Heartbeat
} from '@phosphor-icons/react';

const Map = dynamic(() => import('@/components/Map'), { ssr: false });

const springConfig = { type: 'spring' as const, stiffness: 400, damping: 17 };

interface Run {
  id: string;
  startTime: string;
  endTime: string;
  distanceM: number;
  durationS: number;
  avgPaceSPerKm: number;
  elevationGainM: number | null;
  title: string | null;
  aiSummary: string | null;
}

interface RunPoint {
  lat: number;
  lng: number;
  elevation: number | null;
  timestamp: string;
  sequence: number;
}

interface Split {
  km: number;
  timeS: number;
  paceStr: string;
}

// Calculate splits from coordinates
function calculateSplits(points: RunPoint[]): Split[] {
  if (points.length < 2) return [];

  // Sort by sequence
  const sorted = [...points].sort((a, b) => a.sequence - b.sequence);
  const splits: Split[] = [];

  // Earth radius in meters
  const R = 6371e3;
  function haversine(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const phi1 = (lat1 * Math.PI) / 180;
    const phi2 = (lat2 * Math.PI) / 180;
    const deltaPhi = ((lat2 - lat1) * Math.PI) / 180;
    const deltaLambda = ((lon2 - lon1) * Math.PI) / 180;
    const a = 
      Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
      Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  let accumulatedDistM = 0;
  let splitStartTimestamp = new Date(sorted[0].timestamp).getTime();
  let currentSplitIndex = 1;

  for (let i = 1; i < sorted.length; i++) {
    const d = haversine(
      sorted[i - 1].lat,
      sorted[i - 1].lng,
      sorted[i].lat,
      sorted[i].lng
    );
    accumulatedDistM += d;

    // Check if we reached a kilometer mark
    if (accumulatedDistM >= currentSplitIndex * 1000) {
      const currentTimestamp = new Date(sorted[i].timestamp).getTime();
      const timeDiffS = (currentTimestamp - splitStartTimestamp) / 1000;

      // Format pace string
      const mins = Math.floor(timeDiffS / 60);
      const secs = Math.floor(timeDiffS % 60);
      const paceStr = `${mins}:${String(secs).padStart(2, '0')}`;

      splits.push({
        km: currentSplitIndex,
        timeS: timeDiffS,
        paceStr,
      });

      splitStartTimestamp = currentTimestamp;
      currentSplitIndex++;
    }
  }

  // Handle residual segment if any
  const totalCoveredKm = accumulatedDistM / 1000;
  const remainingFraction = totalCoveredKm - (currentSplitIndex - 1);
  if (remainingFraction > 0.05) {
    const finalTimestamp = new Date(sorted[sorted.length - 1].timestamp).getTime();
    const timeDiffS = (finalTimestamp - splitStartTimestamp) / 1000;
    
    // Extrapolate to 1km pace for split view
    const pace1Km = timeDiffS / remainingFraction;
    const mins = Math.floor(pace1Km / 60);
    const secs = Math.floor(pace1Km % 60);
    const paceStr = `${mins}:${String(secs).padStart(2, '0')}`;

    splits.push({
      km: parseFloat(totalCoveredKm.toFixed(2)),
      timeS: timeDiffS,
      paceStr,
    });
  }

  return splits;
}

function formatPace(paceSecPerKm: number): string {
  if (!paceSecPerKm || paceSecPerKm <= 0 || paceSecPerKm > 3600) return '-:--';
  const mins = Math.floor(paceSecPerKm / 60);
  const secs = Math.floor(paceSecPerKm % 60);
  return `${mins}:${String(secs).padStart(2, '0')}`;
}

function formatDuration(durationS: number): string {
  const hrs = Math.floor(durationS / 3600);
  const mins = Math.floor((durationS % 3600) / 60);
  const secs = durationS % 60;
  return hrs > 0 
    ? `${hrs}:${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`
    : `${mins}:${String(secs).padStart(2, '0')}`;
}

export default function HistoryPage() {
  const [runs, setRuns] = useState<Run[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [loading, setLoading] = useState(true);
  const [sortField, setSortField] = useState<'startTime' | 'distanceM' | 'avgPaceSPerKm'>('startTime');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc');

  // Selected run details in drawer
  const [selectedRun, setSelectedRun] = useState<Run | null>(null);
  const [selectedRunPoints, setSelectedRunPoints] = useState<RunPoint[]>([]);
  const [loadingDetails, setLoadingDetails] = useState(false);

  // Fetch paginated history list
  useEffect(() => {
    async function loadRuns() {
      setLoading(true);
      try {
        const res = await fetch(`/api/runs?page=${page}&limit=10`);
        if (res.ok) {
          const data = await res.json();
          setRuns(data.runs);
          setTotal(data.pagination.total);
          setTotalPages(data.pagination.totalPages);
        }
      } catch (err) {
        console.error('Error fetching runs history:', err);
      } finally {
        setLoading(false);
      }
    }
    loadRuns();
  }, [page]);

  // Load detailed coordinates when a run is selected
  const handleSelectRun = async (run: Run) => {
    setSelectedRun(run);
    setLoadingDetails(true);
    try {
      const res = await fetch(`/api/runs/${run.id}`);
      if (res.ok) {
        const data = await res.json();
        setSelectedRunPoints(data.points || []);
      }
    } catch (err) {
      console.error('Error fetching run details:', err);
    } finally {
      setLoadingDetails(false);
    }
  };

  const handleSort = (field: typeof sortField) => {
    const isAsc = sortField === field && sortOrder === 'asc';
    setSortField(field);
    setSortOrder(isAsc ? 'desc' : 'asc');
  };

  const sortedRuns = [...runs].sort((a, b) => {
    let valA = a[sortField] || 0;
    let valB = b[sortField] || 0;

    if (sortField === 'startTime') {
      valA = new Date(a.startTime).getTime();
      valB = new Date(b.startTime).getTime();
    }

    if (valA === valB) return 0;
    return sortOrder === 'asc' ? (valA < valB ? -1 : 1) : (valA > valB ? -1 : 1);
  });

  const splits = calculateSplits(selectedRunPoints);

  return (
    <div className="flex flex-col items-center justify-between min-h-screen bg-background text-foreground transition-colors duration-300 px-4 py-8 relative select-none">
      {/* Top Header */}
      <header className="w-full max-w-md flex items-center justify-between mb-6 z-10">
        <Link href="/" className="p-3 rounded-full bg-secondary hover:bg-muted border border-border">
          <ArrowLeft size={20} />
        </Link>
        <span className="text-lg font-bold uppercase tracking-wider text-primary">Run History</span>
        <div className="w-11" /> {/* Spacer */}
      </header>

      {/* Main Container */}
      <main className="w-full max-w-md flex-1 flex flex-col gap-4 relative overflow-y-auto mb-16">
        {/* Sort Controls */}
        <div className="flex items-center justify-between bg-secondary/30 border border-border/40 p-2 rounded-xl text-xs font-semibold">
          <span className="text-muted-foreground uppercase text-[10px] tracking-wider px-2">Sort by</span>
          <div className="flex gap-2">
            <button 
              onClick={() => handleSort('startTime')}
              className={`px-3 py-1.5 rounded-lg transition-colors border ${sortField === 'startTime' ? 'bg-primary text-white border-primary' : 'bg-transparent border-border/40 text-muted-foreground'}`}
            >
              Date
            </button>
            <button 
              onClick={() => handleSort('distanceM')}
              className={`px-3 py-1.5 rounded-lg transition-colors border ${sortField === 'distanceM' ? 'bg-primary text-white border-primary' : 'bg-transparent border-border/40 text-muted-foreground'}`}
            >
              Dist
            </button>
            <button 
              onClick={() => handleSort('avgPaceSPerKm')}
              className={`px-3 py-1.5 rounded-lg transition-colors border ${sortField === 'avgPaceSPerKm' ? 'bg-primary text-white border-primary' : 'bg-transparent border-border/40 text-muted-foreground'}`}
            >
              Pace
            </button>
          </div>
        </div>

        {loading ? (
          <div className="flex-1 flex flex-col items-center justify-center gap-2 py-24">
            <Heartbeat className="animate-spin text-primary" size={32} />
            <span className="text-xs text-muted-foreground">Loading workouts...</span>
          </div>
        ) : sortedRuns.length === 0 ? (
          <div className="flex-grow flex flex-col items-center justify-center py-32 text-center">
            <MapPin size={48} className="text-muted-foreground mb-4" />
            <p className="font-semibold text-muted-foreground">No runs logged yet</p>
            <p className="text-xs text-muted-foreground/60 max-w-xs mt-1">Get outside and track your first activity on Trailhead.</p>
          </div>
        ) : (
          <motion.div 
            initial="hidden"
            animate="visible"
            variants={{
              visible: { transition: { staggerChildren: 0.04 } }
            }}
            className="flex flex-col gap-3"
          >
            {sortedRuns.map((run) => {
              const displayDate = new Date(run.startTime).toLocaleDateString('en-US', {
                month: 'short',
                day: 'numeric',
                year: 'numeric',
              });

              return (
                <motion.div
                  key={run.id}
                  onClick={() => handleSelectRun(run)}
                  whileTap={{ scale: 0.98 }}
                  variants={{
                    hidden: { y: 15, opacity: 0 },
                    visible: { y: 0, opacity: 1 }
                  }}
                  transition={springConfig}
                  className="w-full flex items-center justify-between p-4 bg-card border border-border rounded-xl cursor-pointer shadow-sm hover:shadow transition-shadow"
                >
                  <div className="flex flex-col gap-1.5">
                    <span className="font-bold text-sm tracking-wide text-foreground">
                      {run.title || `Workout - ${displayDate}`}
                    </span>
                    <div className="flex items-center gap-3 text-xs text-muted-foreground">
                      <span className="flex items-center gap-1"><Calendar size={12} /> {displayDate}</span>
                      <span className="flex items-center gap-1"><Timer size={12} /> {formatDuration(run.durationS)}</span>
                    </div>
                  </div>

                  <div className="flex flex-col items-end gap-1">
                    <span className="font-black text-lg text-primary tabular-nums">
                      {(run.distanceM / 1000).toFixed(2)} <span className="text-[10px] font-bold">KM</span>
                    </span>
                    <span className="text-[10px] font-medium text-muted-foreground">
                      {formatPace(run.avgPaceSPerKm)} /KM
                    </span>
                  </div>
                </motion.div>
              );
            })}
          </motion.div>
        )}

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="flex items-center justify-center gap-4 mt-6">
            <button
              onClick={() => setPage(p => Math.max(1, p - 1))}
              disabled={page === 1}
              className="px-4 py-2 border border-border bg-secondary hover:bg-muted disabled:opacity-50 text-xs font-semibold rounded-lg"
            >
              Prev
            </button>
            <span className="text-xs font-bold text-muted-foreground">{page} / {totalPages}</span>
            <button
              onClick={() => setPage(p => Math.min(totalPages, p + 1))}
              disabled={page === totalPages}
              className="px-4 py-2 border border-border bg-secondary hover:bg-muted disabled:opacity-50 text-xs font-semibold rounded-lg"
            >
              Next
            </button>
          </div>
        )}
      </main>

      {/* Bottom Sheet Drawer for Run Detail View */}
      <AnimatePresence>
        {selectedRun && (
          <>
            {/* Backdrop Overlay */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 0.5 }}
              exit={{ opacity: 0 }}
              onClick={() => setSelectedRun(null)}
              className="fixed inset-0 bg-black z-40"
            />

            {/* Bottom Drawer Sheet */}
            <motion.div
              initial={{ y: '100%' }}
              animate={{ y: 0 }}
              exit={{ y: '100%' }}
              transition={springConfig}
              className="fixed bottom-0 left-0 right-0 max-h-[85vh] bg-card border-t border-border rounded-t-3xl z-50 overflow-y-auto px-6 py-6 flex flex-col items-center shadow-2xl"
            >
              {/* Swipe/Drag visual anchor */}
              <div className="w-12 h-1.5 bg-muted rounded-full mb-6 cursor-pointer" onClick={() => setSelectedRun(null)} />

              <div className="w-full max-w-md flex items-center justify-between mb-4">
                <h2 className="font-extrabold text-lg text-foreground truncate max-w-[80%]">
                  {selectedRun.title || 'Workout Details'}
                </h2>
                <button
                  onClick={() => setSelectedRun(null)}
                  className="p-2 bg-secondary hover:bg-muted border border-border rounded-full"
                >
                  <X size={16} />
                </button>
              </div>

              <div className="w-full max-w-md flex flex-col gap-6">
                {/* Lazy-loaded map container */}
                <div className="w-full h-48">
                  {loadingDetails ? (
                    <div className="w-full h-full bg-secondary/35 border border-border flex items-center justify-center rounded-2xl">
                      <Heartbeat className="animate-spin text-primary" size={24} />
                    </div>
                  ) : (
                    <Map points={selectedRunPoints.map(p => ({ lat: p.lat, lng: p.lng, timestamp: new Date(p.timestamp).getTime() }))} isFinished={true} />
                  )}
                </div>

                {/* Workout Hero Stats */}
                <div className="grid grid-cols-3 gap-4 border border-border/40 p-4 rounded-xl bg-secondary/15">
                  <div className="flex flex-col items-center">
                    <span className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider mb-1 flex items-center gap-1">
                      <MapPin size={10} /> Distance
                    </span>
                    <span className="font-black text-lg tabular-nums text-foreground">
                      {(selectedRun.distanceM / 1000).toFixed(2)} <span className="text-[9px]">KM</span>
                    </span>
                  </div>

                  <div className="flex flex-col items-center border-l border-r border-border/40">
                    <span className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider mb-1 flex items-center gap-1">
                      <Timer size={10} /> Time
                    </span>
                    <span className="font-black text-lg tabular-nums text-foreground">
                      {formatDuration(selectedRun.durationS)}
                    </span>
                  </div>

                  <div className="flex flex-col items-center">
                    <span className="text-[10px] font-bold text-muted-foreground uppercase tracking-wider mb-1 flex items-center gap-1">
                      <Compass size={10} /> Avg Pace
                    </span>
                    <span className="font-black text-lg tabular-nums text-foreground">
                      {formatPace(selectedRun.avgPaceSPerKm)}
                    </span>
                  </div>
                </div>

                {/* Splits Segment Table */}
                <div className="flex flex-col gap-3">
                  <h3 className="text-xs font-bold text-muted-foreground uppercase tracking-wider px-1">Splits (Kilometers)</h3>
                  
                  {loadingDetails ? (
                    <div className="py-8 text-center text-xs text-muted-foreground">Loading splits...</div>
                  ) : splits.length === 0 ? (
                    <div className="py-4 text-center text-xs text-muted-foreground">No split data found</div>
                  ) : (
                    <div className="border border-border/40 rounded-xl overflow-hidden bg-secondary/10">
                      <table className="w-full text-left border-collapse text-xs">
                        <thead>
                          <tr className="border-b border-border/40 bg-secondary/20">
                            <th className="p-3 font-semibold text-muted-foreground uppercase">Split</th>
                            <th className="p-3 font-semibold text-muted-foreground uppercase">Time</th>
                            <th className="p-3 font-semibold text-muted-foreground uppercase text-right">Pace</th>
                          </tr>
                        </thead>
                        <tbody>
                          {splits.map((s, idx) => (
                            <tr key={idx} className="border-b border-border/30 last:border-0 hover:bg-secondary/20 transition-colors">
                              <td className="p-3 font-bold text-foreground">{s.km}</td>
                              <td className="p-3 tabular-nums text-muted-foreground">{formatDuration(Math.round(s.timeS))}</td>
                              <td className="p-3 tabular-nums text-foreground text-right">{s.paceStr} /KM</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  )}
                </div>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </div>
  );
}
