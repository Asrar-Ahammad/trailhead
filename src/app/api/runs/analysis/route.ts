import { NextRequest, NextResponse } from 'next/server';
import { getUserIdFromRequest } from '@/lib/auth';
import { generateRunAiAnalysis, RunStats } from '@/lib/aiAnalysisEngine';
import { generateUserPerformanceSummary } from '@/lib/performanceEngine';
import { z } from 'zod';

const analysisSchema = z.object({
  distanceM: z.number().nullable().optional(),
  durationS: z.number().nullable().optional(),
  avgPaceSPerKm: z.number().nullable().optional(),
  avgCadenceSpm: z.number().nullable().optional(),
  caloriesKcal: z.number().nullable().optional(),
  stepCount: z.number().nullable().optional(),
  activityType: z.string().nullable().optional(),
  // performanceSummary from client is intentionally ignored; we always fetch fresh data server-side
});

export async function POST(req: NextRequest) {
  try {
    const userId = getUserIdFromRequest(req);
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await req.json();
    const parsed = analysisSchema.parse(body);

    const runStats: RunStats = {
      distanceM: parsed.distanceM ?? undefined,
      durationS: parsed.durationS ?? undefined,
      avgPaceSPerKm: parsed.avgPaceSPerKm ?? undefined,
      avgCadenceSpm: parsed.avgCadenceSpm ?? undefined,
      caloriesKcal: parsed.caloriesKcal ?? undefined,
      stepCount: parsed.stepCount ?? undefined,
      activityType: parsed.activityType ?? undefined,
    };

    // Always fetch a fresh performance summary from the DB server-side.
    // Do NOT rely on the stale client-provided cache — it may be outdated or empty.
    let performanceSummary = null;
    try {
      performanceSummary = await generateUserPerformanceSummary(userId);
      // If the user has no runs yet (totalRuns === 0), treat as null so the AI acknowledges it's a first run.
      if (performanceSummary.totalRuns === 0) {
        performanceSummary = null;
      }
    } catch (summaryErr) {
      console.warn('[runs/analysis] Failed to fetch performance summary (non-fatal):', summaryErr);
    }

    const analysis = await generateRunAiAnalysis(runStats, performanceSummary);

    return NextResponse.json({ analysis });

  } catch (err) {
    console.error('Error generating AI run analysis:', err);
    return NextResponse.json({ 
      analysis: "Great effort! As you accumulate more runs, I'll be able to provide deeper insights into your pacing and trends." 
    });
  }
}

