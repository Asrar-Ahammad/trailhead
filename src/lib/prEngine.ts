import { dbServer } from './db-server';
import { revalidateTag } from 'next/cache';

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

  return R * c; // in meters
}

interface Point {
  lat: number;
  lng: number;
  timestamp: Date;
}

// Distance constants in meters
const TARGET_DISTANCES = {
  '100m': 100,
  '1k': 1000,
  '5k': 5000,
  '10k': 10000,
  'half': 21097.5,
  'marathon': 42195,
};

export interface NewRecordNotification {
  category: string;
  value: number;
  rank: number;
  isNew: boolean;
}

export async function checkForRecords(runId: string): Promise<NewRecordNotification[]> {
  const run = await dbServer.run.findUnique({
    where: { id: runId },
    include: { points: { orderBy: { sequence: 'asc' } } },
  });

  if (!run || run.points.length < 2) return [];

  const userId = run.userId;
  const points: Point[] = run.points.map(p => ({
    lat: p.lat,
    lng: p.lng,
    timestamp: p.timestamp,
  }));

  // 1. Precompute cumulative distance array
  const cumDist: number[] = [0];
  for (let i = 1; i < points.length; i++) {
    const dist = haversine(
      points[i - 1].lat,
      points[i - 1].lng,
      points[i].lat,
      points[i].lng
    );
    cumDist.push(cumDist[i - 1] + dist);
  }

  const totalDistance = cumDist[cumDist.length - 1];
  const totalDuration = run.durationS;
  const newRecords: NewRecordNotification[] = [];

  // ========================================================
  // A. Standalone Overall Run checks (Distance ±2% Tolerance)
  // ========================================================
  for (const [category, target] of Object.entries(TARGET_DISTANCES)) {
    const minTolerance = target * 0.98;
    const maxTolerance = target * 1.02;

    if (totalDistance >= minTolerance && totalDistance <= maxTolerance) {
      // Evaluate direct total duration as the record time
      const notification = await processRecordCandidate(userId, runId, category, totalDuration, true);
      if (notification) newRecords.push(notification);
    }
  }

  // ========================================================
  // B. Best-Effort Segment scans (sliding window)
  // ========================================================
  for (const [category, target] of Object.entries(TARGET_DISTANCES)) {
    // Skip categories that are longer than the run
    if (totalDistance < target) continue;

    let minTimeForSegment = Infinity;
    let start = 0;

    for (let end = 1; end < points.length; end++) {
      while (start < end && cumDist[end] - cumDist[start] >= target) {
        // Compute time difference in seconds
        const timeDiffS = (points[end].timestamp.getTime() - points[start].timestamp.getTime()) / 1000;
        
        if (timeDiffS > 0 && timeDiffS < minTimeForSegment) {
          minTimeForSegment = timeDiffS;
        }
        start++;
      }
    }

    if (minTimeForSegment !== Infinity) {
      const notification = await processRecordCandidate(userId, runId, `${category}_segment`, minTimeForSegment, true);
      if (notification) newRecords.push(notification);
    }
  }

  // ========================================================
  // C. Other direct record categories (higher is better)
  // ========================================================
  // Longest Run
  const distNotification = await processRecordCandidate(userId, runId, 'longest_run', totalDistance, false);
  if (distNotification) newRecords.push(distNotification);

  // Longest Duration
  const durNotification = await processRecordCandidate(userId, runId, 'longest_duration', totalDuration, false);
  if (durNotification) newRecords.push(durNotification);

  // Highest Elevation Gain
  if (run.elevationGainM && run.elevationGainM > 0) {
    const elevNotification = await processRecordCandidate(userId, runId, 'max_elevation', run.elevationGainM, false);
    if (elevNotification) newRecords.push(elevNotification);
  }

  return newRecords;
}

// Check if candidate qualifies for leaderboard and handle ranking updates
async function processRecordCandidate(
  userId: string,
  runId: string,
  category: string,
  value: number,
  lowerIsBetter: boolean
): Promise<NewRecordNotification | null> {
  // Fetch existing records for this category
  const existing = await dbServer.personalRecord.findMany({
    where: { userId, category },
    orderBy: { rank: 'asc' },
  });

  const isBetter = (valA: number, valB: number) => {
    return lowerIsBetter ? valA < valB : valA > valB;
  };

  // If there are fewer than 3 records, or candidate value is better than the worst rank
  const qualifies = 
    existing.length < 3 || 
    isBetter(value, existing[existing.length - 1].value);

  if (!qualifies) return null;

  // Insert temporary record and re-sort
  const allRecords = [
    ...existing.map(r => ({ id: r.id, runId: r.runId, value: r.value, achievedAt: r.achievedAt })),
    { id: 'temp', runId, value, achievedAt: new Date() }
  ];

  // Sort: lower duration / higher distance/elevation
  allRecords.sort((a, b) => {
    if (a.value === b.value) return 0;
    return isBetter(a.value, b.value) ? -1 : 1;
  });

  // Keep top 3
  const top3 = allRecords.slice(0, 3);
  let finalRank = -1;

  // Perform transactional updates
  await dbServer.$transaction(async (tx) => {
    // 1. Delete all existing records for category
    await tx.personalRecord.deleteMany({
      where: { userId, category },
    });

    // 2. Insert top 3 with their new ranks
    for (let idx = 0; idx < top3.length; idx++) {
      const rec = top3[idx];
      const isNewRecord = rec.id === 'temp';
      if (isNewRecord) finalRank = idx + 1;

      await tx.personalRecord.create({
        data: {
          userId,
          category,
          runId: rec.runId,
          value: rec.value,
          achievedAt: rec.achievedAt,
          rank: idx + 1,
        },
      });
    }
  });

  if (finalRank !== -1) {
    revalidateTag(`records-${userId}`, 'max');
    return {
      category,
      value,
      rank: finalRank,
      isNew: true,
    };
  }

  return null;
}
