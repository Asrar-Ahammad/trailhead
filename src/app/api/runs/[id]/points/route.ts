import { NextRequest, NextResponse } from 'next/server';
import { dbServer } from '@/lib/db-server';
import { revalidateTag } from 'next/cache';
import { z } from 'zod';
import { checkForRecords, NewRecordNotification } from '@/lib/prEngine';
import { updateStreak } from '@/lib/streakEngine';
import { getUserIdFromRequest } from '@/lib/auth';

const pointSchema = z.object({
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
  elevation: z.number().nullable().optional(),
  timestamp: z.union([z.string(), z.number()]).refine((val) => {
    const d = new Date(val);
    return !isNaN(d.getTime());
  }, { message: "Invalid timestamp format" }),
  accuracy: z.number().nullable().optional(),
  cadence: z.number().int().nullable().optional(),
  sequence: z.number().int().nonnegative(),
});

const batchPointsSchema = z.array(pointSchema);

export async function POST(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const userId = getUserIdFromRequest(req);
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id: runId } = await params;
    const { searchParams } = new URL(req.url);
    const done = searchParams.get('done') === 'true';
    const tz = searchParams.get('tz') || 'UTC';

    // Verify run ownership first
    const run = await dbServer.run.findUnique({
      where: { id: runId },
    });

    if (!run || run.userId !== userId) {
      return NextResponse.json({ error: 'Run not found' }, { status: 404 });
    }

    const body = await req.json();
    const parsedPoints = batchPointsSchema.parse(body);

    // Enforce server-side limit of 500 points per batch insertion
    if (parsedPoints.length > 500) {
      return NextResponse.json({ error: 'Payload too large. Maximum 500 points allowed per call.' }, { status: 400 });
    }

    // Insert points using createMany to prevent duplicates
    const pointsData = parsedPoints.map((p) => ({
      runId,
      lat: p.lat,
      lng: p.lng,
      elevation: p.elevation !== undefined && p.elevation !== null ? p.elevation : null,
      timestamp: new Date(p.timestamp),
      accuracy: p.accuracy !== undefined && p.accuracy !== null ? p.accuracy : null,
      cadence: p.cadence !== undefined && p.cadence !== null ? p.cadence : null,
      sequence: p.sequence,
    }));

    await dbServer.runPoint.createMany({
      data: pointsData,
      skipDuplicates: true,
    });

    revalidateTag(`run-detail-${runId}`, 'max');

    let prsAchieved: NewRecordNotification[] = [];
    if (done) {
      // 1. Run Personal Record calculations
      prsAchieved = await checkForRecords(runId);
      // 2. Update Streak
      await updateStreak(userId, run.startTime, tz);
    }

    return NextResponse.json({ 
      count: pointsData.length, 
      success: true, 
      prs: prsAchieved 
    });
  } catch (err) {
    console.error('Error inserting run points:', err);
    if (err instanceof z.ZodError) {
      return NextResponse.json({ error: 'Invalid input data', details: err.issues }, { status: 400 });
    }
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const userId = getUserIdFromRequest(req);
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id: runId } = await params;

    const run = await dbServer.run.findUnique({
      where: { id: runId },
    });

    if (!run || run.userId !== userId) {
      return NextResponse.json({ error: 'Run not found' }, { status: 404 });
    }

    const points = await dbServer.runPoint.findMany({
      where: { runId },
      orderBy: { sequence: 'asc' },
      select: { lat: true, lng: true },
    });

    return NextResponse.json(points);
  } catch (err) {
    console.error('Error fetching run points:', err);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
