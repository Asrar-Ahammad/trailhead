import { NextRequest, NextResponse } from 'next/server';
import { getUserIdFromRequest } from '@/lib/auth';
import { dbServer } from '@/lib/db-server';

export async function POST(req: NextRequest) {
  try {
    const userId = getUserIdFromRequest(req);
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const payload = await req.json();
    const { dailySteps } = payload;

    if (!Array.isArray(dailySteps)) {
      return NextResponse.json({ error: 'Invalid payload, expected array of dailySteps' }, { status: 400 });
    }

    const results = [];
    
    // Upsert each daily steps record
    for (const record of dailySteps) {
      if (!record.dateKey || typeof record.steps !== 'number') {
        continue;
      }
      
      const hourlySteps = Array.isArray(record.hourlySteps) ? record.hourlySteps : Array(24).fill(0);
      
      const upserted = await dbServer.dailySteps.upsert({
        where: {
          userId_dateKey: {
            userId,
            dateKey: record.dateKey
          }
        },
        create: {
          userId,
          dateKey: record.dateKey,
          steps: record.steps,
          hourlySteps: hourlySteps,
          lastUpdated: new Date()
        },
        update: {
          steps: record.steps,
          hourlySteps: hourlySteps,
          lastUpdated: new Date()
        }
      });
      
      results.push(upserted);
    }

    return NextResponse.json({ success: true, count: results.length });
  } catch (error) {
    console.error('[API] Error syncing daily steps:', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
