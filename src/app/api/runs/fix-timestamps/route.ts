import { NextRequest, NextResponse } from 'next/server';
import { dbServer } from '@/lib/db-server';
import { getUserIdFromRequest } from '@/lib/auth';
import { revalidateTag } from 'next/cache';

/**
 * ONE-TIME MIGRATION: Fix timestamps using bulk SQL updates.
 * 
 * Uses raw SQL to update all rows at once instead of one-by-one,
 * which is fast enough for serverless function time limits.
 * 
 * DELETE THIS ROUTE after running it once.
 */
export async function POST(req: NextRequest) {
  try {
    const userId = getUserIdFromRequest(req);
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // IST offset: 5 hours 30 minutes = '5 hours 30 minutes' in PostgreSQL interval
    const offsetInterval = '5 hours 30 minutes';

    // 1. Fix Run timestamps (bulk)
    const runsResult = await dbServer.$executeRawUnsafe(
      `UPDATE "Run" SET "startTime" = "startTime" - INTERVAL '${offsetInterval}', "endTime" = "endTime" - INTERVAL '${offsetInterval}' WHERE "userId" = $1`,
      userId
    );

    // 2. Fix RunPoint timestamps (bulk via JOIN)
    const pointsResult = await dbServer.$executeRawUnsafe(
      `UPDATE "RunPoint" SET "timestamp" = "timestamp" - INTERVAL '${offsetInterval}' WHERE "runId" IN (SELECT "id" FROM "Run" WHERE "userId" = $1)`,
      userId
    );

    // 3. Fix PersonalRecord achievedAt (bulk)
    const recordsResult = await dbServer.$executeRawUnsafe(
      `UPDATE "PersonalRecord" SET "achievedAt" = "achievedAt" - INTERVAL '${offsetInterval}' WHERE "userId" = $1`,
      userId
    );

    // 4. Fix WeeklyReport dates (bulk)
    const reportsResult = await dbServer.$executeRawUnsafe(
      `UPDATE "WeeklyReport" SET "startDate" = "startDate" - INTERVAL '${offsetInterval}', "endDate" = "endDate" - INTERVAL '${offsetInterval}' WHERE "userId" = $1`,
      userId
    );

    // 5. Fix Streak lastRunDate (bulk)
    const streakResult = await dbServer.$executeRawUnsafe(
      `UPDATE "Streak" SET "lastRunDate" = "lastRunDate" - INTERVAL '${offsetInterval}', "lastRestDaysUpdate" = CASE WHEN "lastRestDaysUpdate" IS NOT NULL THEN "lastRestDaysUpdate" - INTERVAL '${offsetInterval}' ELSE NULL END WHERE "userId" = $1`,
      userId
    );

    // 6. Invalidate all caches for this user
    revalidateTag(`runs-${userId}`, 'max');
    revalidateTag(`records-${userId}`, 'max');
    revalidateTag(`streak-${userId}`, 'max');

    // Also invalidate individual run detail caches
    const runs = await dbServer.run.findMany({
      where: { userId },
      select: { id: true },
    });
    for (const run of runs) {
      revalidateTag(`run-detail-${run.id}`, 'max');
    }

    return NextResponse.json({
      success: true,
      message: 'All timestamps corrected successfully',
      stats: {
        runsUpdated: runsResult,
        pointsUpdated: pointsResult,
        recordsUpdated: recordsResult,
        reportsUpdated: reportsResult,
        streakUpdated: streakResult,
        offsetApplied: '-5h30m (IST correction)',
      },
    });
  } catch (err) {
    console.error('Error fixing timestamps:', err);
    return NextResponse.json({ error: 'Internal Server Error', details: String(err) }, { status: 500 });
  }
}
