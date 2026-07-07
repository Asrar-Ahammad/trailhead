import { NextResponse } from 'next/server';
import { auth } from '@clerk/nextjs/server';
import { dbServer } from '@/lib/db-server';
import { getLocalDateString } from '@/lib/streakEngine';

export async function GET(req: Request) {
  try {
    const { userId } = await auth();
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { searchParams } = new URL(req.url);
    const tz = searchParams.get('tz') || 'UTC';

    const now = new Date();
    // Start of current week (Monday)
    const currentDay = now.getDay();
    const distanceToMonday = currentDay === 0 ? 6 : currentDay - 1; // 0 is Sunday
    const startOfWeek = new Date(now);
    startOfWeek.setDate(now.getDate() - distanceToMonday);
    startOfWeek.setHours(0, 0, 0, 0);

    const endOfWeek = new Date(startOfWeek);
    endOfWeek.setDate(startOfWeek.getDate() + 6);
    endOfWeek.setHours(23, 59, 59, 999);

    // Prior week range
    const startOfPriorWeek = new Date(startOfWeek);
    startOfPriorWeek.setDate(startOfWeek.getDate() - 7);
    const endOfPriorWeek = new Date(startOfPriorWeek);
    endOfPriorWeek.setDate(startOfPriorWeek.getDate() + 6);
    endOfPriorWeek.setHours(23, 59, 59, 999);

    // 1. Fetch current week's runs
    const currentRuns = await dbServer.run.findMany({
      where: {
        userId,
        startTime: {
          gte: startOfWeek,
          lte: endOfWeek,
        },
      },
    });

    // 2. Fetch prior week's runs
    const priorRuns = await dbServer.run.findMany({
      where: {
        userId,
        startTime: {
          gte: startOfPriorWeek,
          lte: endOfPriorWeek,
        },
      },
    });

    // Calculations for current week
    const currentCount = currentRuns.length;
    const currentDistanceM = currentRuns.reduce((sum, r) => sum + r.distanceM, 0);
    const currentDurationS = currentRuns.reduce((sum, r) => sum + r.durationS, 0);
    const currentDistanceKm = currentDistanceM / 1000;
    const currentAvgPace = currentDistanceKm > 0 ? currentDurationS / currentDistanceKm : 0;

    // Calculations for prior week
    const priorDistanceM = priorRuns.reduce((sum, r) => sum + r.distanceM, 0);
    const priorDurationS = priorRuns.reduce((sum, r) => sum + r.durationS, 0);
    const priorDistanceKm = priorDistanceM / 1000;
    const priorAvgPace = priorDistanceKm > 0 ? priorDurationS / priorDistanceKm : 0;

    // Progress delta comparisons
    let distanceDeltaPct = 0;
    if (priorDistanceKm > 0) {
      distanceDeltaPct = ((currentDistanceKm - priorDistanceKm) / priorDistanceKm) * 100;
    } else if (currentDistanceKm > 0) {
      distanceDeltaPct = 100;
    }

    let paceDeltaPct = 0;
    if (priorAvgPace > 0 && currentAvgPace > 0) {
      // Faster pace means lower seconds/km
      paceDeltaPct = ((priorAvgPace - currentAvgPace) / priorAvgPace) * 100;
    }

    // 3. Fetch PRs achieved this week
    const newPRs = await dbServer.personalRecord.findMany({
      where: {
        userId,
        achievedAt: {
          gte: startOfWeek,
          lte: endOfWeek,
        },
      },
    });

    // Format week range header
    const startStr = startOfWeek.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    const endStr = endOfWeek.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
    const dateRange = `${startStr} - ${endStr}`;

    return NextResponse.json({
      dateRange,
      stats: {
        distanceKm: currentDistanceKm,
        durationS: currentDurationS,
        avgPaceSPerKm: currentAvgPace,
        runCount: currentCount,
      },
      progressDelta: {
        distanceDeltaPct,
        paceDeltaPct, // positive means faster, negative means slower
      },
      newPRs: newPRs.map(pr => ({
        category: pr.category,
        value: pr.value,
        rank: pr.rank,
        achievedAt: pr.achievedAt,
      })),
      // AI Coach line placeholder (coaching feedback cached generation in Phase 9)
      aiCoachFeedback: currentDistanceKm > 0 
        ? "Consistency is key. You've hit your targets this week. Keep maintaining this pace."
        : "Start your run streak! Log your first workout of the week to stay active.",
    });
  } catch (err) {
    console.error('Error calculating weekly summary:', err);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
