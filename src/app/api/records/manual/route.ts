import { NextRequest, NextResponse } from 'next/server';
import { getUserIdFromRequest } from '@/lib/auth';
import { dbServer } from '@/lib/db-server';
import { revalidateTag } from 'next/cache';
import { z } from 'zod';

const manualRecordSchema = z.object({
  category: z.string(),
  value: z.number().positive(),
  achievedAt: z.string().refine((val) => !isNaN(Date.parse(val)), "Invalid date"),
  proofUrl: z.string().url().optional().nullable(),
});

export async function POST(req: NextRequest) {
  try {
    const userId = getUserIdFromRequest(req);
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await req.json();
    const parsed = manualRecordSchema.parse(body);

    await dbServer.personalRecord.deleteMany({
      where: { userId, category: parsed.category, source: 'manual' },
    });

    const record = await dbServer.personalRecord.create({
      data: {
        userId,
        category: parsed.category,
        value: parsed.value,
        achievedAt: new Date(parsed.achievedAt),
        proofUrl: parsed.proofUrl,
        source: 'manual',
        rank: 1, 
      },
    });

    revalidateTag(`records-${userId}`, 'max');

    return NextResponse.json(record);
  } catch (err) {
    console.error('Error creating manual record:', err);
    if (err instanceof z.ZodError) {
      return NextResponse.json({ error: 'Invalid input data', details: err.issues }, { status: 400 });
    }
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
