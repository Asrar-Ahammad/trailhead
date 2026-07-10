import { NextRequest, NextResponse } from 'next/server';
import { getUserIdFromRequest } from '@/lib/auth';
import OpenAI from 'openai';
import { z } from 'zod';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

const parseLogSchema = z.object({
  text: z.string().min(1),
});

export async function POST(req: NextRequest) {
  try {
    const userId = getUserIdFromRequest(req);
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await req.json();
    const parsed = parseLogSchema.parse(body);

    const systemPrompt = `You are a helpful AI assistant that extracts running activity details from natural language text.
The user will provide a free-text or voice-transcribed description of a run (e.g., "ran 5k this morning, felt tired, humid").
Your goal is to parse this into a structured JSON format.

RULES:
- You must return ONLY valid JSON matching this schema exactly:
{
  "distanceKm": number | null,
  "subjectiveEffort": "easy" | "moderate" | "hard" | null,
  "conditions": string | null,
  "timeOfDay": string | null
}
- Determine distance in kilometers. If the user says "miles" or "mi", convert to km (1 mile = 1.60934 km).
- Classify "subjectiveEffort" into one of the three string literals, or null if unknown.
- "conditions" can capture weather or terrain (e.g. "humid", "trails", "rainy", "hot").
- "timeOfDay" can be "morning", "afternoon", "evening", "night", or null.
- If a value cannot be extracted, output null for that field.
- Do not output markdown. Do not include any emojis.`;

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: parsed.text }
      ],
      response_format: { type: "json_object" },
      temperature: 0.1,
    });

    const content = completion.choices[0].message.content;
    if (!content) throw new Error("Empty response from OpenAI");

    try {
      const jsonResponse = JSON.parse(content);
      // Strip out any accidental emojis
      const stringified = JSON.stringify(jsonResponse).replace(/[\\p{Emoji_Presentation}\\p{Emoji}\\uFE0F]/gu, '');
      return NextResponse.json(JSON.parse(stringified));
    } catch (parseError) {
      console.error("Failed to parse OpenAI JSON:", content);
      throw parseError;
    }
  } catch (err) {
    console.error('Error parsing natural language log:', err);
    return NextResponse.json({ error: 'Failed to parse log' }, { status: 500 });
  }
}
