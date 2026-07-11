import { NextRequest, NextResponse } from 'next/server';
import { getUserIdFromRequest } from '@/lib/auth';
import { getCachedStreak } from '@/lib/cache';
import OpenAI from 'openai';

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

export async function GET(req: NextRequest) {
  try {
    const userId = getUserIdFromRequest(req);
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const streak = await getCachedStreak(userId);
    let prompt = '';
    const currentCount = streak?.currentCount ?? 0;

    if (currentCount === 0) {
      prompt = `The user currently has no active running streak. Write a very short, punchy, retro-game-style notification (under 15 words) to motivate them to start a new streak today. Do not use generic phrasing.`;
    } else {
      prompt = `The user is currently on a ${currentCount}-day running streak. Write a very short, punchy, retro-game-style notification (under 15 words) to motivate them to keep their streak alive. Do not use generic phrasing.`;
    }

    if (!process.env.OPENAI_API_KEY) {
       return NextResponse.json({ nudge: currentCount > 0 ? \`Keep your \${currentCount}-day streak alive! Run today!\` : 'Start a new streak today! Get moving!' });
    }

    const aiResponse = await openai.chat.completions.create({
      model: 'gpt-4o',
      messages: [
        { role: 'system', content: 'You are a tough, retro 8-bit AI running coach.' },
        { role: 'user', content: prompt }
      ],
      temperature: 0.7,
      max_tokens: 30,
    });

    const nudgeText = aiResponse.choices[0]?.message?.content?.trim();

    return NextResponse.json({ nudge: nudgeText || (currentCount > 0 ? \`Keep your \${currentCount}-day streak alive! Run today!\` : 'Start a new streak today! Get moving!') });
  } catch (err) {
    console.error('Error generating streak nudge:', err);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
