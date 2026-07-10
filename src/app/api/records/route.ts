import { NextRequest, NextResponse } from 'next/server';
import { getUserIdFromRequest } from '@/lib/auth';
import { getCachedRecords } from '@/lib/cache';

export async function GET(req: NextRequest) {
  try {
    const userId = getUserIdFromRequest(req);
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const records = await getCachedRecords(userId);
    
    // Group by source for easier frontend consumption
    const grouped = {
      best_effort: records.filter(r => r.source === 'best_effort'),
      manual: records.filter(r => r.source === 'manual'),
    };

    return NextResponse.json(grouped);
  } catch (err) {
    console.error('Error fetching personal records:', err);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
