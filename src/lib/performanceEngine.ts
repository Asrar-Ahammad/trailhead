import { dbServer } from '@/lib/db-server';

export interface TopStat {
  label: string;
  value: string;
  detail: string;
}

export interface PerformanceSummary {
  topStats: TopStat[];
  narrative: string;
  totalRuns: number;
  totalDistanceKm: number;
  avgPaceSPerKm: number;
}

export async function generateUserPerformanceSummary(userId: string): Promise<PerformanceSummary> {
  // 1. Fetch all completed runs for this user
  const runs = await dbServer.run.findMany({
    where: {
      userId,
      distanceM: { gt: 0 },
      durationS: { gt: 0 }
    },
    orderBy: { startTime: 'desc' }
  });

  if (runs.length === 0) {
    return {
      topStats: [],
      narrative: "You haven't completed any runs yet. Get out there and start your journey!",
      totalRuns: 0,
      totalDistanceKm: 0,
      avgPaceSPerKm: 0
    };
  }

  // 2. Compute aggregate stats
  const totalRuns = runs.length;
  const totalDistanceM = runs.reduce((sum, r) => sum + r.distanceM, 0);
  const totalDistanceKm = parseFloat((totalDistanceM / 1000).toFixed(2));
  const totalDurationS = runs.reduce((sum, r) => sum + r.durationS, 0);
  const avgPaceSPerKm = totalDistanceKm > 0 ? Math.round(totalDurationS / totalDistanceKm) : 0;

  // 3. Compute Top Stats
  const topStats: TopStat[] = [];
  
  // Longest Run
  const longestRun = runs.reduce((max, r) => r.distanceM > max.distanceM ? r : max, runs[0]);
  topStats.push({
    label: "Longest Run",
    value: `${(longestRun.distanceM / 1000).toFixed(2)} km`,
    detail: `Achieved on ${longestRun.startTime.toLocaleDateString()}`
  });

  // Fastest 5K
  const runsOver5k = runs.filter(r => r.distanceM >= 4800);
  if (runsOver5k.length > 0) {
    const fastest5kRun = runsOver5k.reduce((min, r) => r.avgPaceSPerKm < min.avgPaceSPerKm ? r : min, runsOver5k[0]);
    const pMins = Math.floor(fastest5kRun.avgPaceSPerKm / 60);
    const pSecs = Math.floor(fastest5kRun.avgPaceSPerKm % 60).toString().padStart(2, '0');
    topStats.push({
      label: "Fastest 5K Pace",
      value: `${pMins}:${pSecs} /km`,
      detail: `Achieved on ${fastest5kRun.startTime.toLocaleDateString()}`
    });
  } else {
    const fastestRunOverall = runs.reduce((min, r) => r.avgPaceSPerKm < min.avgPaceSPerKm ? r : min, runs[0]);
    const pMins = Math.floor(fastestRunOverall.avgPaceSPerKm / 60);
    const pSecs = Math.floor(fastestRunOverall.avgPaceSPerKm % 60).toString().padStart(2, '0');
    topStats.push({
      label: "Fastest Pace",
      value: `${pMins}:${pSecs} /km`,
      detail: `Achieved on ${fastestRunOverall.startTime.toLocaleDateString()}`
    });
  }

  // 4. Compute recent trend
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  const sixtyDaysAgo = new Date();
  sixtyDaysAgo.setDate(sixtyDaysAgo.getDate() - 60);

  const recentRuns = runs.filter(r => r.startTime >= thirtyDaysAgo);
  const prevRuns = runs.filter(r => r.startTime >= sixtyDaysAgo && r.startTime < thirtyDaysAgo);

  const recentDistance = recentRuns.reduce((sum, r) => sum + r.distanceM, 0) / 1000;
  const prevDistance = prevRuns.reduce((sum, r) => sum + r.distanceM, 0) / 1000;

  let narrative = `You have completed ${totalRuns} runs, covering a total distance of ${totalDistanceKm} km with an average pace of ${Math.floor(avgPaceSPerKm/60)}:${Math.floor(avgPaceSPerKm%60).toString().padStart(2,'0')}/km. `;

  if (recentDistance > prevDistance * 1.2) {
    narrative += "You've been increasing your mileage recently, keep up the great momentum! ";
  } else if (recentRuns.length > 0 && prevRuns.length === 0) {
    narrative += "You've just started building consistency this month. ";
  } else if (recentRuns.length === 0 && runs.length > 0) {
    narrative += "It looks like it's been a while since your last run. Ready to get back out there? ";
  } else {
    narrative += "You are maintaining a steady and consistent running routine. ";
  }

  return {
    topStats,
    narrative,
    totalRuns,
    totalDistanceKm,
    avgPaceSPerKm
  };
}
