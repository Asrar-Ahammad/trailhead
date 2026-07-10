import { NextRequest, NextResponse } from 'next/server';
import { getUserIdFromRequest } from '@/lib/auth';
import OpenAI from 'openai';
import { z } from 'zod';
import prisma from '@/lib/prisma';

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

const chatRequestSchema = z.object({
  messages: z.array(
    z.object({
      role: z.enum(['user', 'assistant', 'system', 'tool']),
      content: z.string().nullable(),
      name: z.string().optional(),
      tool_calls: z.any().optional(),
      tool_call_id: z.string().optional(),
    })
  ),
});

const tools: OpenAI.Chat.Completions.ChatCompletionTool[] = [
  {
    type: 'function',
    function: {
      name: 'getRunHistory',
      description: 'Get the user\'s recent run history, sorted by most recent first. Distances are in meters, durations in seconds.',
      parameters: {
        type: 'object',
        properties: {
          limit: { type: 'number', description: 'Number of runs to return (max 20)' },
        },
      },
    },
  },
  {
    type: 'function',
    function: {
      name: 'getPersonalRecords',
      description: 'Get the user\'s personal records (PRs) across different distances.',
      parameters: { type: 'object', properties: {} },
    },
  },
  {
    type: 'function',
    function: {
      name: 'getAggregateStats',
      description: 'Get total aggregate stats (total distance, total time, count) for a specific date range.',
      parameters: {
        type: 'object',
        properties: {
          startDateISO: { type: 'string', description: 'Start date in ISO format (e.g. 2023-01-01T00:00:00Z)' },
          endDateISO: { type: 'string', description: 'End date in ISO format' },
        },
      },
    },
  }
];

export async function POST(req: NextRequest) {
  try {
    const userId = getUserIdFromRequest(req);
    if (!userId) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

    const body = await req.json();
    const { messages } = chatRequestSchema.parse(body);

    const systemPrompt = {
      role: 'system',
      content: `You are Trailhead AI, an advanced running coach and stats assistant. 
      You have access to the user's running data via tools. 
      When a user asks about their stats, ALWAYS use the tools to fetch the data before answering.
      Be concise, motivating, and use a slightly retro/arcade tone (e.g. "Great job!", "New high score!", etc).
      Keep your answers brief, as they will be displayed on a mobile device screen.`
    };

    let currentMessages: any[] = [systemPrompt, ...messages];

    let finalResponse = null;
    let iterations = 0;

    while (iterations < 5) {
      iterations++;
      const response = await openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: currentMessages,
        tools,
        tool_choice: 'auto',
      });

      const message = response.choices[0].message;
      currentMessages.push(message);

      if (message.tool_calls && message.tool_calls.length > 0) {
        for (const toolCall of message.tool_calls) {
          const args = JSON.parse(toolCall.function.arguments);
          let toolResult = '';

          try {
            if (toolCall.function.name === 'getRunHistory') {
              const limit = Math.min(args.limit || 5, 20);
              const runs = await prisma.run.findMany({
                where: { userId },
                orderBy: { startTime: 'desc' },
                take: limit,
                select: { distanceM: true, durationS: true, startTime: true, title: true, subjectiveEffort: true }
              });
              toolResult = JSON.stringify(runs);
            } else if (toolCall.function.name === 'getPersonalRecords') {
              const prs = await prisma.personalRecord.findMany({
                where: { userId },
                orderBy: { category: 'asc' },
                select: { category: true, value: true, source: true, rank: true }
              });
              toolResult = JSON.stringify(prs);
            } else if (toolCall.function.name === 'getAggregateStats') {
              const whereClause: any = { userId };
              if (args.startDateISO || args.endDateISO) {
                whereClause.startTime = {};
                if (args.startDateISO) whereClause.startTime.gte = new Date(args.startDateISO);
                if (args.endDateISO) whereClause.startTime.lte = new Date(args.endDateISO);
              }
              const agg = await prisma.run.aggregate({
                where: whereClause,
                _sum: { distanceM: true, durationS: true },
                _count: true
              });
              toolResult = JSON.stringify(agg);
            } else {
              toolResult = '{"error": "Unknown tool"}';
            }
          } catch(dbErr) {
            console.error(dbErr);
            toolResult = '{"error": "Failed to fetch data"}';
          }

          currentMessages.push({
            role: 'tool',
            tool_call_id: toolCall.id,
            content: toolResult,
          });
        }
      } else {
        finalResponse = message.content;
        break;
      }
    }

    return NextResponse.json({ reply: finalResponse, messages: currentMessages.slice(1) }); // don't return system prompt
  } catch (e) {
    console.error('Chat API Error:', e);
    return NextResponse.json({ error: 'Server error' }, { status: 500 });
  }
}
