import { openDB, DBSchema, IDBPDatabase } from 'idb';

export interface RunDraft {
  id: string;
  startTime: number;
  endTime: number | null;
  distanceM: number;
  durationS: number;
  status: 'active' | 'paused' | 'completed';
  version: number;
  checksum: string;
}

export interface RunPointDraft {
  id: string; // client point id (e.g. uuid/cuid)
  runId: string;
  lat: number;
  lng: number;
  elevation: number | null;
  timestamp: number;
  accuracy: number | null;
  speed: number | null;
  sequence: number;
}

export interface SyncJob {
  runId: string;
  attempts: number;
  lastAttemptTime: number;
  status: 'pending' | 'syncing' | 'failed';
}

interface RunTrackerDB extends DBSchema {
  runs: {
    key: string;
    value: RunDraft;
  };
  runPoints: {
    key: string;
    value: RunPointDraft;
    indexes: { 'by-run': string };
  };
  syncJobs: {
    key: string;
    value: SyncJob;
  };
}

const DB_NAME = 'run-tracker-db';
const DB_VERSION = 2; // Bumped version to support syncJobs store addition

let dbPromise: Promise<IDBPDatabase<RunTrackerDB>> | null = null;

function getDB() {
  if (typeof window === 'undefined') return null;
  if (!dbPromise) {
    dbPromise = openDB<RunTrackerDB>(DB_NAME, DB_VERSION, {
      upgrade(db, oldVersion, newVersion, transaction) {
        // Upgrade from v1 or initialize
        if (!db.objectStoreNames.contains('runs')) {
          db.createObjectStore('runs', { keyPath: 'id' });
        }
        if (!db.objectStoreNames.contains('runPoints')) {
          const pointStore = db.createObjectStore('runPoints', { keyPath: 'id' });
          pointStore.createIndex('by-run', 'runId');
        }
        if (!db.objectStoreNames.contains('syncJobs')) {
          db.createObjectStore('syncJobs', { keyPath: 'runId' });
        }
      },
    });
  }
  return dbPromise;
}

// Simple checksum generator to verify draft integrity
export function calculateChecksum(run: Omit<RunDraft, 'checksum'>): string {
  const dataString = `${run.id}:${run.startTime}:${run.endTime || ''}:${run.distanceM.toFixed(2)}:${run.durationS}:${run.status}:${run.version}`;
  let hash = 0;
  for (let i = 0; i < dataString.length; i++) {
    const char = dataString.charCodeAt(i);
    hash = (hash << 5) - hash + char;
    hash |= 0; // Convert to 32bit integer
  }
  return hash.toString(16);
}

export async function saveRunDraft(run: Omit<RunDraft, 'checksum'>): Promise<void> {
  const db = await getDB();
  if (!db) return;

  const checksum = calculateChecksum(run);
  const runWithChecksum: RunDraft = { ...run, checksum };

  await db.put('runs', runWithChecksum);
}

export async function getRunDraft(id: string): Promise<RunDraft | null> {
  const db = await getDB();
  if (!db) return null;
  return (await db.get('runs', id)) || null;
}

export async function getActiveRunDraft(): Promise<RunDraft | null> {
  const db = await getDB();
  if (!db) return null;

  const tx = db.transaction('runs', 'readonly');
  const store = tx.objectStore('runs');
  let cursor = await store.openCursor();

  while (cursor) {
    if (cursor.value.status === 'active' || cursor.value.status === 'paused') {
      return cursor.value;
    }
    cursor = await cursor.continue();
  }
  return null;
}

export async function deleteRunDraft(id: string): Promise<void> {
  const db = await getDB();
  if (!db) return;

  const tx = db.transaction(['runs', 'runPoints'], 'readwrite');
  await tx.objectStore('runs').delete(id);

  // Also delete associated points
  const pointStore = tx.objectStore('runPoints');
  const index = pointStore.index('by-run');
  let cursor = await index.openCursor(IDBKeyRange.only(id));
  while (cursor) {
    await cursor.delete();
    cursor = await cursor.continue();
  }
  await tx.done;
}

export async function addRunPoints(points: RunPointDraft[]): Promise<void> {
  const db = await getDB();
  if (!db) return;

  const tx = db.transaction('runPoints', 'readwrite');
  const store = tx.objectStore('runPoints');
  for (const point of points) {
    store.put(point);
  }
  await tx.done;
}

export async function getRunPoints(runId: string): Promise<RunPointDraft[]> {
  const db = await getDB();
  if (!db) return [];

  const tx = db.transaction('runPoints', 'readonly');
  const index = tx.objectStore('runPoints').index('by-run');
  const points = await index.getAll(IDBKeyRange.only(runId));
  return points.sort((a, b) => a.sequence - b.sequence);
}

// Verify that the run draft checksum matches the stored fields
export function verifyDraftIntegrity(run: RunDraft): boolean {
  const { checksum, ...runWithoutChecksum } = run;
  const computed = calculateChecksum(runWithoutChecksum);
  return computed === checksum;
}

// ==========================================
// Sync Job Queue helpers
// ==========================================

export async function addSyncJob(job: SyncJob): Promise<void> {
  const db = await getDB();
  if (!db) return;
  await db.put('syncJobs', job);
}

export async function getSyncJob(runId: string): Promise<SyncJob | null> {
  const db = await getDB();
  if (!db) return null;
  return (await db.get('syncJobs', runId)) || null;
}

export async function getAllSyncJobs(): Promise<SyncJob[]> {
  const db = await getDB();
  if (!db) return [];
  return await db.getAll('syncJobs');
}

export async function deleteSyncJob(runId: string): Promise<void> {
  const db = await getDB();
  if (!db) return;
  await db.delete('syncJobs', runId);
}
