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
  let restDaysLimit = 0;
  const existingStreak = await dbServer.streak.findUnique({
    where: { userId },
    select: { restDaysLimit: true },
  });
  if (existingStreak) {
    restDaysLimit = existingStreak.restDaysLimit;
  }

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
        restDaysLimit,
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
  
  let currentMonth = '';
  let restDaysRemaining = restDaysLimit;

  for (const dateStr of uniqueDates) {
    const month = dateStr.substring(0, 7);
    if (month !== currentMonth) {
      currentMonth = month;
      restDaysRemaining = restDaysLimit;
    }

    if (!prevDateStr) {
      currentCount = 1;
    } else {
      const diff = getDayDiff(dateStr, prevDateStr);
      if (diff === 1) {
        currentCount += 1;
      } else if (diff > 1) {
        const missedDays = diff - 1;
        if (missedDays <= restDaysRemaining) {
          restDaysRemaining -= missedDays;
          currentCount += diff; // Include the rest days in the streak!
        } else {
          currentCount = 1;
          restDaysRemaining = Math.max(0, restDaysRemaining - missedDays);
        }
      }
    }
    if (currentCount > longestCount) {
      longestCount = currentCount;
    }
    prevDateStr = dateStr;
  }

  const todayStr = getLocalDateString(new Date(), timezone);
  const todayMonth = todayStr.substring(0, 7);
  if (todayMonth !== currentMonth) {
    currentMonth = todayMonth;
    restDaysRemaining = restDaysLimit;
  }

  let activeStreak = currentCount;
  if (prevDateStr) {
    const finalDiff = getDayDiff(todayStr, prevDateStr);
    if (finalDiff > 1) {
      const missedDays = finalDiff - 1;
      if (missedDays > restDaysRemaining) {
        activeStreak = 0;
      } else {
        restDaysRemaining -= missedDays;
        activeStreak += missedDays; // Include the used rest days in the active streak
      }
    }
  } else {
    activeStreak = 0;
  }

  const latestRun = allRuns[allRuns.length - 1];
  const restDaysUsed = restDaysLimit - restDaysRemaining;

  await dbServer.streak.upsert({
    where: { userId },
    create: {
      userId,
      currentCount: activeStreak,
      longestCount,
      lastRunDate: latestRun.startTime,
      restDaysUsed: Math.max(0, restDaysUsed),
      restDaysLimit,
    },
    update: {
      currentCount: activeStreak,
      longestCount,
      lastRunDate: latestRun.startTime,
      restDaysUsed: Math.max(0, restDaysUsed),
    },
  });

  revalidateTag(`streak-${userId}`, 'max');
}
