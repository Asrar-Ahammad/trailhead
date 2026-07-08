'use client';

import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';
import { Info } from '@phosphor-icons/react';

interface ElevationChartProps {
  elevChartData: { dist: string; elev: number }[];
}

export default function ElevationChart({ elevChartData }: ElevationChartProps) {
  return (
    <div className="mt-8 border-t border-white/5 pt-6">
      <div className="px-4 flex items-center justify-between mb-4">
        <h2 className="text-xl font-bold">Elevation</h2>
        <div className="flex items-center gap-3">
          <div className="bg-[#2a2a2a] px-3 py-1 rounded-md text-xs font-bold text-white shadow-md flex items-center gap-1">
            {Math.round(elevChartData[elevChartData.length - 1]?.elev || 0)}m
          </div>
          <Info size={20} className="text-muted-foreground" />
        </div>
      </div>
      <div className="w-full h-40 px-2">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={elevChartData}>
            <defs>
              <linearGradient id="colorElev" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#8A8A8A" stopOpacity={0.8}/>
                <stop offset="95%" stopColor="#8A8A8A" stopOpacity={0}/>
              </linearGradient>
            </defs>
            <XAxis dataKey="dist" tick={{ fontSize: 10, fill: '#888' }} tickLine={false} axisLine={false} minTickGap={30} tickFormatter={(v) => `${v} km`} />
            <YAxis domain={['auto', 'auto']} tick={{ fontSize: 10, fill: '#888' }} tickLine={false} axisLine={false} orientation="left" width={40} />
            <Tooltip 
              contentStyle={{ backgroundColor: '#1a1a1a', border: 'none', borderRadius: '8px', color: '#fff' }}
              labelStyle={{ color: '#888', marginBottom: '4px' }}
              formatter={(value: any) => [`${Math.round(value as number)} m`, 'Elevation']}
              labelFormatter={(v) => `${v} km`}
            />
            <Area type="monotone" dataKey="elev" stroke="#8A8A8A" fillOpacity={1} fill="url(#colorElev)" />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
