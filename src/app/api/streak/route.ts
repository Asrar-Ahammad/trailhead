import { NextRequest, NextResponse } from 'next/server';
import { getUserIdFromRequest } from '@/lib/auth';
import { getCachedStreak } from '@/lib/cache';
import { dbServer } from '@/lib/db-server';
import { revalidateTag } from 'next/cache';

export async function GET(req: NextRequest) {
  try {
    const userId = getUserIdFromRequest(req);
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const streak = await getCachedStreak(userId);

    if (!streak) {
      return NextResponse.json({
        currentCount: 0,
        longestCount: 0,
        lastRunDate: null,
        restDaysUsed: 0,
        restDaysLimit: 0,
        lastRestDaysUpdate: null,
      });
    }

    return NextResponse.json(streak);
  } catch (err) {
    console.error('Error fetching streak info:', err);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}

export async function PUT(req: NextRequest) {
  try {
    const userId = getUserIdFromRequest(req);
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await req.json();
    const { restDaysLimit } = body;

    if (typeof restDaysLimit !== 'number' || restDaysLimit < 0 || restDaysLimit > 31) {
      return NextResponse.json({ error: 'Invalid restDaysLimit' }, { status: 400 });
    }

    const existingStreak = await dbServer.streak.findUnique({
      where: { userId },
    });

    if (existingStreak && existingStreak.lastRestDaysUpdate) {
      const lastUpdate = existingStreak.lastRestDaysUpdate;
      const now = new Date();
      // Constraint: user can only edit if the last update was in a previous month (or year).
      if (lastUpdate.getFullYear() === now.getFullYear() && lastUpdate.getMonth() === now.getMonth()) {
        return NextResponse.json(
          { error: 'Rest days can only be updated once per month.' },
          { status: 429 }
        );
      }
    }

    const updatedStreak = await dbServer.streak.upsert({
      where: { userId },
      create: {
        userId,
        currentCount: 0,
        longestCount: 0,
        lastRunDate: new Date(),
        restDaysUsed: 0,
        restDaysLimit,
        lastRestDaysUpdate: new Date(),
      },
      update: {
        restDaysLimit,
        lastRestDaysUpdate: new Date(),
      },
    });

    revalidateTag(`streak-${userId}`, 'max');

    return NextResponse.json(updatedStreak);
  } catch (err) {
    console.error('Error updating streak config:', err);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
