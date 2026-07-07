import { unstable_cache } from 'next/cache';
import { dbServer } from './db-server';

export const getCachedRuns = (userId: string, limit: number, skip: number, sortField: string = 'startTime', sortOrder: string = 'desc') => {
  return unstable_cache(
    async () => {
      return dbServer.run.findMany({
        where: { userId },
        orderBy: { [sortField]: sortOrder },
        skip,
        take: limit,
      });
    },
    [`runs-${userId}-${limit}-${skip}-${sortField}-${sortOrder}`],
    { tags: [`runs-${userId}`], revalidate: 3600 }
  )();
};

export const getCachedRunCount = (userId: string) => {
  return unstable_cache(
    async () => {
      return dbServer.run.count({
        where: { userId },
      });
    },
    [`run-count-${userId}`],
    { tags: [`runs-${userId}`], revalidate: 3600 }
  )();
};

export const getCachedRunDetail = (runId: string, userId: string) => {
  return unstable_cache(
    async () => {
      return dbServer.run.findUnique({
        where: { id: runId },
        include: { points: { orderBy: { sequence: 'asc' } } },
      });
    },
    [`run-detail-${runId}`],
    { tags: [`runs-${userId}`, `run-detail-${runId}`], revalidate: 3600 }
  )();
};

export const getCachedStreak = (userId: string) => {
  return unstable_cache(
    async () => {
      return dbServer.streak.findUnique({
        where: { userId },
      });
    },
    [`streak-${userId}`],
    { tags: [`streak-${userId}`], revalidate: 3600 }
  )();
};

export const getCachedRecords = (userId: string) => {
  return unstable_cache(
    async () => {
      return dbServer.personalRecord.findMany({
        where: { userId },
        orderBy: { rank: 'asc' },
      });
    },
    [`records-${userId}`],
    { tags: [`records-${userId}`], revalidate: 3600 }
  )();
};
