import { Lightning, Timer, Path, Trophy } from '@phosphor-icons/react';
import React from 'react';

export type PhosphorIconType = React.ComponentType<{
  size?: number | string;
  className?: string;
  weight?: 'thin' | 'light' | 'regular' | 'bold' | 'fill' | 'duotone';
}>;

export interface CategoryMetadata {
  label: string;
  icon: PhosphorIconType;
  unit: string;
  format: (v: number) => string;
}

function formatDuration(durationS: number): string {
  const hrs = Math.floor(durationS / 3600);
  const mins = Math.floor((durationS % 3600) / 60);
  const secs = Math.floor(durationS % 60);
  if (hrs > 0) {
    return `${hrs}:${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
  }
  return `${mins}:${String(secs).padStart(2, '0')}`;
}

export const categoryConfig: Record<string, CategoryMetadata> = {
  // Standalone Run categories
  '100m': { label: '100m Run', icon: Lightning, unit: '', format: formatDuration },
  '1k': { label: '1k Run', icon: Timer, unit: '', format: formatDuration },
  '5k': { label: '5k Run', icon: Path, unit: '', format: formatDuration },
  '10k': { label: '10k Run', icon: Path, unit: '', format: formatDuration },
  'half': { label: 'Half Marathon', icon: Path, unit: '', format: formatDuration },
  'marathon': { label: 'Marathon', icon: Path, unit: '', format: formatDuration },
  
  // Best-Effort Segment categories
  '100m_segment': { label: 'Fastest 100m Segment', icon: Lightning, unit: '', format: formatDuration },
  '1k_segment': { label: 'Fastest 1k Segment', icon: Timer, unit: '', format: formatDuration },
  '5k_segment': { label: 'Fastest 5k Segment', icon: Path, unit: '', format: formatDuration },
  '10k_segment': { label: 'Fastest 10k Segment', icon: Path, unit: '', format: formatDuration },
  
  // Custom categories
  'longest_run': { 
    label: 'Longest Run', 
    icon: Path, 
    unit: 'KM', 
    format: (v) => `${(v / 1000).toFixed(2)} KM` 
  },
  'longest_duration': { label: 'Longest Duration', icon: Timer, unit: '', format: formatDuration },
  'max_elevation': { 
    label: 'Max Elevation Gain', 
    icon: Trophy, 
    unit: 'm', 
    format: (v) => `${Math.round(v)} m` 
  },
};
