'use client';

import dynamic from 'next/dynamic';
import { Compass } from '@phosphor-icons/react';

const Map = dynamic(() => import('@/components/Map'), { ssr: false });

export default function MapsPage() {
  return (
    <div className="flex flex-col h-full bg-background text-foreground select-none">
      {/* Header */}
      <header className="flex items-center justify-between px-4 py-3 z-10">
        <h1 className="text-xl font-bold text-foreground">Maps</h1>
        <Compass size={22} className="text-primary" />
      </header>

      {/* Coming Soon Placeholder */}
      <div className="flex-1 flex flex-col items-center justify-center p-8 text-center text-muted-foreground">
        <Compass size={48} className="mb-4 opacity-50" />
        <h2 className="text-xl font-semibold text-foreground mb-2">Coming Soon</h2>
        <p className="text-sm">We&apos;re working on an interactive map explorer for your routes.</p>
      </div>
    </div>
  );
}
