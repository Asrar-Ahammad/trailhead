import { NextRequest, NextResponse } from 'next/server';
import { dbServer } from '@/lib/db-server';
import { z } from 'zod';
import { getUserIdFromRequest } from '@/lib/auth';

const createShoeSchema = z.object({
  id: z.string(),
  name: z.string(),
  brand: z.string().nullable().optional(),
  distanceM: z.number().nonnegative().optional(),
  isActive: z.boolean().optional(),
  createdAt: z.string().or(z.number()).optional(),
});

export async function GET(req: NextRequest) {
  try {
    const userId = getUserIdFromRequest(req);
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const shoes = await dbServer.shoe.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    return NextResponse.json(shoes);
  } catch (err) {
    console.error('Error fetching shoes:', err);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}

export async function POST(req: NextRequest) {
  try {
    const userId = getUserIdFromRequest(req);
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await req.json();
    const parsed = createShoeSchema.parse(body);

    const createdAt = parsed.createdAt ? new Date(parsed.createdAt) : new Date();

    const shoe = await dbServer.shoe.upsert({
      where: { id: parsed.id },
      update: {
        name: parsed.name,
        brand: parsed.brand || null,
        distanceM: parsed.distanceM ?? 0,
        isActive: parsed.isActive ?? true,
      },
      create: {
        id: parsed.id,
        userId,
        name: parsed.name,
        brand: parsed.brand || null,
        distanceM: parsed.distanceM ?? 0,
        isActive: parsed.isActive ?? true,
        createdAt,
      },
    });

    return NextResponse.json(shoe);
  } catch (err) {
    console.error('Error upserting shoe:', err);
    if (err instanceof z.ZodError) {
      return NextResponse.json({ error: 'Invalid input data', details: err.issues }, { status: 400 });
    }
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
