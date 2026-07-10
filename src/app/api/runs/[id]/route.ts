import { NextRequest, NextResponse } from 'next/server';
import { getUserIdFromRequest } from '@/lib/auth';
import { getCachedRunDetail } from '@/lib/cache';
import { revalidateTag } from 'next/cache';
import { dbServer } from '@/lib/db-server';
import { updateStreak } from '@/lib/streakEngine';

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const userId = getUserIdFromRequest(req);
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

export async function DELETE(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const userId = getUserIdFromRequest(req);
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = await params;

    // Check ownership
    const run = await getCachedRunDetail(id, userId);
    if (!run || run.userId !== userId) {
      return NextResponse.json({ error: 'Run not found' }, { status: 404 });
    }

    await dbServer.$transaction([
      dbServer.runPoint.deleteMany({ where: { runId: id } }),
      dbServer.personalRecord.deleteMany({ where: { runId: id } }),
      dbServer.run.delete({ where: { id } }),
    ]);

    await updateStreak(userId, new Date());

    revalidateTag(`runs-${userId}`, 'max');
    revalidateTag(`run-detail-${id}`, 'max');

    return NextResponse.json({ success: true });
  } catch (err) {
    console.error('Error deleting run:', err);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
