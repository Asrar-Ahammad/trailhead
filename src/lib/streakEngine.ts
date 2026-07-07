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
  const runLocalDateStr = getLocalDateString(runStartTime, timezone);

  // Fetch the existing streak
  const streak = await dbServer.streak.findUnique({
    where: { userId },
  });

  if (!streak) {
    // Initial streak record
    await dbServer.streak.create({
      data: {
        userId,
        currentCount: 1,
        longestCount: 1,
        lastRunDate: runStartTime,
        restDaysUsed: 0,
      },
    });
    revalidateTag(`streak-${userId}`, 'max');
    return;
  }

  const streakLocalDateStr = getLocalDateString(streak.lastRunDate, timezone);
  const diffDays = getDayDiff(runLocalDateStr, streakLocalDateStr);

  if (diffDays === 0) {
    // Same day run, maintain streak. Update lastRunDate to the latest run timestamp
    if (runStartTime.getTime() > streak.lastRunDate.getTime()) {
      await dbServer.streak.update({
        where: { userId },
        data: { lastRunDate: runStartTime },
      });
      revalidateTag(`streak-${userId}`, 'max');
    }
    return;
  }

  if (diffDays === 1) {
    // Consecutive day run
    const newCurrent = streak.currentCount + 1;
    const newLongest = Math.max(streak.longestCount, newCurrent);

    await dbServer.streak.update({
      where: { userId },
      data: {
        currentCount: newCurrent,
        longestCount: newLongest,
        lastRunDate: runStartTime,
      },
    });
    revalidateTag(`streak-${userId}`, 'max');
    return;
  }

  if (diffDays > 1) {
    // There is a gap. Checks if user allowed rest days config protects the streak.
    // For this implementation, we check if diffDays is within the allowed threshold of 1 + restDays.
    // Default allowed rest days/week = 0.
    // If we break the streak:
    await dbServer.streak.update({
      where: { userId },
      data: {
        currentCount: 1,
        lastRunDate: runStartTime,
      },
    });
    revalidateTag(`streak-${userId}`, 'max');
  }
}
