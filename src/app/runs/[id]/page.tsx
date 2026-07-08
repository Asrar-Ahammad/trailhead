'use client';

import { useEffect, useState, useMemo, use } from 'react';
import { useRouter } from 'next/navigation';
import { CaretLeft, BookmarkSimple, DotsThree, Info } from '@phosphor-icons/react';
import dynamic from 'next/dynamic';
import PaceChart from '@/components/PaceChart';
import ElevationChart from '@/components/ElevationChart';
import { formatPace } from '@/lib/format';

const Map = dynamic(() => import('@/components/Map'), { ssr: false });

interface RunData {
  id: string;
  startTime: string;
  endTime: string | null;
  distanceM: number;
  durationS: number;
  avgPaceSPerKm: number;
  elevationGainM: number | null;
  title: string | null;
}

interface RunPoint {
  lat: number;
  lng: number;
  elevation: number | null;
  timestamp: string;
}

interface Split {
  km: string;
  pace: number;
  elevation: number;
  widthPercent: number;
}

function haversineDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371e3;
  const toRadians = (deg: number) => (deg * Math.PI) / 180;
  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function formatDuration(durationS: number): string {
  const hrs = Math.floor(durationS / 3600);
  const mins = Math.floor((durationS % 3600) / 60);
  const secs = Math.floor(durationS % 60);
  if (hrs > 0) return `${hrs}:${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
  return `${mins}:${String(secs).padStart(2, '0')}`;
}

export default function RunDetailsPage({ params }: { params: Promise<{ id: string }> }) {
  const resolvedParams = use(params);
  const id = resolvedParams.id;
  const router = useRouter();

  const [run, setRun] = useState<RunData | null>(null);
  const [points, setPoints] = useState<RunPoint[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadData() {
      try {
        const [runRes, pointsRes] = await Promise.all([
          fetch(`/api/runs/${id}`),
          fetch(`/api/runs/${id}`)
        ]);
        
        if (runRes.ok && pointsRes.ok) {
          const runData = await runRes.json();
          const pointsData = await pointsRes.json();
          setRun(runData);
          setPoints(pointsData.points || []);
        } else {
          router.push('/');
        }
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    }
    if (id) loadData();
  }, [id, router]);

  const analytics = useMemo(() => {
    if (!points || points.length === 0) return null;

    const splits: Split[] = [];
    const paceChartData: any[] = [];
    const elevChartData: any[] = [];
    
    let currentSplitStartPt = points[0];
    let accumulatedDist = 0;
    let splitIndex = 1;
    let maxPace = 0;
    let fastestSplit = Infinity;
    let totalElevGain = 0;
    let maxElev = -Infinity;

    for (let i = 1; i < points.length; i++) {
      const prev = points[i - 1];
      const curr = points[i];
      
      const distM = haversineDistance(prev.lat, prev.lng, curr.lat, curr.lng);
      accumulatedDist += distM;
      
      if (curr.elevation !== null && prev.elevation !== null) {
        if (curr.elevation > prev.elevation) {
          totalElevGain += (curr.elevation - prev.elevation);
        }
        if (curr.elevation > maxElev) maxElev = curr.elevation;
      }

      if (Math.floor(accumulatedDist / 100) > elevChartData.length) {
        const timeDiff = (new Date(curr.timestamp).getTime() - new Date(prev.timestamp).getTime()) / 1000;
        let instantPace = 0;
        if (distM > 0 && timeDiff > 0) {
          instantPace = timeDiff / (distM / 1000);
          if (instantPace > 600) instantPace = 600;
        }
        
        paceChartData.push({
          dist: (accumulatedDist / 1000).toFixed(2),
          pace: instantPace,
        });
        
        elevChartData.push({
          dist: (accumulatedDist / 1000).toFixed(2),
          elev: curr.elevation || 0,
        });
      }

      if (accumulatedDist >= splitIndex * 1000 || i === points.length - 1) {
        const splitDist = accumulatedDist - ((splitIndex - 1) * 1000);
        const splitTimeDiff = (new Date(curr.timestamp).getTime() - new Date(currentSplitStartPt.timestamp).getTime()) / 1000;
        let splitPace = 0;
        if (splitDist > 0) {
           splitPace = splitTimeDiff / (splitDist / 1000);
        }
        
        const splitElevDiff = (curr.elevation || 0) - (currentSplitStartPt.elevation || 0);

        if (splitPace < fastestSplit && splitDist > 500) {
          fastestSplit = splitPace;
        }

        if (splitPace > maxPace) maxPace = splitPace;

        splits.push({
          km: i === points.length - 1 && splitDist < 950 ? (splitDist / 1000).toFixed(2) : splitIndex.toString(),
          pace: splitPace,
          elevation: Math.round(splitElevDiff),
          widthPercent: 0,
        });

        currentSplitStartPt = curr;
        splitIndex++;
      }
    }

    const maxSplitPace = Math.max(...splits.map(s => s.pace));
    splits.forEach(s => {
      s.widthPercent = Math.max(10, (s.pace / maxSplitPace) * 100);
    });

    return {
      splits,
      paceChartData,
      elevChartData,
      fastestSplit: fastestSplit === Infinity ? 0 : fastestSplit,
      calcElevGain: totalElevGain,
      maxElev: maxElev === -Infinity ? 0 : maxElev,
    };
  }, [points]);

  if (loading) {
    return <div className="h-[100dvh] bg-background flex flex-col items-center justify-center text-muted-foreground">Loading...</div>;
  }

  if (!run) return null;

  const mapPoints = points.map(p => ({ lat: p.lat, lng: p.lng, timestamp: new Date(p.timestamp).getTime() }));

  return (
    <div className="flex flex-col min-h-[100dvh] bg-[#121212] text-foreground pb-12">
      <header className="flex items-center justify-between px-4 py-3 sticky top-0 bg-[#121212]/90 backdrop-blur z-50">
        <div className="flex items-center gap-3">
          <button onClick={() => router.back()} className="p-1">
            <CaretLeft size={24} weight="bold" className="text-foreground" />
          </button>
          <span className="font-bold text-lg">Run</span>
        </div>
        <div className="flex items-center gap-4">
          <BookmarkSimple size={24} className="text-muted-foreground" />
          <DotsThree size={28} weight="bold" className="text-foreground" />
        </div>
      </header>

      <div className="px-5 py-4">
        <h1 className="text-2xl font-black mb-4">{run.title || 'Run'}</h1>
        <div className="flex gap-8">
          <div>
            <span className="text-[11px] text-muted-foreground uppercase font-bold tracking-wider block mb-0.5">Distance</span>
            <div className="font-black text-xl tabular-nums">
              {(run.distanceM / 1000).toFixed(2)} <span className="text-xs font-bold">km</span>
            </div>
          </div>
          <div>
            <span className="text-[11px] text-muted-foreground uppercase font-bold tracking-wider block mb-0.5">Pace</span>
            <div className="font-black text-xl tabular-nums">
              {formatPace(run.avgPaceSPerKm)} <span className="text-xs font-bold">/km</span>
            </div>
          </div>
          <div>
            <span className="text-[11px] text-muted-foreground uppercase font-bold tracking-wider block mb-0.5">Time</span>
            <div className="font-black text-xl tabular-nums">
              {formatDuration(run.durationS)}
            </div>
          </div>
        </div>
      </div>

      <div className="w-full h-64 bg-secondary mt-2 z-0 relative">
        <Map points={mapPoints} isFinished={true} rounded={false} showLocateButton={false} />
      </div>

      {analytics && analytics.splits.length > 0 && (
        <div className="mt-6 px-4">
          <h2 className="text-xl font-bold mb-4">Splits</h2>
          <div className="flex justify-between text-[10px] text-muted-foreground uppercase font-bold tracking-wider mb-2 pb-2 border-b border-white/10">
            <span className="w-8">Km</span>
            <span className="flex-1 ml-2">Pace</span>
            <span>Elev</span>
          </div>
          <div className="flex flex-col gap-3 mt-3">
            {analytics.splits.map((s, idx) => (
              <div key={idx} className="flex items-center text-sm font-semibold tabular-nums">
                <span className="w-8 text-muted-foreground">{s.km}</span>
                <div className="flex-1 ml-2 flex items-center gap-3">
                  <span className="w-10">{formatPace(s.pace)}</span>
                  <div className="h-4 bg-[#2D73D5] rounded-sm" style={{ width: `${s.widthPercent * 0.7}%` }} />
                </div>
                <span className="w-8 text-right text-muted-foreground">{s.elevation}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {analytics && analytics.paceChartData.length > 0 && (
        <>
          <PaceChart paceChartData={analytics.paceChartData} avgPaceSPerKm={run.avgPaceSPerKm} />
          
          <div className="px-4 flex flex-col gap-4 mt-6 text-sm font-semibold">
            <div className="flex justify-between items-center border-b border-white/5 pb-3">
              <span className="text-muted-foreground">Avg Pace</span>
              <span>{formatPace(run.avgPaceSPerKm)} /km</span>
            </div>
            <div className="flex justify-between items-center border-b border-white/5 pb-3">
              <span className="text-muted-foreground">Moving Time</span>
              <span>{formatDuration(run.durationS)}</span>
            </div>
            <div className="flex justify-between items-center pb-2">
              <span className="text-muted-foreground">Fastest Split</span>
              <span>{formatPace(analytics.fastestSplit)} /km</span>
            </div>
          </div>
        </>
      )}

      {analytics && analytics.elevChartData.length > 0 && (
        <>
          <ElevationChart elevChartData={analytics.elevChartData} />
          
          <div className="px-4 flex flex-col gap-4 mt-6 text-sm font-semibold">
            <div className="flex justify-between items-center border-b border-white/5 pb-3">
              <span className="text-muted-foreground">Elevation Gain</span>
              <span>{Math.round(run.elevationGainM || analytics.calcElevGain)} m</span>
            </div>
            <div className="flex justify-between items-center pb-2">
              <span className="text-muted-foreground">Max Elevation</span>
              <span>{Math.round(analytics.maxElev)} m</span>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
