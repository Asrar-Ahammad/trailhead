import { NextRequest, NextResponse } from 'next/server';
import { getUserIdFromRequest } from '@/lib/auth';
import { dbServer } from '@/lib/db-server';

function getISOWeekInfo(date: Date) {
  const target = new Date(date.valueOf());
  const dayNr = (date.getUTCDay() + 6) % 7;
  target.setUTCDate(target.getUTCDate() - dayNr + 3);
  const firstThursday = target.valueOf();
  target.setUTCMonth(0, 1);
  if (target.getUTCDay() !== 4) {
    target.setUTCMonth(0, 1 + ((4 - target.getUTCDay()) + 7) % 7);
  }
  const weekNumber = 1 + Math.ceil((firstThursday - target.valueOf()) / 604800000);
  const year = target.getUTCFullYear();
  
  // Calculate start of week (Monday) and end of week (Sunday)
  const startDate = new Date(date.valueOf());
  startDate.setUTCDate(startDate.getUTCDate() - dayNr);
  startDate.setUTCHours(0, 0, 0, 0);
  
  const endDate = new Date(startDate.valueOf());
  endDate.setUTCDate(startDate.getUTCDate() + 6);
  endDate.setUTCHours(23, 59, 59, 999);
  
  return { year, weekNumber, startDate, endDate };
}

export async function POST(req: NextRequest) {
  try {
    const userId = getUserIdFromRequest(req);
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // 1. Fetch all runs for the user
    const allRuns = await dbServer.run.findMany({
      where: { userId },
      orderBy: { startTime: 'asc' }
    });

    // 2. Group by ISO Year & Week
    const groupedRuns = new Map<string, {
      year: number;
      weekNumber: number;
      startDate: Date;
      endDate: Date;
      runs: typeof allRuns;
    }>();

    for (const run of allRuns) {
      const { year, weekNumber, startDate, endDate } = getISOWeekInfo(run.startTime);
      const key = `${year}-${weekNumber}`;
      if (!groupedRuns.has(key)) {
        groupedRuns.set(key, { year, weekNumber, startDate, endDate, runs: [] });
      }
      groupedRuns.get(key)!.runs.push(run);
    }

    // 3. Process each week and upsert WeeklyReport
    const reports = [];

    for (const [key, group] of groupedRuns.entries()) {
      let totalDistanceM = 0;
      let totalDurationS = 0;
      let totalCalories = 0;
      let totalSteps = 0;
      let runCount = 0;
      let walkCount = 0;
      
      let sumPace = 0;
      let sumCadence = 0;
      let sumStride = 0;
      let paceCount = 0;
      let cadenceCount = 0;
      let strideCount = 0;

      // Group by day for daily charts (0 = Monday, 6 = Sunday)
      const dailyMap = new Map<number, { paceSum: number; paceCount: number; cadenceSum: number; cadenceCount: number }>();

      for (const run of group.runs) {
        totalDistanceM += run.distanceM;
        totalDurationS += run.durationS;
        
        if (run.activityType === 'walk') {
          walkCount++;
        } else {
          runCount++;
        }

        // Calculate calories (rough estimate: distance in km * 65)
        const calories = (run.distanceM / 1000) * 65;
        totalCalories += calories;

        // Since backend Prisma Run model doesn't store cadence/stride, default to 0
        const cadence = 0;
        const stride = 0;

        // Steps = cadence * duration in mins
        if (cadence > 0 && run.durationS > 0) {
          totalSteps += Math.round(cadence * (run.durationS / 60));
        }

        if (run.avgPaceSPerKm > 0) {
          sumPace += run.avgPaceSPerKm;
          paceCount++;
        }
        if (cadence > 0) {
          sumCadence += cadence;
          cadenceCount++;
        }
        if (stride > 0) {
          sumStride += stride;
          strideCount++;
        }

        // Daily breakdown
        const dayOfWeek = (run.startTime.getUTCDay() + 6) % 7; // Monday = 0
        if (!dailyMap.has(dayOfWeek)) {
          dailyMap.set(dayOfWeek, { paceSum: 0, paceCount: 0, cadenceSum: 0, cadenceCount: 0 });
        }
        const daily = dailyMap.get(dayOfWeek)!;
        if (run.avgPaceSPerKm > 0) {
          daily.paceSum += run.avgPaceSPerKm;
          daily.paceCount++;
        }
        if (cadence > 0) {
          daily.cadenceSum += cadence;
          daily.cadenceCount++;
        }
      }

      const avgPaceSPerKm = paceCount > 0 ? sumPace / paceCount : 0;
      const avgCadenceSpm = cadenceCount > 0 ? sumCadence / cadenceCount : 0;
      const avgStrideLengthM = strideCount > 0 ? sumStride / strideCount : 0;

      const dailyStats = [];
      for (let i = 0; i < 7; i++) {
        const stats = dailyMap.get(i);
        if (stats) {
          dailyStats.push({
            day: i,
            avgPace: stats.paceCount > 0 ? stats.paceSum / stats.paceCount : 0,
            avgCadence: stats.cadenceCount > 0 ? stats.cadenceSum / stats.cadenceCount : 0,
          });
        } else {
          dailyStats.push({ day: i, avgPace: 0, avgCadence: 0 });
        }
      }

      const reportData = {
        userId,
        year: group.year,
        weekNumber: group.weekNumber,
        startDate: group.startDate,
        endDate: group.endDate,
        totalDistanceM,
        totalDurationS,
        totalCalories,
        totalSteps,
        runCount,
        walkCount,
        avgPaceSPerKm,
        avgCadenceSpm,
        avgStrideLengthM,
        dailyStats: dailyStats
      };

      const existingReport = await dbServer.weeklyReport.findUnique({
        where: {
          userId_year_weekNumber: {
            userId,
            year: group.year,
            weekNumber: group.weekNumber
          }
        }
      });

      if (existingReport) {
        await dbServer.weeklyReport.update({
          where: { id: existingReport.id },
          data: reportData
        });
      } else {
        await dbServer.weeklyReport.create({
          data: reportData
        });
      }

      reports.push(reportData);
    }

    return NextResponse.json({ success: true, count: reports.length });

  } catch (err) {
    console.error('Error syncing weekly summaries:', err);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
