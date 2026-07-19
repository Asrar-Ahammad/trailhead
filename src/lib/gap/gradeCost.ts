/**
 * Implements the Minetti et al. (2002) metabolic cost-of-running-on-gradient equation:
 * C(i) = 155.4·i⁵ − 30.4·i⁴ − 43.3·i³ + 46.3·i² + 19.5·i + 3.6
 * 
 * i: gradient as a decimal fraction (e.g., 0.1 for 10% grade)
 * Returns the cost relative to flat ground (C(i) / C(0))
 */

export const FLAT_COST = 3.6;

export function gradeCostFactor(gradeDecimal: number): number {
  const i = gradeDecimal;
  const i2 = i * i;
  const i3 = i2 * i;
  const i4 = i3 * i;
  const i5 = i4 * i;

  const cost = 155.4 * i5 - 30.4 * i4 - 43.3 * i3 + 46.3 * i2 + 19.5 * i + FLAT_COST;
  return cost / FLAT_COST;
}
