'use client';

import { useEffect, useRef, useState, useCallback } from 'react';
import L from 'leaflet';
import { useTheme } from 'next-themes';

interface MapProps {
  points: { lat: number; lng: number; timestamp: number }[];
  isFinished?: boolean;
  rounded?: boolean;
  showLocateButton?: boolean;
}

const createUserLocationIcon = () => {
  return L.divIcon({
    className: 'user-location-marker',
    html: `<div style="
      width: 16px; height: 16px; border-radius: 50%;
      background: #4285f4; border: 3px solid white;
      box-shadow: 0 0 0 4px rgba(66,133,244,0.25), 0 0 8px rgba(0,0,0,0.3);
    "></div>`,
    iconSize: [16, 16],
    iconAnchor: [8, 8],
  });
};

export default function Map({ points, isFinished = false, rounded = true, showLocateButton = false }: MapProps) {
  const mapContainerRef = useRef<HTMLDivElement | null>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const tileLayerRef = useRef<L.TileLayer | null>(null);
  const polylineRef = useRef<L.Polyline | null>(null);
  const startMarkerRef = useRef<L.Marker | null>(null);
  const endMarkerRef = useRef<L.Marker | null>(null);
  const userMarkerRef = useRef<L.Marker | null>(null);
  const [isLocating, setIsLocating] = useState(false);
  
  const { theme } = useTheme();

  // Dark & Light Tile Providers
  const lightTiles = 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
  const darkTiles = 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
  const attribution = '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>';

  // Initialize Map
  useEffect(() => {
    if (!mapContainerRef.current) return;

    // Use default coordinates if no points
    const defaultCenter: [number, number] = points.length > 0 
      ? [points[points.length - 1].lat, points[points.length - 1].lng]
      : [37.7749, -122.4194]; // SF

    const map = L.map(mapContainerRef.current, {
      center: defaultCenter,
      zoom: 15,
      zoomControl: false, // Clean UI, no default zoom controls
      attributionControl: true,
    });

    mapInstanceRef.current = map;

    // Set up active tile layer
    const activeTileUrl = theme === 'dark' ? darkTiles : lightTiles;
    const tileLayer = L.tileLayer(activeTileUrl, {
      attribution,
      maxZoom: 20,
    }).addTo(map);

    tileLayerRef.current = tileLayer;

    // Add polyline
    const latLngs = points.map(p => L.latLng(p.lat, p.lng));
    const polyline = L.polyline(latLngs, {
      color: '#fc4c02', // Strava coral
      weight: 5,
      opacity: 0.95,
      lineJoin: 'round',
    }).addTo(map);

    polylineRef.current = polyline;

    // Fit bounds if points exist
    if (latLngs.length > 0) {
      map.fitBounds(polyline.getBounds(), { padding: [20, 20] });
    }

    return () => {
      // Cleanup to prevent memory leaks
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
      }
    };
  }, []); // Run once on mount

  // Update Tiles on Theme Change
  useEffect(() => {
    if (!tileLayerRef.current) return;
    const activeTileUrl = theme === 'dark' ? darkTiles : lightTiles;
    tileLayerRef.current.setUrl(activeTileUrl);
  }, [theme]);

  // Update Polyline, Markers, and Bounds on points change
  useEffect(() => {
    const map = mapInstanceRef.current;
    const polyline = polylineRef.current;
    if (!map || !polyline) return;

    const latLngs = points.map(p => L.latLng(p.lat, p.lng));
    polyline.setLatLngs(latLngs);

    // Update start marker (green dot)
    if (latLngs.length > 0) {
      const startPoint = latLngs[0];
      if (!startMarkerRef.current) {
        const startIcon = L.divIcon({
          className: 'custom-start-marker',
          html: `<div style="background-color: #22c55e; width: 12px; height: 12px; border-radius: 50%; border: 2px solid white; box-shadow: 0 0 6px rgba(0,0,0,0.3);"></div>`,
          iconSize: [12, 12],
          iconAnchor: [6, 6],
        });
        startMarkerRef.current = L.marker(startPoint, { icon: startIcon }).addTo(map);
      } else {
        startMarkerRef.current.setLatLng(startPoint);
      }
    } else if (startMarkerRef.current) {
      startMarkerRef.current.remove();
      startMarkerRef.current = null;
    }

    // Update user current position marker (blue pulsing dot) if tracking is active
    if (!isFinished && latLngs.length > 0) {
      const currentPoint = latLngs[latLngs.length - 1];
      if (userMarkerRef.current) {
        userMarkerRef.current.setLatLng(currentPoint);
      } else {
        userMarkerRef.current = L.marker(currentPoint, { icon: createUserLocationIcon() }).addTo(map);
      }
    } else if (isFinished && userMarkerRef.current) {
      userMarkerRef.current.remove();
      userMarkerRef.current = null;
    }

    // Update end marker (red dot) if finished/stopped
    if (isFinished && latLngs.length > 1) {
      const endPoint = latLngs[latLngs.length - 1];
      if (!endMarkerRef.current) {
        const endIcon = L.divIcon({
          className: 'custom-end-marker',
          html: `<div style="background-color: #ef4444; width: 12px; height: 12px; border-radius: 50%; border: 2px solid white; box-shadow: 0 0 6px rgba(0,0,0,0.3);"></div>`,
          iconSize: [12, 12],
          iconAnchor: [6, 6],
        });
        endMarkerRef.current = L.marker(endPoint, { icon: endIcon }).addTo(map);
      } else {
        endMarkerRef.current.setLatLng(endPoint);
      }
    } else if (endMarkerRef.current) {
      endMarkerRef.current.remove();
      endMarkerRef.current = null;
    }

    // Auto-fit/pan bounds
    if (latLngs.length > 0) {
      if (isFinished) {
        map.fitBounds(polyline.getBounds(), { padding: [45, 45], animate: true });
      } else {
        // Follow user
        const lastPoint = latLngs[latLngs.length - 1];
        map.panTo(lastPoint, { animate: true });
      }
    }
  }, [points, isFinished]);

  // Locate current position
  const handleLocate = useCallback(() => {
    const map = mapInstanceRef.current;
    if (!map || !navigator.geolocation) return;

    setIsLocating(true);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const { latitude, longitude } = pos.coords;
        const latlng = L.latLng(latitude, longitude);

        // Add or update a blue pulsing dot marker
        if (userMarkerRef.current) {
          userMarkerRef.current.setLatLng(latlng);
        } else {
          userMarkerRef.current = L.marker(latlng, { icon: createUserLocationIcon() }).addTo(map);
        }

        map.flyTo(latlng, 16, { animate: true, duration: 0.8 });
        setIsLocating(false);
      },
      (err) => {
        console.error('Geolocation error:', err);
        setIsLocating(false);
      },
      { enableHighAccuracy: true, timeout: 10000 }
    );
  }, []);

  return (
    <div className={`w-full h-full relative overflow-hidden bg-background ${rounded ? 'rounded-2xl border border-border shadow-inner' : ''}`}>
      <div ref={mapContainerRef} className="absolute inset-0 z-0" />

      {/* Locate Me Button */}
      {showLocateButton && (
        <button
          onClick={handleLocate}
          disabled={isLocating}
          className="absolute bottom-4 right-4 z-20 w-10 h-10 rounded-full bg-background/90 backdrop-blur-sm border border-border shadow-lg flex items-center justify-center transition-colors hover:bg-secondary disabled:opacity-50"
          aria-label="Show my location"
        >
          {isLocating ? (
            <svg className="w-5 h-5 text-primary animate-spin" viewBox="0 0 24 24" fill="none">
              <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="2" opacity="0.3" />
              <path d="M12 2a10 10 0 0 1 10 10" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
            </svg>
          ) : (
            <svg className="w-5 h-5 text-foreground" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="12" cy="12" r="3" />
              <path d="M12 2v4M12 18v4M2 12h4M18 12h4" />
            </svg>
          )}
        </button>
      )}
    </div>
  );
}
