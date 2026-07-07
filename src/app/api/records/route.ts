import { NextResponse } from 'next/server';
import { auth } from '@clerk/nextjs/server';
import { getCachedRecords } from '@/lib/cache';

export async function GET(req: Request) {
  try {
    const { userId } = await auth();
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const records = await getCachedRecords(userId);

    return NextResponse.json(records);
  } catch (err) {
    console.error('Error fetching personal records:', err);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
