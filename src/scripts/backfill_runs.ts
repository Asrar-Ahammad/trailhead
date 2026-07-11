import { dbServer } from '../lib/db-server';

async function backfillRuns() {
  console.log('Starting backfill of run metadata...');
  
  const runs = await dbServer.run.findMany({
    where: {
      avgCadenceSpm: null
    }
  });

  console.log(`Found ${runs.length} runs to backfill.`);

  for (const run of runs) {
    const points = await dbServer.runPoint.findMany({
      where: { runId: run.id },
      select: { cadence: true }
    });

    let sumCadence = 0;
    let validPoints = 0;

    for (const p of points) {
      if (p.cadence && p.cadence > 0) {
        sumCadence += p.cadence;
        validPoints++;
      }
    }

    const avgCadenceSpm = validPoints > 0 ? sumCadence / validPoints : 0;
    const stepCount = avgCadenceSpm > 0 && run.durationS > 0 ? Math.round(avgCadenceSpm * (run.durationS / 60)) : 0;
    const avgStrideLengthM = stepCount > 0 ? run.distanceM / stepCount : 0;
    const caloriesKcal = (run.distanceM / 1000) * 65;

    await dbServer.run.update({
      where: { id: run.id },
      data: {
        avgCadenceSpm: avgCadenceSpm > 0 ? avgCadenceSpm : null,
        stepCount: stepCount > 0 ? stepCount : null,
        avgStrideLengthM: avgStrideLengthM > 0 ? avgStrideLengthM : null,
        caloriesKcal: caloriesKcal
      }
    });

    console.log(`Updated run ${run.id}: cadence=${avgCadenceSpm}, steps=${stepCount}, stride=${avgStrideLengthM}`);
  }

  console.log('Backfill complete!');
}

backfillRuns().catch(console.error);
