'use client';

import { useEffect } from 'react';

export default function PwaRegister() {
  useEffect(() => {
    if (typeof window !== 'undefined' && 'serviceWorker' in navigator) {
      window.addEventListener('load', () => {
        navigator.serviceWorker
          .register('/sw.js')
          .then((registration) => {
            if (process.env.NODE_ENV === 'development') {
              console.log('Service Worker registered successfully with scope:', registration.scope);
            }
          })
          .catch((error) => {
            if (process.env.NODE_ENV === 'development') {
              console.error('Service Worker registration failed:', error);
            }
          });
      });
    }
  }, []);

  return null;
}
