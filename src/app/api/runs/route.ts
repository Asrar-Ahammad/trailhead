import { NextRequest, NextResponse } from 'next/server';
import { dbServer } from '@/lib/db-server';
import { z } from 'zod';
import { getCachedRuns, getCachedRunCount } from '@/lib/cache';
import { revalidateTag } from 'next/cache';
import { updateStreak } from '@/lib/streakEngine';
import { getUserIdFromRequest } from '@/lib/auth';

const createRunSchema = z.object({
  clientRunId: z.string().optional(),
  startTime: z.string().or(z.number()),
  endTime: z.string().or(z.number()),
  distanceM: z.number().nonnegative(),
  durationS: z.number().nonnegative(),
  avgPaceSPerKm: z.number().nonnegative(),
  avgGapSPerKm: z.number().nullable().optional(),
  avgCadenceSpm: z.number().nullable().optional(),
  avgStrideLengthM: z.number().nullable().optional(),
  caloriesKcal: z.number().nullable().optional(),
  stepCount: z.number().nullable().optional(),
  elevationGainM: z.number().nullable().optional(),
  title: z.string().nullable().optional(),
  activityType: z.string().optional(),
  shoeId: z.string().nullable().optional(),
  weatherTemp: z.number().nullable().optional(),
  weatherCode: z.number().nullable().optional(),
  aiAnalysis: z.string().nullable().optional(),
});

export async function POST(req: NextRequest) {
  try {
    const userId = getUserIdFromRequest(req);
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await req.json();
    const parsed = createRunSchema.parse(body);

    const runId = parsed.clientRunId;
    if (runId) {
      const existingRun = await dbServer.run.findUnique({
        where: { id: runId },
      });
      if (existingRun) {
        return NextResponse.json({ error: 'Conflict: run already exists / already synced' }, { status: 409 });
      }
    }

    const startTime = new Date(parsed.startTime);
    const endTime = new Date(parsed.endTime);

    if (isNaN(startTime.getTime()) || isNaN(endTime.getTime())) {
      return NextResponse.json({ error: 'Invalid start or end time format' }, { status: 400 });
    }

    if (endTime < startTime) {
      return NextResponse.json({ error: 'End time cannot be earlier than start time' }, { status: 400 });
    }

    const run = await dbServer.run.create({
      data: {
        id: runId,
        userId,
        startTime,
        endTime,
        distanceM: parsed.distanceM,
        durationS: parsed.durationS,
        avgPaceSPerKm: parsed.avgPaceSPerKm,
        avgGapSPerKm: parsed.avgGapSPerKm !== undefined && parsed.avgGapSPerKm !== null ? parsed.avgGapSPerKm : null,
        avgCadenceSpm: parsed.avgCadenceSpm !== undefined && parsed.avgCadenceSpm !== null ? parsed.avgCadenceSpm : null,
        avgStrideLengthM: parsed.avgStrideLengthM !== undefined && parsed.avgStrideLengthM !== null ? parsed.avgStrideLengthM : null,
        caloriesKcal: parsed.caloriesKcal !== undefined && parsed.caloriesKcal !== null ? parsed.caloriesKcal : null,
        stepCount: parsed.stepCount !== undefined && parsed.stepCount !== null ? parsed.stepCount : null,
        elevationGainM: parsed.elevationGainM !== undefined && parsed.elevationGainM !== null ? parsed.elevationGainM : null,
        title: parsed.title || null,
        activityType: parsed.activityType || 'run',
        shoeId: parsed.shoeId || null,
        weatherTemp: parsed.weatherTemp !== undefined && parsed.weatherTemp !== null ? parsed.weatherTemp : null,
        weatherCode: parsed.weatherCode !== undefined && parsed.weatherCode !== null ? parsed.weatherCode : null,
        aiAnalysis: parsed.aiAnalysis || null,
      },
    });

    // Invalidate cached runs
    revalidateTag(`runs-${userId}`, 'max');

    // Also update DailySteps in Postgres with the run's steps
    if (parsed.stepCount && parsed.stepCount > 0) {
      try {
        const dateKey = startTime.toISOString().split('T')[0];
        const hour = startTime.getUTCHours();
        
        const existingDaily = await dbServer.dailySteps.findUnique({
          where: { userId_dateKey: { userId, dateKey } }
        });
        
        let newHourly = Array(24).fill(0);
        if (existingDaily && Array.isArray(existingDaily.hourlySteps) && existingDaily.hourlySteps.length === 24) {
          newHourly = [...existingDaily.hourlySteps];
        }
        
        newHourly[hour] += parsed.stepCount;
        
        await dbServer.dailySteps.upsert({
          where: { userId_dateKey: { userId, dateKey } },
          create: {
            userId,
            dateKey,
            steps: parsed.stepCount,
            hourlySteps: newHourly,
            lastUpdated: new Date()
          },
          update: {
            steps: { increment: parsed.stepCount },
            hourlySteps: newHourly,
            lastUpdated: new Date()
          }
        });
      } catch (stepErr) {
        console.error('Failed to update daily steps from run (non-fatal):', stepErr);
      }
    }

    const { searchParams } = new URL(req.url);
    const tz = searchParams.get('tz') || 'UTC';
    try {
      await updateStreak(userId, startTime, tz);
    } catch (streakErr) {
      console.error('Failed to update streak (non-fatal):', streakErr);
    }

    return NextResponse.json(run);
  } catch (err) {
    console.error('Error creating run:', err);
    if (err instanceof z.ZodError) {
      return NextResponse.json({ error: 'Invalid input data', details: err.issues }, { status: 400 });
    }
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}

export async function GET(req: NextRequest) {
  try {
    const userId = getUserIdFromRequest(req);
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { searchParams } = new URL(req.url);
    const pageParam = searchParams.get('page');
    const limitParam = searchParams.get('limit');

    let pageNum = parseInt(pageParam || '1');
    let limitNum = parseInt(limitParam || '10');

    if (isNaN(pageNum) || pageNum < 1) pageNum = 1;
    if (isNaN(limitNum) || limitNum < 1) limitNum = 10;

    const page = pageNum;
    const limit = Math.min(100, limitNum);
    const skip = (page - 1) * limit;

    const sortField = searchParams.get('sortField') || 'startTime';
    const sortOrder = searchParams.get('sortOrder') || 'desc';

    const validSortFields = ['startTime', 'distanceM', 'avgPaceSPerKm'];
    const validSortOrders = ['asc', 'desc'];

    const activeSortField = validSortFields.includes(sortField) ? sortField : 'startTime';
    const activeSortOrder = validSortOrders.includes(sortOrder) ? sortOrder : 'desc';

    const [runs, total] = await Promise.all([
      getCachedRuns(userId, limit, skip, activeSortField, activeSortOrder),
      getCachedRunCount(userId),
    ]);

    return NextResponse.json({
      runs,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (err) {
    console.error('Error fetching runs:', err);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
