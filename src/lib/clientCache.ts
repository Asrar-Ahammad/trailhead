let memoryCache: Record<string, { data: unknown; timestamp: number }> = {};

export function getClientCache<T = unknown>(key: string, ttlMs = 300000): T | null { // 5 minutes default TTL
  if (typeof window === 'undefined') return null;
  const item = memoryCache[key];
  if (item && Date.now() - item.timestamp < ttlMs) {
    return item.data as T;
  }
  return null;
}

export function setClientCache<T>(key: string, data: T): void {
  if (typeof window === 'undefined') return;
  memoryCache[key] = { data, timestamp: Date.now() };
}

export function clearClientCache(key?: string): void {
  if (typeof window === 'undefined') return;
  if (key) {
    delete memoryCache[key];
  } else {
    memoryCache = {};
  }
}
