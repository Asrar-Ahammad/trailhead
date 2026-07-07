import { NextResponse } from 'next/server';
import { auth, currentUser } from '@clerk/nextjs/server';
import { dbServer } from '@/lib/db-server';
import { z } from 'zod';
import { getCachedRuns, getCachedRunCount } from '@/lib/cache';
import { revalidateTag } from 'next/cache';

const createRunSchema = z.object({
  clientRunId: z.string().optional(),
  startTime: z.string().or(z.number()),
  endTime: z.string().or(z.number()),
  distanceM: z.number().nonnegative(),
  durationS: z.number().nonnegative(),
  avgPaceSPerKm: z.number().nonnegative(),
  elevationGainM: z.number().nullable().optional(),
  title: z.string().nullable().optional(),
});

export async function POST(req: Request) {
  try {
    const { userId } = await auth();
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await req.json();
    const parsed = createRunSchema.parse(body);

    // Ensure user exists in our local DB
    const userExists = await dbServer.user.findUnique({
      where: { id: userId },
    });

    if (!userExists) {
      const clerkUser = await currentUser();
      const email = clerkUser?.emailAddresses[0]?.emailAddress || `${userId}@placeholder.com`;
      await dbServer.user.create({
        data: { id: userId, email },
      });
    }

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
        elevationGainM: parsed.elevationGainM !== undefined && parsed.elevationGainM !== null ? parsed.elevationGainM : null,
        title: parsed.title || null,
      },
    });

    // Invalidate cached runs
    revalidateTag(`runs-${userId}`, 'max');

    return NextResponse.json(run);
  } catch (err) {
    console.error('Error creating run:', err);
    if (err instanceof z.ZodError) {
      return NextResponse.json({ error: 'Invalid input data', details: err.issues }, { status: 400 });
    }
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}

export async function GET(req: Request) {
  try {
    const { userId } = await auth();
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
