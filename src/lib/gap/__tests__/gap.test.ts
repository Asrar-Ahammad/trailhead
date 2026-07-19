import { gradeCostFactor } from '../gradeCost';
import { segmentGrade } from '../segmentGrade';
import { computeGap } from '../computeGap';

async function runTests() {
  console.log('Testing gradeCostFactor...');
  console.assert(Math.abs(gradeCostFactor(0) - 1.0) < 0.001, '0% grade should equal 1.0 factor');
  
  // 10% incline (0.1) should cost roughly 25-30% more (factor > 1)
  const incline10 = gradeCostFactor(0.1);
  console.log(`+10% incline factor: ${incline10}`);
  console.assert(incline10 > 1.0, '+10% should cost more than flat');

  // 10% decline (-0.1) should cost less
  const decline10 = gradeCostFactor(-0.1);
  console.log(`-10% decline factor: ${decline10}`);
  console.assert(decline10 < 1.0, '-10% should cost less than flat');

  console.log('\nTesting segmentGrade...');
  const date = new Date();
  const mockPoints = [
    { lat: 0, lng: 0, elevation: 100, timestamp: new Date(date.getTime()) },
    { lat: 0, lng: 0.001, elevation: 110, timestamp: new Date(date.getTime() + 10000) }, // ~111m away
  ];
  const segments = segmentGrade(mockPoints);
  console.log('Segments:', segments);
  // Expected grade: 10m / 111m ≈ 0.09
  console.assert(segments.length === 1, 'Should have 1 segment');
  
  console.log('\nTesting computeGap...');
  const gap = computeGap(mockPoints);
  console.log(`Calculated GAP for segment: ${gap} s/km`);
  
  // Segment pace: 10s / 111m = 0.09 s/m = 90 s/km.
  // With ~0.09 grade, cost is ~1.2.
  // GAP = 90 / 1.2 = ~75 s/km
  if (gap !== null) {
      console.assert(gap < 90, 'Uphill GAP should be faster than raw pace');
  }

  console.log('\nAll tests completed.');
}

runTests().catch(console.error);
