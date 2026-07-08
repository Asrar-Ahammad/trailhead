export function formatPace(paceSecPerKm: number): string {
  if (!paceSecPerKm || paceSecPerKm <= 0 || paceSecPerKm > 3600) return '-:--';
  const mins = Math.floor(paceSecPerKm / 60);
  const secs = Math.floor(paceSecPerKm % 60);
  return `${mins}:${String(secs).padStart(2, '0')}`;
}

export function formatYAxisPace(val: number): string {
  const m = Math.floor(val / 60);
  const s = Math.floor(val % 60);
  return `${m}:${String(s).padStart(2, '0')}`;
}
