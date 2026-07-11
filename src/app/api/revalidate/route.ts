import { NextRequest, NextResponse } from 'next/server';
import { revalidatePath } from 'next/cache';

export async function GET(req: NextRequest) {
  revalidatePath('/api/records');
  return NextResponse.json({ revalidated: true });
}
