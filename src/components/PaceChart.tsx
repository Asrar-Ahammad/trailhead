'use client';

import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer, ReferenceLine } from 'recharts';
import { Info } from '@phosphor-icons/react';

interface PaceChartProps {
  paceChartData: { dist: string; pace: number }[];
  avgPaceSPerKm: number;
}

function formatPace(paceSecPerKm: number): string {
  if (!paceSecPerKm || paceSecPerKm <= 0 || paceSecPerKm > 3600) return '-:--';
  const mins = Math.floor(paceSecPerKm / 60);
  const secs = Math.floor(paceSecPerKm % 60);
  return `${mins}:${String(secs).padStart(2, '0')}`;
}

function formatYAxisPace(val: number) {
  const m = Math.floor(val / 60);
  const s = Math.floor(val % 60);
  return `${m}:${String(s).padStart(2, '0')}`;
}

export default function PaceChart({ paceChartData, avgPaceSPerKm }: PaceChartProps) {
  return (
    <div className="mt-8">
      <div className="px-4 flex items-center justify-between mb-4">
        <h2 className="text-xl font-bold">Pace</h2>
        <Info size={20} className="text-muted-foreground" />
      </div>
      <div className="w-full h-48 px-2">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={paceChartData}>
            <defs>
              <linearGradient id="colorPace" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#4F89D8" stopOpacity={0.8}/>
                <stop offset="95%" stopColor="#4F89D8" stopOpacity={0}/>
              </linearGradient>
            </defs>
            <XAxis dataKey="dist" tick={{ fontSize: 10, fill: '#888' }} tickLine={false} axisLine={false} minTickGap={30} tickFormatter={(v) => `${v} km`} />
            <YAxis reversed domain={['dataMax', 'dataMin']} tickFormatter={formatYAxisPace} tick={{ fontSize: 10, fill: '#888' }} tickLine={false} axisLine={false} orientation="left" width={45} />
            <Tooltip 
              contentStyle={{ backgroundColor: '#1a1a1a', border: 'none', borderRadius: '8px', color: '#fff' }}
              labelStyle={{ color: '#888', marginBottom: '4px' }}
              formatter={(value: any) => [formatPace(value as number), 'Pace']}
              labelFormatter={(v) => `${v} km`}
            />
            <ReferenceLine y={avgPaceSPerKm} stroke="#fff" strokeDasharray="3 3" opacity={0.3} />
            <Area type="monotone" dataKey="pace" stroke="#4F89D8" fillOpacity={1} fill="url(#colorPace)" />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
