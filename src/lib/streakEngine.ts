import { dbServer } from './db-server';
import { revalidateTag } from 'next/cache';

// Get local date string 'YYYY-MM-DD' for a date under specific timezone
export function getLocalDateString(date: Date, timezone: string): string {
  try {
    return new Intl.DateTimeFormat('en-CA', {
      timeZone: timezone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    }).format(date);
  } catch (err) {
    // Fallback to UTC if timezone is invalid
    return date.toISOString().split('T')[0];
  }
}

// Compute difference in days between two date strings 'YYYY-MM-DD'
function getDayDiff(dateStr1: string, dateStr2: string): number {
  const d1 = new Date(dateStr1 + 'T00:00:00Z');
  const d2 = new Date(dateStr2 + 'T00:00:00Z');
  const diffTime = d1.getTime() - d2.getTime();
  return Math.round(diffTime / (1000 * 60 * 60 * 24));
}

export async function updateStreak(userId: string, runStartTime: Date, timezone: string = 'UTC') {
  const allRuns = await dbServer.run.findMany({
    where: { userId },
    orderBy: { startTime: 'asc' },
    select: { startTime: true },
  });

  if (allRuns.length === 0) {
    await dbServer.streak.upsert({
      where: { userId },
      create: {
        userId,
        currentCount: 0,
        longestCount: 0,
        lastRunDate: new Date(),
        restDaysUsed: 0,
      },
      update: {
        currentCount: 0,
        longestCount: 0,
      },
    });
    revalidateTag(`streak-${userId}`, 'max');
    return;
  }

  const uniqueDates = Array.from(
    new Set(allRuns.map((r) => getLocalDateString(r.startTime, timezone)))
  ).sort();

  let currentCount = 0;
  let longestCount = 0;
  let prevDateStr: string | null = null;

  for (const dateStr of uniqueDates) {
    if (!prevDateStr) {
      currentCount = 1;
    } else {
      const diff = getDayDiff(dateStr, prevDateStr);
      if (diff === 1) {
        currentCount += 1;
      } else if (diff > 1) {
        currentCount = 1;
      }
    }
    if (currentCount > longestCount) {
      longestCount = currentCount;
    }
    prevDateStr = dateStr;
  }

  const todayStr = getLocalDateString(new Date(), timezone);
  let activeStreak = currentCount;
  if (prevDateStr) {
    const finalDiff = getDayDiff(todayStr, prevDateStr);
    if (finalDiff > 1) {
      activeStreak = 0;
    }
  } else {
    activeStreak = 0;
  }

  // Find the latest runStartTime for lastRunDate
  const latestRun = allRuns[allRuns.length - 1];

  await dbServer.streak.upsert({
    where: { userId },
    create: {
      userId,
      currentCount: activeStreak,
      longestCount,
      lastRunDate: latestRun.startTime,
      restDaysUsed: 0,
    },
    update: {
      currentCount: activeStreak,
      longestCount,
      lastRunDate: latestRun.startTime,
    },
  });

  revalidateTag(`streak-${userId}`, 'max');
}
