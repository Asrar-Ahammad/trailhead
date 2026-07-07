import { NextResponse } from 'next/server';
import { auth } from '@clerk/nextjs/server';
import { getCachedRunDetail } from '@/lib/cache';

export async function GET(
  req: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { userId } = await auth();
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = await params;

    const run = await getCachedRunDetail(id, userId);

    // Check ownership or return 404 (IDOR Prevention)
    if (!run || run.userId !== userId) {
      return NextResponse.json({ error: 'Run not found' }, { status: 404 });
    }

    return NextResponse.json(run);
  } catch (err) {
    console.error('Error fetching run details:', err);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
