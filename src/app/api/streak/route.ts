import { NextResponse } from 'next/server';
import { auth } from '@clerk/nextjs/server';
import { getCachedStreak } from '@/lib/cache';

export async function GET(req: Request) {
  try {
    const { userId } = await auth();
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
      });
    }

    return NextResponse.json(streak);
  } catch (err) {
    console.error('Error fetching streak info:', err);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
