import { NextRequest, NextResponse } from 'next/server';
import { getUserIdFromRequest } from '@/lib/auth';
import { dbServer } from '@/lib/db-server';
import { revalidateTag } from 'next/cache';

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

    const record = await dbServer.personalRecord.findUnique({
      where: { id },
    });

    if (!record || record.userId !== userId) {
      return NextResponse.json({ error: 'Record not found' }, { status: 404 });
    }

    await dbServer.personalRecord.delete({
      where: { id },
    });

    revalidateTag(`records-${userId}`, 'max');

    return NextResponse.json({ success: true });
  } catch (err) {
    console.error('Error deleting manual record:', err);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
