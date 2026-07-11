import { z } from 'zod';
const summarySchema = z.object({
  distanceM: z.number().nullable().optional(),
  durationS: z.number().nullable().optional(),
  avgPaceSPerKm: z.number().nullable().optional(),
  timeOfDay: z.string().nullable().optional(),
  caloriesKcal: z.number().nullable().optional(),
  avgStrideLengthM: z.number().nullable().optional(),
  avgCadenceSpm: z.number().nullable().optional(),
});

const body = {
  distanceM: 2140.0,
  durationS: 800,
  avgPaceSPerKm: 373.83,
  caloriesKcal: 162,
  avgStrideLengthM: 1.06,
  avgCadenceSpm: 151
};

const parsed = summarySchema.parse(body);
const stats: Record<string, any> = {};
if (parsed.distanceM != null) stats.distanceKm = (parsed.distanceM / 1000).toFixed(2);
if (parsed.durationS != null) {
  const mins = Math.floor(parsed.durationS / 60);
  const secs = parsed.durationS % 60;
  stats.duration = `${mins}m ${secs}s`;
}
if (parsed.avgPaceSPerKm != null) {
  const pMins = Math.floor(parsed.avgPaceSPerKm / 60);
  const pSecs = Math.floor(parsed.avgPaceSPerKm % 60).toString().padStart(2, '0');
  stats.pacePerKm = `${pMins}:${pSecs}`;
}

console.log(stats);
