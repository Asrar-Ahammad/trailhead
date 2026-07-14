import { NextRequest, NextResponse } from 'next/server';
import { dbServer } from '@/lib/db-server';
import { getUserIdFromRequest } from '@/lib/auth';

export async function GET(req: NextRequest) {
  try {
    const userId = getUserIdFromRequest(req);
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const user = await dbServer.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        name: true,
        dob: true,
        gender: true,
        weightKg: true,
        createdAt: true,
        dailyGoalMetric: true,
        dailyGoalTarget: true,
        monthlyGoalMetric: true,
        monthlyGoalTarget: true,
      },
    });

    if (!user) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 });
    }

    return NextResponse.json(user);
  } catch (err) {
    console.error('Error fetching user profile:', err);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}

export async function PUT(req: NextRequest) {
  try {
    const userId = getUserIdFromRequest(req);
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await req.json();
    const { 
      name, dob, gender, weightKg,
      dailyGoalMetric, dailyGoalTarget, monthlyGoalMetric, monthlyGoalTarget 
    } = body;

    // Validate gender if provided
    if (gender && !['Male', 'Female', 'Prefer not to say'].includes(gender)) {
      return NextResponse.json({ error: 'Invalid gender' }, { status: 400 });
    }

    const updatedUser = await dbServer.user.update({
      where: { id: userId },
      data: {
        ...(name !== undefined && { name }),
        ...(dob !== undefined && { dob }),
        ...(gender !== undefined && { gender }),
        ...(weightKg !== undefined && { weightKg }),
        ...(dailyGoalMetric !== undefined && { dailyGoalMetric }),
        ...(dailyGoalTarget !== undefined && { dailyGoalTarget }),
        ...(monthlyGoalMetric !== undefined && { monthlyGoalMetric }),
        ...(monthlyGoalTarget !== undefined && { monthlyGoalTarget }),
      },
      select: {
        id: true,
        email: true,
        name: true,
        dob: true,
        gender: true,
        weightKg: true,
        dailyGoalMetric: true,
        dailyGoalTarget: true,
        monthlyGoalMetric: true,
        monthlyGoalTarget: true,
      },
    });

    return NextResponse.json(updatedUser);
  } catch (err) {
    console.error('Error updating user profile:', err);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
