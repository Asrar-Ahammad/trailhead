import { dbServer } from '../lib/db-server';

async function checkPRs() {
  console.log('Checking Personal Records in the database...');
  const records = await dbServer.personalRecord.findMany();
  console.log(`Found ${records.length} records.`);
  if (records.length > 0) {
    console.log(records.slice(0, 5));
  }
}

checkPRs().catch(console.error);
