import { Point, segmentGrade } from './segmentGrade';
import { gradeCostFactor, FLAT_COST } from './gradeCost';

/**
 * Computes the distance-weighted average Grade-Adjusted Pace (GAP) for a run.
 * 
 * 1. Derives segment grades from points.
 * 2. Clamps extreme grades to realistic running ranges (±40%) to handle GPS noise.
 * 3. Applies Minetti grade cost factor to the segment pace.
 * 4. Weights each segment's GAP by its distance to compute the final average GAP.
 * 
 * @returns Average GAP in seconds per kilometer, or null if insufficient elevation data.
 */
export function computeGap(points: Point[]): number | null {
  const segments = segmentGrade(points);

  if (segments.length === 0) return null;

  let totalWeightedGapSPerKm = 0;
  let totalDistanceM = 0;
  let hasValidElevation = false;

  // Grade clamping limits (40% grade)
  const MAX_GRADE = 0.40;
  const MIN_GRADE = -0.40;
  let lastValidGrade = 0;

  for (const seg of segments) {
    if (seg.distanceM === 0) continue;

    let grade = seg.gradeDecimal;

    // Clamp extreme grades and treat as noise, falling back to last valid
    if (grade > MAX_GRADE || grade < MIN_GRADE) {
      grade = lastValidGrade;
    } else {
      lastValidGrade = grade;
      if (grade !== 0) {
        hasValidElevation = true; // We found at least one non-flat segment
      }
    }

    const costFactor = gradeCostFactor(grade);

    // Segment raw pace (seconds per km)
    const segmentRawPaceSPerKm = (seg.durationS / seg.distanceM) * 1000;

    // GAP: uphill costs more (factor > 1), so it makes the "pace" faster (lower seconds) ?
    // Wait. If cost is 2x flat, then for the same effort, you would run 2x as fast on flat ground.
    // Therefore, GAP = RawPace / CostFactor.
    // Example: Raw pace = 600 s/km. Cost factor = 2.0. GAP = 600 / 2.0 = 300 s/km. (Much faster).
    const segmentGapPaceSPerKm = segmentRawPaceSPerKm / costFactor;

    totalWeightedGapSPerKm += segmentGapPaceSPerKm * seg.distanceM;
    totalDistanceM += seg.distanceM;
  }

  // If no elevation data was present and it just defaulted to 0 the whole time, 
  // or total distance is 0, return null.
  if (!hasValidElevation || totalDistanceM === 0) {
    return null;
  }

  const avgGapSPerKm = totalWeightedGapSPerKm / totalDistanceM;
  return avgGapSPerKm;
}
