import { dbServer } from '../lib/db-server';
import { checkForRecords } from '../lib/prEngine';

async function backfillPRs() {
  console.log('Starting backfill of Personal Records...');
  
  const runs = await dbServer.run.findMany();
  console.log(`Found ${runs.length} runs to process for PRs.`);

  for (const run of runs) {
    try {
      const records = await checkForRecords(run.id);
      if (records.length > 0) {
        console.log(`Run ${run.id}: Generated ${records.length} new records.`);
      }
    } catch (e) {
      console.error(`Error processing run ${run.id}:`, e);
    }
  }

  console.log('Backfill of PRs complete!');
}

backfillPRs().catch(console.error);
