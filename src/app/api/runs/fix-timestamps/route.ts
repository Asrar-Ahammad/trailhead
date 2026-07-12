import { NextRequest, NextResponse } from 'next/server';
import { dbServer } from '@/lib/db-server';
import { getUserIdFromRequest } from '@/lib/auth';
import { revalidateTag } from 'next/cache';

/**
 * ONE-TIME MIGRATION: Fix timestamps that were stored with a timezone offset bug.
 * 
 * The bug: The mobile app sent local DateTime.toIso8601String() without a UTC
 * indicator (no 'Z' suffix). The server's new Date() treated the local time as
 * UTC, storing it shifted by the user's UTC offset.
 * 
 * For IST (UTC+5:30): stored times are 5h30m AHEAD of the correct UTC value.
 * Fix: subtract 5 hours 30 minutes from all Run and RunPoint timestamps.
 * 
 * This endpoint is idempotent-ish — calling it twice would double-shift,
 * so DELETE THIS ROUTE after running it once.
 */
export async function POST(req: NextRequest) {
  try {
    const userId = getUserIdFromRequest(req);
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // IST offset: 5 hours 30 minutes = 330 minutes = 19800000 ms
    const OFFSET_MS = 5 * 60 * 60 * 1000 + 30 * 60 * 1000; // 19800000

    // 1. Fix all Run timestamps for this user
    const runs = await dbServer.run.findMany({
      where: { userId },
      select: { id: true, startTime: true, endTime: true },
    });

    let runsFixed = 0;
    for (const run of runs) {
      const correctedStartTime = new Date(run.startTime.getTime() - OFFSET_MS);
      const correctedEndTime = new Date(run.endTime.getTime() - OFFSET_MS);

      await dbServer.run.update({
        where: { id: run.id },
        data: {
          startTime: correctedStartTime,
          endTime: correctedEndTime,
        },
      });
      runsFixed++;
    }

    // 2. Fix all RunPoint timestamps for this user's runs
    const runIds = runs.map(r => r.id);
    
    let pointsFixed = 0;
    // Process in batches to avoid memory issues
    for (const runId of runIds) {
      const points = await dbServer.runPoint.findMany({
        where: { runId },
        select: { id: true, timestamp: true },
      });

      for (const point of points) {
        const correctedTimestamp = new Date(point.timestamp.getTime() - OFFSET_MS);
        await dbServer.runPoint.update({
          where: { id: point.id },
          data: { timestamp: correctedTimestamp },
        });
        pointsFixed++;
      }
    }

    // 3. Fix PersonalRecord achievedAt timestamps
    const records = await dbServer.personalRecord.findMany({
      where: { userId },
      select: { id: true, achievedAt: true },
    });

    let recordsFixed = 0;
    for (const record of records) {
      const correctedAchievedAt = new Date(record.achievedAt.getTime() - OFFSET_MS);
      await dbServer.personalRecord.update({
        where: { id: record.id },
        data: { achievedAt: correctedAchievedAt },
      });
      recordsFixed++;
    }

    // 4. Fix WeeklyReport date ranges
    const weeklyReports = await dbServer.weeklyReport.findMany({
      where: { userId },
      select: { id: true, startDate: true, endDate: true },
    });

    let reportsFixed = 0;
    for (const report of weeklyReports) {
      const correctedStartDate = new Date(report.startDate.getTime() - OFFSET_MS);
      const correctedEndDate = new Date(report.endDate.getTime() - OFFSET_MS);
      await dbServer.weeklyReport.update({
        where: { id: report.id },
        data: {
          startDate: correctedStartDate,
          endDate: correctedEndDate,
        },
      });
      reportsFixed++;
    }

    // 5. Fix Streak lastRunDate
    const streak = await dbServer.streak.findUnique({
      where: { userId },
    });

    let streakFixed = false;
    if (streak) {
      const updates: Record<string, Date> = {};
      updates.lastRunDate = new Date(streak.lastRunDate.getTime() - OFFSET_MS);
      if (streak.lastRestDaysUpdate) {
        updates.lastRestDaysUpdate = new Date(streak.lastRestDaysUpdate.getTime() - OFFSET_MS);
      }
      await dbServer.streak.update({
        where: { userId },
        data: updates,
      });
      streakFixed = true;
    }

    // 6. Invalidate caches
    revalidateTag(`runs-${userId}`, 'max');
    for (const runId of runIds) {
      revalidateTag(`run-detail-${runId}`, 'max');
    }
    revalidateTag(`records-${userId}`, 'max');
    revalidateTag(`streak-${userId}`, 'max');

    return NextResponse.json({
      success: true,
      message: 'Timestamps corrected successfully',
      stats: {
        runsFixed,
        pointsFixed,
        recordsFixed,
        reportsFixed,
        streakFixed,
        offsetApplied: '-5h30m (IST correction)',
      },
    });
  } catch (err) {
    console.error('Error fixing timestamps:', err);
    return NextResponse.json({ error: 'Internal Server Error', details: String(err) }, { status: 500 });
  }
}
