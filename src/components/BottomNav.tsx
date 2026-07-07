'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  House,
  MapTrifold,
  Circle,
  Trophy,
  UserCircle,
} from '@phosphor-icons/react';

const tabs = [
  { href: '/', label: 'Home', icon: House },
  { href: '/maps', label: 'Maps', icon: MapTrifold },
  { href: '/record', label: 'Record', icon: Circle },
  { href: '/groups', label: 'Groups', icon: Trophy },
  { href: '/you', label: 'You', icon: UserCircle },
];

export default function BottomNav() {
  const pathname = usePathname();

  // Hide bottom nav on auth pages
  if (pathname?.startsWith('/sign-in') || pathname?.startsWith('/sign-up')) {
    return null;
  }

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 bg-background pb-safe">
      <div className="max-w-lg mx-auto flex items-center justify-around h-14">
        {tabs.map((tab) => {
          const isActive =
            tab.href === '/'
              ? pathname === '/'
              : pathname?.startsWith(tab.href);
          const Icon = tab.icon;

          return (
            <Link
              key={tab.href}
              href={tab.href}
              className={`flex flex-col items-center justify-center gap-0.5 w-16 h-full transition-colors ${
                isActive ? 'text-primary' : 'text-muted-foreground'
              }`}
            >
              {tab.label === 'Record' ? (
                <div
                  className={`w-7 h-7 rounded-full border-2 flex items-center justify-center ${
                    isActive
                      ? 'border-primary bg-primary/10'
                      : 'border-muted-foreground'
                  }`}
                >
                  <div
                    className={`w-3 h-3 rounded-full ${
                      isActive ? 'bg-primary' : 'bg-muted-foreground'
                    }`}
                  />
                </div>
              ) : (
                <Icon
                  size={22}
                  weight={isActive ? 'fill' : 'regular'}
                />
              )}
              <span className="text-[10px] font-semibold leading-none">
                {tab.label}
              </span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
