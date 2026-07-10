import { NextRequest, NextResponse } from 'next/server';
import { getUserIdFromRequest } from '@/lib/auth';
import { dbServer } from '@/lib/db-server';
import { getLocalDateString } from '@/lib/streakEngine';
import OpenAI from 'openai';

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

export async function GET(req: NextRequest) {
  try {
    const userId = getUserIdFromRequest(req);
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { searchParams } = new URL(req.url);
    const tz = searchParams.get('tz') || 'UTC';

    const getAbsoluteDateInTimezone = (dateStr: string, timezone: string): Date => {
      const utcDate = new Date(dateStr + 'Z');
      try {
        const tzDate = new Date(utcDate.toLocaleString('en-US', { timeZone: timezone }));
        const diff = utcDate.getTime() - tzDate.getTime();
        return new Date(utcDate.getTime() + diff);
      } catch (e) {
        return utcDate;
      }
    };

    const localNowStr = getLocalDateString(new Date(), tz);
    const [year, month, day] = localNowStr.split('-').map(Number);
    const localNow = new Date(Date.UTC(year, month - 1, day));

    const currentDay = localNow.getUTCDay();
    const distanceToMonday = currentDay === 0 ? 6 : currentDay - 1;

    const localStartOfWeek = new Date(localNow);
    localStartOfWeek.setUTCDate(localNow.getUTCDate() - distanceToMonday);

    const startOfWeekStr = `${localStartOfWeek.getUTCFullYear()}-${String(localStartOfWeek.getUTCMonth() + 1).padStart(2, '0')}-${String(localStartOfWeek.getUTCDate()).padStart(2, '0')}T00:00:00`;
    const startOfWeek = getAbsoluteDateInTimezone(startOfWeekStr, tz);

    const endOfWeek = new Date(startOfWeek);
    endOfWeek.setDate(startOfWeek.getDate() + 6);
    endOfWeek.setHours(23, 59, 59, 999);

    const startOfPriorWeek = new Date(startOfWeek);
    startOfPriorWeek.setDate(startOfWeek.getDate() - 7);
    const endOfPriorWeek = new Date(startOfPriorWeek);
    endOfPriorWeek.setDate(startOfPriorWeek.getDate() + 6);
    endOfPriorWeek.setHours(23, 59, 59, 999);

    // 1. Fetch current week's runs
    const currentRuns = await dbServer.run.findMany({
      where: {
        userId,
        startTime: {
          gte: startOfWeek,
          lte: endOfWeek,
        },
      },
    });

    // 2. Fetch prior week's runs
    const priorRuns = await dbServer.run.findMany({
      where: {
        userId,
        startTime: {
          gte: startOfPriorWeek,
          lte: endOfPriorWeek,
        },
      },
    });

    // Calculations for current week
    const currentCount = currentRuns.length;
    const currentDistanceM = currentRuns.reduce((sum, r) => sum + r.distanceM, 0);
    const currentDurationS = currentRuns.reduce((sum, r) => sum + r.durationS, 0);
    const currentDistanceKm = currentDistanceM / 1000;
    const currentAvgPace = currentDistanceKm > 0 ? currentDurationS / currentDistanceKm : 0;

    // Calculations for prior week
    const priorDistanceM = priorRuns.reduce((sum, r) => sum + r.distanceM, 0);
    const priorDurationS = priorRuns.reduce((sum, r) => sum + r.durationS, 0);
    const priorDistanceKm = priorDistanceM / 1000;
    const priorAvgPace = priorDistanceKm > 0 ? priorDurationS / priorDistanceKm : 0;

    // Progress delta comparisons
    let distanceDeltaPct = 0;
    if (priorDistanceKm > 0) {
      distanceDeltaPct = ((currentDistanceKm - priorDistanceKm) / priorDistanceKm) * 100;
    } else if (currentDistanceKm > 0) {
      distanceDeltaPct = 100;
    }

    let paceDeltaPct = 0;
    if (priorAvgPace > 0 && currentAvgPace > 0) {
      // Faster pace means lower seconds/km
      paceDeltaPct = ((priorAvgPace - currentAvgPace) / priorAvgPace) * 100;
    }

    // 3. Fetch PRs achieved this week
    const newPRs = await dbServer.personalRecord.findMany({
      where: {
        userId,
        achievedAt: {
          gte: startOfWeek,
          lte: endOfWeek,
        },
      },
    });

    // Format week range header
    const startStr = startOfWeek.toLocaleDateString('en-US', { month: 'short', day: 'numeric', timeZone: tz });
    const endStr = endOfWeek.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric', timeZone: tz });
    const dateRange = `${startStr} - ${endStr}`;

    // Fetch user context for AI
    const user = await dbServer.user.findUnique({
      where: { id: userId },
    });

    let age = 'Unknown';
    if (user?.dob) {
      const birthDate = new Date(user.dob);
      const ageDate = new Date(Date.now() - birthDate.getTime());
      age = Math.abs(ageDate.getUTCFullYear() - 1970).toString();
    }
    const weight = user?.weightKg ? `${user.weightKg}kg` : 'Unknown';
    const gender = user?.gender || 'Unknown';

    // 10% rule: Calculate average of previous 4 weeks
    const startOf4WeeksAgo = new Date(startOfWeek);
    startOf4WeeksAgo.setDate(startOfWeek.getDate() - 28);
    
    const last4WeeksRuns = await dbServer.run.findMany({
      where: {
        userId,
        startTime: {
          gte: startOf4WeeksAgo,
          lt: startOfWeek,
        },
      },
    });

    let previous4WeeksDistanceKm = 0;
    last4WeeksRuns.forEach(r => previous4WeeksDistanceKm += r.distanceM / 1000);
    const avgWeeklyDistanceKm = previous4WeeksDistanceKm / 4;

    let coachingFeedback = currentDistanceKm > 0 
      ? "Consistency is key. You've hit your targets this week. Keep maintaining this pace."
      : "Start your run streak! Log your first workout of the week to stay active.";
    let fatigueFlag: string | null = null;

    if (process.env.OPENAI_API_KEY && currentDistanceKm > 0) {
      const prompt = `You are an elite running coach providing weekly feedback.
User Context: Age: ${age}, Gender: ${gender}, Weight: ${weight}.
Current Week Distance: ${currentDistanceKm.toFixed(1)} km across ${currentCount} runs.
Previous 4-Week Average Distance: ${avgWeeklyDistanceKm.toFixed(1)} km/week.

The "10% rule" states weekly mileage shouldn't increase by more than 10%. 
Analyze the data. Keep the tone encouraging but non-alarmist. DO NOT provide medical advice.

Return a JSON object with two fields:
- "coachingFeedback": 2-4 sentences of personalized training feedback.
- "fatigueFlag": A short 1-sentence warning string IF the user significantly exceeded the 10% rule (e.g. "You ramped up your mileage very fast this week—prioritize recovery!"). Otherwise, return null.`;

      try {
        const aiResponse = await openai.chat.completions.create({
          model: 'gpt-4o-mini',
          messages: [{ role: 'user', content: prompt }],
          response_format: { type: 'json_object' },
        });

        const parsed = JSON.parse(aiResponse.choices[0].message.content || '{}');
        if (parsed.coachingFeedback) coachingFeedback = parsed.coachingFeedback;
        if (parsed.fatigueFlag) fatigueFlag = parsed.fatigueFlag;
      } catch (e) {
        console.error('OpenAI Error in weekly summary:', e);
      }
    }

    return NextResponse.json({
      dateRange,
      stats: {
        distanceKm: currentDistanceKm,
        durationS: currentDurationS,
        avgPaceSPerKm: currentAvgPace,
        runCount: currentCount,
      },
      progressDelta: {
        distanceDeltaPct,
        paceDeltaPct, // positive means faster, negative means slower
      },
      newPRs: newPRs.map(pr => ({
        category: pr.category,
        value: pr.value,
        rank: pr.rank,
        achievedAt: pr.achievedAt,
      })),
      coachingFeedback,
      fatigueFlag,
    });
  } catch (err) {
    console.error('Error calculating weekly summary:', err);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
