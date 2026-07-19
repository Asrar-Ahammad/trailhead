export interface Point {
  lat: number;
  lng: number;
  elevation: number | null;
  timestamp: Date;
}

export interface Segment {
  gradeDecimal: number;
  distanceM: number;
  durationS: number;
}

// Earth radius in meters
const R = 6371e3;

function haversine(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const phi1 = (lat1 * Math.PI) / 180;
  const phi2 = (lat2 * Math.PI) / 180;
  const deltaPhi = ((lat2 - lat1) * Math.PI) / 180;
  const deltaLambda = ((lon2 - lon1) * Math.PI) / 180;

  const a = 
    Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c; // in meters
}

export function segmentGrade(points: Point[]): Segment[] {
  if (points.length < 2) return [];

  const segments: Segment[] = [];
  const altitudeBuffer: number[] = [];
  let lastSmoothedAlt: number | null = null;
  let lastPointTime = points[0].timestamp;
  let lastPointLat = points[0].lat;
  let lastPointLng = points[0].lng;

  // Pre-seed buffer with the first point if available
  if (points[0].elevation !== null) {
    altitudeBuffer.push(points[0].elevation);
  }

  for (let i = 1; i < points.length; i++) {
    const p = points[i];
    if (p.elevation !== null) {
      altitudeBuffer.push(p.elevation);
      if (altitudeBuffer.length > 3) {
        altitudeBuffer.shift();
      }
    }

    let currentSmoothedAlt: number | null = null;
    if (altitudeBuffer.length === 3) {
      currentSmoothedAlt = (altitudeBuffer[0] + altitudeBuffer[1] + altitudeBuffer[2]) / 3.0;
    }

    const dist = haversine(lastPointLat, lastPointLng, p.lat, p.lng);
    const durationS = (p.timestamp.getTime() - lastPointTime.getTime()) / 1000;

    if (dist > 0 && durationS > 0) {
      let gradeDecimal = 0;
      if (lastSmoothedAlt !== null && currentSmoothedAlt !== null) {
        const deltaAlt = currentSmoothedAlt - lastSmoothedAlt;
        gradeDecimal = deltaAlt / dist;
      }

      segments.push({
        gradeDecimal,
        distanceM: dist,
        durationS
      });
    }

    lastPointLat = p.lat;
    lastPointLng = p.lng;
    lastPointTime = p.timestamp;

    if (currentSmoothedAlt !== null) {
      lastSmoothedAlt = currentSmoothedAlt;
    }
  }

  return segments;
}
