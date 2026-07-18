import { NextRequest, NextResponse } from 'next/server';
import { getUserIdFromRequest } from '@/lib/auth';
import { generateRunAiAnalysis, RunStats } from '@/lib/aiAnalysisEngine';
import { z } from 'zod';

const analysisSchema = z.object({
  distanceM: z.number().nullable().optional(),
  durationS: z.number().nullable().optional(),
  avgPaceSPerKm: z.number().nullable().optional(),
  avgCadenceSpm: z.number().nullable().optional(),
  caloriesKcal: z.number().nullable().optional(),
  stepCount: z.number().nullable().optional(),
  activityType: z.string().nullable().optional(),
  performanceSummary: z.string().nullable().optional(),
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

    const analysis = await generateRunAiAnalysis(runStats, parsed.performanceSummary ?? null);

    return NextResponse.json({ analysis });

  } catch (err) {
    console.error('Error generating AI run analysis:', err);
    return NextResponse.json({ 
      analysis: "Great effort! As you accumulate more runs, I'll be able to provide deeper insights into your pacing and trends." 
    });
  }
}
