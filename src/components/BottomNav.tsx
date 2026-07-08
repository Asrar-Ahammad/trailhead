'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  House,
  ClipboardText,
  PersonSimpleRun,
} from '@phosphor-icons/react';

const tabs = [
  { href: '/', label: 'Home', icon: House },
  { href: '/record', label: 'Record', icon: PersonSimpleRun },
  { href: '/you', label: 'You', icon: ClipboardText },
];

export default function BottomNav() {
  const pathname = usePathname();

  // Hide bottom nav on auth pages
  if (pathname?.startsWith('/sign-in') || pathname?.startsWith('/sign-up')) {
    return null;
  }

  const activeIndex = pathname === '/' ? 0 : pathname?.startsWith('/record') ? 1 : pathname?.startsWith('/you') ? 2 : -1;

  return (
    <nav className="fixed bottom-5 left-1/2 -translate-x-1/2 w-[calc(100%-2rem)] max-w-sm z-50">
      <div className="bg-[#121212]/95 backdrop-blur-xl border border-white/[0.08] shadow-[0_8px_32px_rgba(0,0,0,0.5)] rounded-2xl flex items-center justify-around h-16 px-2 relative">
        {/* Animated Active Dot */}
        {activeIndex !== -1 && (
          <div
            className="absolute bottom-1.5 w-1.5 h-1.5 rounded-full bg-primary transition-all duration-300 ease-out pointer-events-none"
            style={{
              left: activeIndex === 0 ? '18%' : activeIndex === 2 ? '82%' : '50%',
              transform: `translateX(-50%) scale(${activeIndex === 1 ? 0 : 1})`,
              opacity: activeIndex === 1 ? 0 : 1,
            }}
          />
        )}

        {tabs.map((tab) => {
          const isActive =
            tab.href === '/'
              ? pathname === '/'
              : pathname?.startsWith(tab.href);
          const Icon = tab.icon;

          if (tab.label === 'Record') {
            return (
              <Link
                key={tab.href}
                href={tab.href}
                className="relative -top-3 flex flex-col items-center justify-center w-12"
              >
                <div
                  className={`w-12 h-12 rounded-full flex items-center justify-center shadow-lg transition-all duration-300 ${
                    isActive
                      ? 'bg-primary text-white shadow-primary/35 scale-105 border-4 border-[#121212]'
                      : 'bg-neutral-900 border-4 border-primary/50 text-primary hover:bg-neutral-800 scale-100 hover:scale-105'
                  }`}
                >
                  <Icon
                    size={20}
                    weight="bold"
                  />
                </div>
                <span className={`text-[8px] font-black uppercase tracking-wider mt-1 transition-colors ${isActive ? 'text-primary' : 'text-muted-foreground'}`}>
                  Record
                </span>
              </Link>
            );
          }

          return (
            <Link
              key={tab.href}
              href={tab.href}
              className={`flex flex-col items-center justify-center gap-1 w-14 h-full relative transition-colors ${
                isActive ? 'text-primary' : 'text-muted-foreground hover:text-foreground'
              }`}
            >
              <Icon
                size={20}
                weight={isActive ? 'fill' : 'regular'}
                className="transition-transform duration-200"
              />
              <span className="text-[9px] font-bold tracking-wide leading-none">
                {tab.label}
              </span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
