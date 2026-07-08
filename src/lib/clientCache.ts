let memoryCache: Record<string, { data: any; timestamp: number }> = {};

export function getClientCache(key: string, ttlMs = 300000) { // 5 minutes default TTL
  if (typeof window === 'undefined') return null;
  const item = memoryCache[key];
  if (item && Date.now() - item.timestamp < ttlMs) {
    return item.data;
  }
  return null;
}

export function setClientCache(key: string, data: any) {
  if (typeof window === 'undefined') return;
  memoryCache[key] = { data, timestamp: Date.now() };
}

export function clearClientCache(key?: string) {
  if (typeof window === 'undefined') return;
  if (key) {
    delete memoryCache[key];
  } else {
    memoryCache = {};
  }
}
