'use client';

import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import {
  Trophy,
  Medal,
  Heartbeat,
  Lightning,
  Timer,
  Path,
} from '@phosphor-icons/react';

import { categoryConfig } from '@/lib/categoryConfig';

const springConfig = { type: 'spring' as const, stiffness: 400, damping: 17 };

interface Record {
  id: string;
  category: string;
  value: number;
  rank: number;
  achievedAt: string;
}

const rankColors = ['text-amber-400', 'text-zinc-300', 'text-amber-600'];
const rankBgs = ['bg-amber-400/10 border-amber-400/20', 'bg-zinc-300/10 border-zinc-300/20', 'bg-amber-600/10 border-amber-600/20'];

export default function GroupsPage() {
  const [records, setRecords] = useState<Record[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadRecords = async () => {
      try {
        const res = await fetch('/api/records');
        if (res.ok) setRecords(await res.json());
      } catch (e) {
        console.error('Error loading records:', e);
      } finally {
        setLoading(false);
      }
    };
    loadRecords();
  }, []);

  // Group records by category
  const grouped = records.reduce<{ [cat: string]: Record[] }>((acc, r) => {
    if (!acc[r.category]) acc[r.category] = [];
    acc[r.category].push(r);
    return acc;
  }, {});

  return (
    <div className="flex flex-col min-h-screen bg-background text-foreground select-none">
      {/* Header */}
      <header className="flex items-center justify-between px-4 py-3">
        <h1 className="text-xl font-bold text-foreground">Groups</h1>
        <Trophy size={22} className="text-primary" />
      </header>

      <main className="flex-1 overflow-y-auto hide-scrollbar px-4 pb-8">
        {/* PR Section Header */}
        <div className="flex items-center gap-2 mb-4 mt-2">
          <Medal size={18} className="text-primary" />
          <span className="text-sm font-black uppercase tracking-wider text-foreground">Personal Records</span>
        </div>

        {loading ? (
          <div className="flex flex-col items-center justify-center py-32 gap-3">
            <Heartbeat className="animate-spin text-primary" size={28} />
            <span className="text-xs text-muted-foreground">Loading records...</span>
          </div>
        ) : Object.keys(grouped).length === 0 ? (
          <div className="flex flex-col items-center justify-center py-32 text-center">
            <Trophy size={48} className="text-muted-foreground mb-4" />
            <p className="font-semibold text-foreground mb-1">No records yet</p>
            <p className="text-xs text-muted-foreground max-w-xs">
              Complete runs to earn personal records. Your top 3 times for each distance will appear here.
            </p>
          </div>
        ) : (
          <motion.div
            initial="hidden"
            animate="visible"
            variants={{ visible: { transition: { staggerChildren: 0.06 } } }}
            className="flex flex-col gap-4"
          >
            {Object.entries(grouped).map(([category, recs]) => {
              const config = categoryConfig[category] || {
                label: category,
                icon: Trophy,
                unit: '',
                format: (v: number) => String(v),
              };
              const Icon = config.icon;

              return (
                <motion.div
                  key={category}
                  variants={{
                    hidden: { opacity: 0, y: 15 },
                    visible: { opacity: 1, y: 0 },
                  }}
                  transition={springConfig}
                  className="bg-card border border-border rounded-xl overflow-hidden"
                >
                  {/* Category Header */}
                  <div className="flex items-center gap-2 px-4 py-3 border-b border-border/50">
                    <Icon size={16} className="text-primary" />
                    <span className="text-sm font-bold text-foreground">{config.label}</span>
                  </div>

                  {/* Rankings */}
                  <div className="divide-y divide-border/30">
                    {recs.sort((a, b) => a.rank - b.rank).map((rec) => {
                      const rankIdx = rec.rank - 1;
                      const dateStr = new Date(rec.achievedAt).toLocaleDateString('en-US', {
                        month: 'short',
                        day: 'numeric',
                        year: 'numeric',
                      });

                      return (
                        <div key={rec.id} className="flex items-center justify-between px-4 py-3">
                          <div className="flex items-center gap-3">
                            <div className={`w-8 h-8 rounded-full flex items-center justify-center text-xs font-black border ${rankBgs[rankIdx] || 'bg-secondary border-border'}`}>
                              <span className={rankColors[rankIdx] || 'text-muted-foreground'}>
                                {rec.rank}
                              </span>
                            </div>
                            <div className="flex flex-col">
                              <span className="text-sm font-black tabular-nums text-foreground">
                                {config.format(rec.value)}
                              </span>
                              <span className="text-[10px] text-muted-foreground">{dateStr}</span>
                            </div>
                          </div>
                          <Medal size={16} className={rankColors[rankIdx] || 'text-muted-foreground'} />
                        </div>
                      );
                    })}
                  </div>
                </motion.div>
              );
            })}
          </motion.div>
        )}
      </main>
    </div>
  );
}
