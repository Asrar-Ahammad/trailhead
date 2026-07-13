import { NextRequest, NextResponse } from 'next/server';
import { dbServer } from '@/lib/db-server';
import { getUserIdFromRequest } from '@/lib/auth';

export async function DELETE(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const userId = getUserIdFromRequest(req);
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const resolvedParams = await params;
    const { id } = resolvedParams;

    // First check if shoe belongs to user
    const shoe = await dbServer.shoe.findUnique({
      where: { id },
    });

    if (!shoe) {
      return NextResponse.json({ error: 'Shoe not found' }, { status: 404 });
    }

    if (shoe.userId !== userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 403 });
    }

    await dbServer.shoe.delete({
      where: { id },
    });

    return NextResponse.json({ success: true });
  } catch (err) {
    console.error('Error deleting shoe:', err);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
