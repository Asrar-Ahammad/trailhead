import { 
  getAllSyncJobs, 
  getRunDraft, 
  getRunPoints, 
  deleteRunDraft, 
  deleteSyncJob, 
  addSyncJob,
  SyncJob 
} from './db';

// Simple listener registry for notifying UI of sync state changes
type SyncCallback = (status: {
  isSyncing: boolean;
  pendingCount: number;
  lastError: string | null;
}) => void;

const listeners = new Set<SyncCallback>();
let isSyncingActive = false;
let lastSyncError: string | null = null;

export function subscribeToSyncStatus(callback: SyncCallback) {
  listeners.add(callback);
  // Initial call
  notifyStatus();
  return () => {
    listeners.delete(callback);
  };
}

async function notifyStatus() {
  try {
    const jobs = await getAllSyncJobs();
    const pendingCount = jobs.filter(j => j.status !== 'syncing').length;
    listeners.forEach(cb => cb({
      isSyncing: isSyncingActive,
      pendingCount,
      lastError: lastSyncError,
    }));
  } catch (err) {
    console.error('Error reading sync status:', err);
  }
}

// Check if backoff period has passed
function isBackoffExpired(job: SyncJob): boolean {
  if (job.status === 'pending') return true;
  const delayMs = Math.min(Math.pow(2, job.attempts) * 1000, 300000); // Max backoff capped at 5 mins
  return Date.now() - job.lastAttemptTime >= delayMs;
}

// Main sync loop executor
export async function triggerSync(): Promise<void> {
  if (isSyncingActive) return;
  isSyncingActive = true;
  lastSyncError = null;
  notifyStatus();

  try {
    const jobs = await getAllSyncJobs();
    const jobsToRun = jobs.filter(job => job.attempts < 5 && isBackoffExpired(job));

    for (const job of jobsToRun) {
      const success = await syncSingleRun(job);
      if (!success) {
        // Stop processing subsequent runs to allow backoff
        break;
      }
    }
  } catch (err) {
    console.error('Sync trigger error:', err);
  } finally {
    isSyncingActive = false;
    notifyStatus();
  }
}

// Sync metadata + points for a single run
async function syncSingleRun(job: SyncJob): Promise<boolean> {
  const runId = job.runId;

  // Mark job as syncing
  job.status = 'syncing';
  await addSyncJob(job);
  notifyStatus();

  try {
    const runDraft = await getRunDraft(runId);
    if (!runDraft) {
      // Draft has been deleted, clean up job
      await deleteSyncJob(runId);
      return true;
    }

    const tz = typeof Intl !== 'undefined' ? Intl.DateTimeFormat().resolvedOptions().timeZone : 'UTC';

    // 1. Sync Run Metadata
    const response = await fetch(`/api/runs?tz=${encodeURIComponent(tz)}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        clientRunId: runDraft.id,
        startTime: runDraft.startTime,
        endTime: runDraft.endTime || Date.now(),
        distanceM: runDraft.distanceM,
        durationS: runDraft.durationS,
        avgPaceSPerKm: runDraft.durationS / ((runDraft.distanceM || 1) / 1000), // average pace s/km
      }),
    });

    if (!response.ok) {
      // Handle Unauthorized
      if (response.status === 401) {
        throw new Error('Unauthorized: please sign in to sync');
      }
      // Concurrency conflict: First successful sync wins
      if (response.status === 409) {
        console.warn(`Run ${runId} already synced on server (409 Conflict). Deleting local copy.`);
        await deleteRunDraft(runId);
        await deleteSyncJob(runId);
        return true;
      }
      throw new Error(`Metadata sync failed with status ${response.status}`);
    }

    // 2. Sync Points sequentially in batches
    const rawPoints = await getRunPoints(runId);
    const batchSize = 250; // Use conservative batch size (max 500)

    for (let i = 0; i < rawPoints.length; i += batchSize) {
      const batch = rawPoints.slice(i, i + batchSize);
      const isLast = (i + batchSize) >= rawPoints.length;
      
      const pointsResp = await fetch(`/api/runs/${runId}/points?done=${isLast}&tz=${encodeURIComponent(tz)}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(batch),
      });

      if (!pointsResp.ok) {
        throw new Error(`Points sync failed at index ${i} with status ${pointsResp.status}`);
      }
    }

    // 3. Clear Local IndexedDB Buffer after successful sync
    await deleteRunDraft(runId);
    await deleteSyncJob(runId);
    return true;
  } catch (err: any) {
    console.error(`Failed to sync run ${runId}:`, err);
    lastSyncError = err.message || 'Unknown network error';
    
    // Update job metrics for exponential retry
    job.attempts += 1;
    job.lastAttemptTime = Date.now();
    job.status = 'failed';
    await addSyncJob(job);
    return false;
  }
}
