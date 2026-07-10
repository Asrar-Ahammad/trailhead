import { NextRequest, NextResponse } from 'next/server';
import { getUserIdFromRequest } from '@/lib/auth';
import { dbServer as prisma } from '@/lib/db-server';
import OpenAI from 'openai';

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

// Distances in meters
const PREDICT_DISTANCES = [
  { name: '100m', d: 100 },
  { name: '200m', d: 200 },
  { name: '400m', d: 400 },
  { name: '5K', d: 5000 },
  { name: '10K', d: 10000 },
  { name: 'Half Marathon', d: 21097.5 },
  { name: 'Marathon', d: 42195 },
];

export async function GET(request: NextRequest) {
  try {
    const userId = await getUserIdFromRequest(request);
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const user = await prisma.user.findUnique({
      where: { id: userId },
    });

    // Get the most recent valid runs to establish a baseline
    const runs = await prisma.run.findMany({
      where: { 
        userId: userId,
        distanceM: { gt: 0 },
        durationS: { gt: 0 }
      },
      orderBy: { startTime: 'desc' },
      take: 10,
    });

    if (runs.length === 0) {
      return NextResponse.json({ error: 'Not enough data to predict. Go log some runs first!' }, { status: 400 });
    }

    // Find best baseline run (using the longest run to bias endurance predictions, 
    // or just the one with the highest average speed that isn't too short).
    // For simplicity, let's just pick the longest run as the baseline.
    const baselineRun = runs.reduce((prev, current) => (prev.distanceM > current.distanceM) ? prev : current);

    const t1 = baselineRun.durationS;
    const d1 = baselineRun.distanceM;

    // Riegel Formula: T2 = T1 * (D2/D1)^1.06
    const predictions = PREDICT_DISTANCES.map(target => {
      let t2 = t1 * Math.pow((target.d / d1), 1.06);
      
      // format time
      const totalSeconds = Math.round(t2);
      const h = Math.floor(totalSeconds / 3600);
      const m = Math.floor((totalSeconds % 3600) / 60);
      const s = totalSeconds % 60;
      
      let timeStr = '';
      if (h > 0) {
        timeStr = `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
      } else {
        timeStr = `${m}:${s.toString().padStart(2, '0')}`;
      }

      // For sprints, show fractional seconds for realism, even though Riegel isn't meant for sprints
      if (target.d <= 400) {
        timeStr = t2.toFixed(2) + 's';
      }

      return {
        distance: target.name,
        timeStr: timeStr,
        seconds: totalSeconds
      };
    });

    // Get AI context
    let aiReasoning = "Keep training to achieve these times!";
    if (process.env.OPENAI_API_KEY) {
      // Calculate age if dob exists
      let age = 'Unknown';
      if (user?.dob) {
        const birthDate = new Date(user.dob);
        const ageDifMs = Date.now() - birthDate.getTime();
        const ageDate = new Date(ageDifMs);
        age = Math.abs(ageDate.getUTCFullYear() - 1970).toString();
      }

      const userContext = `Age: ${age}, Gender: ${user?.gender ?? 'Unknown'}. 
Baseline run used for calculation: ${d1} meters in ${t1} seconds.`;
      
      const prompt = `You are an elite running coach. 
The user is looking at their Riegel formula race predictions based on their recent runs.
User Context: ${userContext}
Predictions: ${predictions.map(p => `${p.distance}: ${p.timeStr}`).join(', ')}

Provide exactly ONE short sentence of personalized reasoning or advice based on their baseline and age/gender (if available). The Riegel formula is notoriously bad for sprinting (100m-400m) when extrapolated from long distance baselines, so you can playfully call that out if their sprint times look ridiculous. Be encouraging but realistic. Keep it under 25 words.`;

      try {
        const aiResponse = await openai.chat.completions.create({
          model: 'gpt-4o-mini',
          messages: [{ role: 'user', content: prompt }],
          max_tokens: 60,
          temperature: 0.7,
        });
        aiReasoning = aiResponse.choices[0].message.content?.trim() || aiReasoning;
      } catch (aiErr) {
        console.error('AI contextualization failed', aiErr);
      }
    }

    return NextResponse.json({
      baseline: {
        distanceM: d1,
        durationS: t1,
      },
      predictions,
      aiReasoning
    });
  } catch (error: any) {
    console.error('Predictions API error:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
