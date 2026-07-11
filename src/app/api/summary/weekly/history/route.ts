import { NextRequest, NextResponse } from 'next/server';
import { getUserIdFromRequest } from '@/lib/auth';
import { dbServer } from '@/lib/db-server';

export async function GET(req: NextRequest) {
  try {
    const userId = getUserIdFromRequest(req);
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const reports = await dbServer.weeklyReport.findMany({
      where: { userId },
      orderBy: [
        { year: 'desc' },
        { weekNumber: 'desc' }
      ]
    });

    return NextResponse.json({ reports });

  } catch (err) {
    console.error('Error fetching weekly reports history:', err);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
