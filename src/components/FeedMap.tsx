'use client';

import { useEffect, useRef, useState } from 'react';
import L from 'leaflet';

interface FeedMapProps {
  runId: string;
}

export default function FeedMap({ runId }: FeedMapProps) {
  const containerRef = useRef<HTMLDivElement | null>(null);
  const mapRef = useRef<L.Map | null>(null);
  const [points, setPoints] = useState<{ lat: number; lng: number }[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    const loadPoints = async () => {
      try {
        const res = await fetch(`/api/runs/${runId}/points`);
        if (res.ok) {
          const data = await res.json();
          if (!cancelled && Array.isArray(data)) {
            setPoints(data.map((p: any) => ({ lat: p.lat, lng: p.lng })));
          }
        }
      } catch (e) {
        // Silently fail for feed maps
      } finally {
        if (!cancelled) setLoading(false);
      }
    };
    loadPoints();
    return () => { cancelled = true; };
  }, [runId]);

  useEffect(() => {
    if (!containerRef.current || points.length === 0) return;

    // Prevent re-initializing
    if (mapRef.current) {
      mapRef.current.remove();
      mapRef.current = null;
    }

    const center: [number, number] = [points[0].lat, points[0].lng];
    const map = L.map(containerRef.current, {
      center,
      zoom: 15,
      zoomControl: false,
      attributionControl: true,
      dragging: false,
      scrollWheelZoom: false,
      doubleClickZoom: false,
      touchZoom: false,
      boxZoom: false,
      keyboard: false,
    });

    mapRef.current = map;

    // Removed tileLayer to only show the path outline

    const latLngs = points.map(p => L.latLng(p.lat, p.lng));
    const polyline = L.polyline(latLngs, {
      color: '#fc4c02',
      weight: 4,
      opacity: 1,
      lineJoin: 'round',
      lineCap: 'round',
    }).addTo(map);

    if (latLngs.length > 0) {
      map.fitBounds(polyline.getBounds(), { padding: [30, 30] });
    }

    return () => {
      if (mapRef.current) {
        mapRef.current.remove();
        mapRef.current = null;
      }
    };
  }, [points]);

  if (loading) {
    return (
      <div className="w-full h-full bg-secondary flex items-center justify-center">
        <span className="text-xs text-muted-foreground">Loading map...</span>
      </div>
    );
  }

  if (points.length === 0) {
    return (
      <div className="w-full h-full bg-secondary flex items-center justify-center">
        <span className="text-xs text-muted-foreground">No map data</span>
      </div>
    );
  }

  return <div ref={containerRef} className="w-full h-full" />;
}
