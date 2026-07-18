import { NextRequest, NextResponse } from 'next/server';
import { dbServer } from '@/lib/db-server';
import { getUserIdFromRequest } from '@/lib/auth';
import { generateUserPerformanceSummary } from '@/lib/performanceEngine';

export async function POST(req: NextRequest) {
  try {
    const userId = getUserIdFromRequest(req);
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const summary = await generateUserPerformanceSummary(userId);

    // Save to User model
    await dbServer.user.update({
      where: { id: userId },
      data: {
        performanceSummary: JSON.stringify(summary),
        performanceUpdatedAt: new Date()
      }
    });

    return NextResponse.json(summary);
  } catch (err) {
    console.error('Error generating performance summary:', err);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
