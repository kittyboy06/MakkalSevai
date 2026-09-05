import React, { useEffect, useState, useRef } from 'react';
import L from 'leaflet';
import { 
  Filter, 
  Search, 
  Phone, 
  Battery, 
  Gauge, 
  Radio, 
  MapPin, 
  CheckCircle, 
  Clock, 
  X,
  Layers
} from 'lucide-react';
import { WorkerTelemetry } from '../types/adminTypes';
import { fetchWorkerTelemetry } from '../api/adminApi';

interface SpatialFleetMapProps {
  onNavigateTab: (tab: string) => void;
}

export const SpatialFleetMap: React.FC<SpatialFleetMapProps> = ({ onNavigateTab }) => {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const markersGroupRef = useRef<L.LayerGroup | null>(null);

  const [fleet, setFleet] = useState<WorkerTelemetry[]>([]);
  const [selectedWorker, setSelectedWorker] = useState<WorkerTelemetry | null>(null);
  const [tradeFilter, setTradeFilter] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState<string>('');

  // Load telemetry data
  useEffect(() => {
    let isMounted = true;
    const loadFleet = async () => {
      try {
        const res = await fetchWorkerTelemetry();
        if (isMounted) {
          setFleet(res.fleet);
          // Auto-select Rajesh Kumar by default for demo inspection
          const rajesh = res.fleet.find(w => w.name.toLowerCase().includes('rajesh'));
          if (rajesh && !selectedWorker) {
            setSelectedWorker(rajesh);
          }
        }
      } catch (err) {
        console.error('Failed to load fleet telemetry:', err);
      }
    };

    loadFleet();
    const interval = setInterval(loadFleet, 4000);
    return () => {
      isMounted = false;
      clearInterval(interval);
    };
  }, []);

  // Initialize Leaflet Map
  useEffect(() => {
    if (!mapContainerRef.current || mapInstanceRef.current) return;

    // Center at Chennai T. Nagar
    const map = L.map(mapContainerRef.current, {
      center: [13.0418, 80.2341],
      zoom: 14,
      zoomControl: false
    });

    L.control.zoom({ position: 'bottomleft' }).addTo(map);

    // OpenStreetMap standard tile layer
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap contributors'
    }).addTo(map);

    const markersGroup = L.layerGroup().addTo(map);
    markersGroupRef.current = markersGroup;
    mapInstanceRef.current = map;

    return () => {
      map.remove();
      mapInstanceRef.current = null;
    };
  }, []);

  // Render markers onto map
  useEffect(() => {
    if (!mapInstanceRef.current || !markersGroupRef.current) return;
    const markersGroup = markersGroupRef.current;
    markersGroup.clearLayers();

    // Customer pin (Senthil Nathan at Flat 4B Shanti Nilayam)
    const customerIcon = L.divIcon({
      className: 'custom-pin-customer',
      html: `
        <div style="background-color: #1E3A8A; color: white; width: 34px; height: 34px; border-radius: 50%; display: flex; align-items: center; justify-content: center; border: 2.5px solid white; box-shadow: 0 4px 6px rgba(0,0,0,0.3); font-size: 16px;">
          🏠
        </div>
      `,
      iconSize: [34, 34],
      iconAnchor: [17, 17]
    });
    const customerMarker = L.marker([13.0418, 80.2341], { icon: customerIcon });
    customerMarker.bindPopup('<b>Customer: Senthil Nathan</b><br/>Flat 4B, Shanti Nilayam, T. Nagar');
    markersGroup.addLayer(customerMarker);

    // Worker pins
    fleet.forEach((worker) => {
      // Filter logic
      if (tradeFilter !== 'all' && !worker.trade.toLowerCase().includes(tradeFilter.toLowerCase())) {
        return;
      }
      if (statusFilter !== 'all' && worker.status !== statusFilter) {
        return;
      }
      if (searchQuery && !worker.name.toLowerCase().includes(searchQuery.toLowerCase())) {
        return;
      }

      const isEnroute = worker.status === 'enroute';
      const isAvailable = worker.status === 'available';
      const bgColor = isAvailable ? '#059669' : (isEnroute ? '#D97706' : '#2563EB');
      const iconEmoji = worker.trade.includes('Electrician') ? '⚡' : (worker.trade.includes('Plumber') ? '🚰' : '🛠️');

      const workerIcon = L.divIcon({
        className: 'custom-pin-worker',
        html: `
          <div style="position: relative; display: flex; align-items: center; justify-content: center;">
            <div style="background-color: ${bgColor}; color: white; width: 36px; height: 36px; border-radius: 50%; display: flex; align-items: center; justify-content: center; border: 2.5px solid white; box-shadow: 0 4px 8px rgba(0,0,0,0.25); font-size: 16px; font-weight: bold; cursor: pointer;">
              ${iconEmoji}
            </div>
            ${isEnroute ? `<div style="position: absolute; width: 44px; height: 44px; border-radius: 50%; border: 2px solid ${bgColor}; animation: ping 1.5s cubic-bezier(0,0,0.2,1) infinite;"></div>` : ''}
          </div>
        `,
        iconSize: [36, 36],
        iconAnchor: [18, 18]
      });

      const marker = L.marker([worker.lat, worker.lng], { icon: workerIcon });
      marker.on('click', () => {
        setSelectedWorker(worker);
      });
      markersGroup.addLayer(marker);

      // Draw dashed dispatch route line from enroute worker to customer
      if (isEnroute && worker.name.includes('Rajesh')) {
        const polyline = L.polyline([[worker.lat, worker.lng], [13.0418, 80.2341]], {
          color: '#D97706',
          weight: 3.5,
          dashArray: '6, 8',
          opacity: 0.85
        });
        markersGroup.addLayer(polyline);
      }
    });
  }, [fleet, tradeFilter, statusFilter, searchQuery]);

  return (
    <div className="relative w-full h-[calc(100vh-100px)] flex overflow-hidden">
      {/* Floating Left Control Card */}
      <div className="absolute top-4 left-4 z-20 w-72 bg-white/95 backdrop-blur-md rounded-xl border border-slate-200 shadow-md p-4 space-y-4">
        <div className="flex items-center justify-between border-b border-slate-100 pb-2.5">
          <h3 className="font-bold text-slate-900 text-xs tracking-tight flex items-center gap-1.5 uppercase font-mono">
            <Filter className="w-3.5 h-3.5 text-blue-700" />
            Fleet Filter Controls
          </h3>
          <span className="text-[10px] font-mono font-bold bg-slate-100 text-slate-600 px-1.5 py-0.5 rounded">
            {fleet.length} ONLINE
          </span>
        </div>

        {/* Search */}
        <div className="relative">
          <Search className="w-3.5 h-3.5 text-slate-400 absolute left-2.5 top-2.5" />
          <input
            type="text"
            placeholder="Search worker or trade..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full bg-slate-50 border border-slate-200 rounded-lg pl-8 pr-3 py-1.5 text-xs text-slate-900 placeholder:text-slate-400 focus:outline-none focus:border-blue-600"
          />
        </div>

        {/* Trade Selector */}
        <div className="space-y-1">
          <label className="text-[10px] font-bold text-slate-400 uppercase font-mono tracking-wider">
            Trade Category
          </label>
          <div className="grid grid-cols-2 gap-1.5 text-xs">
            {['all', 'electrician', 'plumber', 'ac tech'].map((trade) => (
              <button
                key={trade}
                onClick={() => setTradeFilter(trade)}
                className={`px-2.5 py-1.5 rounded-md text-left font-medium transition cursor-pointer capitalize text-[11px] ${
                  tradeFilter === trade
                    ? 'bg-blue-900 text-white font-semibold'
                    : 'bg-slate-50 hover:bg-slate-100 text-slate-700 border border-slate-200'
                }`}
              >
                {trade}
              </button>
            ))}
          </div>
        </div>

        {/* Status Selector */}
        <div className="space-y-1">
          <label className="text-[10px] font-bold text-slate-400 uppercase font-mono tracking-wider">
            Availability Status
          </label>
          <div className="flex flex-col space-y-1 text-xs font-medium">
            {[
              { id: 'all', label: 'All Statuses' },
              { id: 'available', label: '🟢 Available & Standby' },
              { id: 'enroute', label: '🟡 Enroute to Citizen' },
              { id: 'in_progress', label: '🔵 In-Progress at Location' }
            ].map((st) => (
              <button
                key={st.id}
                onClick={() => setStatusFilter(st.id)}
                className={`px-2.5 py-1.5 rounded-md text-left text-[11px] transition cursor-pointer ${
                  statusFilter === st.id
                    ? 'bg-slate-900 text-white font-semibold'
                    : 'bg-slate-50 hover:bg-slate-100 text-slate-700'
                }`}
              >
                {st.label}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Main Full-Bleed Map Canvas */}
      <div ref={mapContainerRef} className="flex-1 w-full h-full z-10" />

      {/* Right Worker Telemetry Drawer (380px wide) */}
      {selectedWorker && (
        <div className="w-96 bg-white border-l border-slate-200 flex flex-col z-20 shadow-xl overflow-y-auto shrink-0 animate-in slide-in-from-right duration-200">
          {/* Drawer Header */}
          <div className="p-4 border-b border-slate-200 bg-slate-900 text-white flex items-center justify-between">
            <div>
              <span className="text-[10px] font-mono text-emerald-400 font-semibold tracking-wider uppercase block">
                Live Telemetry Drawer
              </span>
              <h3 className="text-base font-bold tracking-tight">
                {selectedWorker.name}
              </h3>
            </div>
            <button
              onClick={() => setSelectedWorker(null)}
              className="p-1 rounded-md text-slate-400 hover:text-white hover:bg-slate-800 transition cursor-pointer"
            >
              <X className="w-4 h-4" />
            </button>
          </div>

          <div className="p-5 space-y-5 text-xs">
            {/* Status Pill & Trade */}
            <div className="flex items-center justify-between">
              <span className="font-semibold text-slate-700 bg-slate-100 px-2.5 py-1 rounded-md text-xs border border-slate-200">
                {selectedWorker.trade}
              </span>
              <span className={`px-2.5 py-1 rounded-full text-[11px] font-bold uppercase tracking-wider ${
                selectedWorker.status === 'enroute'
                  ? 'bg-amber-100 text-amber-900 border border-amber-300'
                  : 'bg-emerald-100 text-emerald-900 border border-emerald-300'
              }`}>
                {selectedWorker.status}
              </span>
            </div>

            {/* Profile Overview */}
            <div className="bg-slate-50 p-3.5 rounded-xl border border-slate-200 space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-slate-500">Citizen Rating:</span>
                <span className="font-bold text-slate-900 font-tabular">⭐ {selectedWorker.rating_avg} / 5.0</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-slate-500">Fulfilled Jobs:</span>
                <span className="font-bold text-slate-900 font-tabular">{selectedWorker.jobs_completed} jobs</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-slate-500">e-Shram Status:</span>
                <span className="text-emerald-700 font-semibold flex items-center gap-1">
                  <CheckCircle className="w-3.5 h-3.5" /> UAN-TN-2026-88392
                </span>
              </div>
            </div>

            {/* Realtime Device Telemetry Grid */}
            <div className="space-y-1.5">
              <label className="text-[10px] font-bold text-slate-400 uppercase font-mono tracking-wider">
                Device Telemetry Pings
              </label>
              <div className="grid grid-cols-3 gap-2 text-center">
                <div className="p-2.5 rounded-lg bg-slate-50 border border-slate-200">
                  <Battery className="w-4 h-4 mx-auto text-emerald-600 mb-1" />
                  <span className="text-[10px] text-slate-500 block">Battery</span>
                  <span className="font-bold text-slate-900 font-tabular">{selectedWorker.battery_pct}%</span>
                </div>
                <div className="p-2.5 rounded-lg bg-slate-50 border border-slate-200">
                  <Gauge className="w-4 h-4 mx-auto text-blue-600 mb-1" />
                  <span className="text-[10px] text-slate-500 block">Speed</span>
                  <span className="font-bold text-slate-900 font-tabular">{selectedWorker.speed_kmh} km/h</span>
                </div>
                <div className="p-2.5 rounded-lg bg-slate-50 border border-slate-200">
                  <Radio className="w-4 h-4 mx-auto text-amber-600 mb-1" />
                  <span className="text-[10px] text-slate-500 block">GPS Ping</span>
                  <span className="font-bold text-slate-900">{selectedWorker.last_gps_ping}</span>
                </div>
              </div>
            </div>

            {/* In-Flight Order Dispatch Dossier */}
            {selectedWorker.active_order_id && (
              <div className="bg-amber-50/60 border border-amber-200 rounded-xl p-3.5 space-y-2">
                <div className="flex items-center justify-between">
                  <span className="font-mono font-bold text-amber-900 text-xs">
                    {selectedWorker.active_order_id}
                  </span>
                  <span className="text-[11px] font-semibold text-amber-800 bg-amber-100 px-2 py-0.5 rounded">
                    ETA: {selectedWorker.eta_mins} mins
                  </span>
                </div>
                <div className="text-xs text-slate-700">
                  <p className="font-semibold text-slate-900">Destination:</p>
                  <p className="text-slate-600 mt-0.5">{selectedWorker.customer_destination}</p>
                </div>
              </div>
            )}

            {/* Actions */}
            <div className="pt-2 space-y-2">
              <a
                href={`tel:${selectedWorker.phone}`}
                className="w-full flex items-center justify-center space-x-2 py-2.5 rounded-lg bg-slate-900 hover:bg-slate-800 text-white font-semibold transition text-xs shadow-xs"
              >
                <Phone className="w-3.5 h-3.5 text-emerald-400" />
                <span>Call Worker ({selectedWorker.phone})</span>
              </a>
              <button
                onClick={() => onNavigateTab('orders')}
                className="w-full py-2.5 rounded-lg border border-slate-200 hover:bg-slate-50 text-slate-700 font-semibold transition text-xs cursor-pointer"
              >
                View Order Dossier in Registry
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
