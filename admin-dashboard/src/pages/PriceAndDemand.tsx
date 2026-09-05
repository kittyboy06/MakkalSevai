import React, { useEffect, useState, useRef } from 'react';
import L from 'leaflet';
import { 
  TrendingUp, 
  Lock, 
  IndianRupee, 
  Download, 
  FileSpreadsheet, 
  BarChart3, 
  MapPin, 
  CheckCircle,
  HelpCircle
} from 'lucide-react';
import { PriceRule, HeatmapFeature } from '../types/adminTypes';
import { fetchPriceGovernance, fetchHeatmap } from '../api/adminApi';

export const PriceAndDemand: React.FC = () => {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);

  const [priceRules, setPriceRules] = useState<PriceRule[]>([]);
  const [heatmapData, setHeatmapData] = useState<{ features: HeatmapFeature[]; cluster_inference: string } | null>(null);

  useEffect(() => {
    fetchPriceGovernance().then(res => setPriceRules(res.regulated_trades));
    fetchHeatmap().then(res => setHeatmapData(res));
  }, []);

  // Initialize Leaflet Map for demand density visualization
  useEffect(() => {
    if (!mapContainerRef.current || mapInstanceRef.current) return;

    const map = L.map(mapContainerRef.current, {
      center: [13.0418, 80.2341],
      zoom: 13,
      zoomControl: false
    });

    L.control.zoom({ position: 'bottomleft' }).addTo(map);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap contributors'
    }).addTo(map);

    // Add circular density heat buffers for Chennai clusters
    const clusters = [
      { name: 'T. Nagar Urban Core', lat: 13.0418, lng: 80.2341, radius: 1200, color: '#EF4444', orders: 34, trade: 'Electrician' },
      { name: 'Mylapore Cultural Quarter', lat: 13.0339, lng: 80.2676, radius: 900, color: '#F59E0B', orders: 21, trade: 'Plumber' },
      { name: 'Anna Nagar West', lat: 13.0850, lng: 80.2100, radius: 800, color: '#3B82F6', orders: 18, trade: 'Carpenter' },
      { name: 'Adyar Residential Zone', lat: 13.0060, lng: 80.2550, radius: 700, color: '#10B981', orders: 12, trade: 'AC Tech' }
    ];

    clusters.forEach((c) => {
      const circle = L.circle([c.lat, c.lng], {
        color: c.color,
        fillColor: c.color,
        fillOpacity: 0.35,
        radius: c.radius,
        weight: 2
      }).addTo(map);

      circle.bindPopup(`
        <div style="font-family: sans-serif; font-size: 12px;">
          <b>${c.name}</b><br/>
          Density: <b>${c.orders} requests/day</b><br/>
          Dominant Trade: <b>${c.trade}</b>
        </div>
      `);
    });

    mapInstanceRef.current = map;

    return () => {
      map.remove();
      mapInstanceRef.current = null;
    };
  }, []);

  const handleExportCsv = () => {
    const csvContent = "data:text/csv;charset=utf-8," 
      + "Trade,Municipal Ceiling (INR),Platform Avg (INR),Worker Take-Home (INR),Civic Margin (%),Status\n"
      + priceRules.map(e => `${e.trade},${e.govt_cap},${e.platform_avg},${e.worker_take_home},${e.civic_margin_pct}%,${e.status}`).join("\n");
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", "MakkalSevai_Price_Governance_Audit_2026.csv");
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="p-6 space-y-6 max-w-[1600px] mx-auto">
      {/* Page Title & Context */}
      <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-xs flex items-center justify-between">
        <div>
          <h2 className="text-base font-bold text-slate-900 tracking-tight flex items-center gap-2">
            <TrendingUp className="w-5 h-5 text-blue-900" />
            Platform Price Governance & Demand Intelligence Heatmap
          </h2>
          <p className="text-xs text-slate-500">
            Enforce statutory price ceilings, audit fixed commission caps, and evaluate platform vocational demand density.
          </p>
        </div>
        <div className="flex space-x-2">
          <button
            onClick={handleExportCsv}
            className="flex items-center space-x-1.5 px-3 py-1.5 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 text-slate-700 font-semibold text-xs transition cursor-pointer shadow-xs"
          >
            <FileSpreadsheet className="w-3.5 h-3.5 text-emerald-600" />
            <span>Export Raw Audit CSV</span>
          </button>
          <button
            onClick={() => alert("Municipal Audit Report PDF compiled for Chennai Corporation Zone 10.")}
            className="flex items-center space-x-1.5 px-3 py-1.5 rounded-lg bg-slate-900 hover:bg-slate-800 text-white font-semibold text-xs transition cursor-pointer shadow-xs"
          >
            <Download className="w-3.5 h-3.5" />
            <span>Download Municipal Audit (PDF)</span>
          </button>
        </div>
      </div>

      {/* Main Two-Column Split (50% / 50%) */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Left Column (50%): Civic Price Ceiling & Fare Governance */}
        <div className="lg:col-span-6 bg-white rounded-xl border border-slate-200 p-5 shadow-xs space-y-4">
          <div className="border-b border-slate-100 pb-3">
            <span className="text-[10px] font-mono text-slate-400 uppercase font-bold tracking-wider">
              Prototype Configuration · Decision A-D10
            </span>
            <h3 className="text-sm font-bold text-slate-900 tracking-tight">
              Platform Price Governance & Fare Limits
            </h3>
            <p className="text-xs text-slate-500">
              Statutory rate parameters configured to protect both citizens from price gouging and informal workers from exploitation.
            </p>
          </div>

          {/* Locked Badges */}
          <div className="grid grid-cols-2 gap-3">
            <div className="p-3 rounded-lg bg-emerald-50 border border-emerald-200 flex items-center space-x-2.5">
              <Lock className="w-4 h-4 text-emerald-700 shrink-0" />
              <div>
                <span className="text-[10px] font-mono font-bold text-emerald-800 uppercase block">Surge Pricing Policy</span>
                <span className="text-xs font-bold text-emerald-950">LOCKED (0.0x Surge)</span>
              </div>
            </div>

            <div className="p-3 rounded-lg bg-blue-50 border border-blue-200 flex items-center space-x-2.5">
              <IndianRupee className="w-4 h-4 text-blue-700 shrink-0" />
              <div>
                <span className="text-[10px] font-mono font-bold text-blue-800 uppercase block">Platform Fee Ceiling</span>
                <span className="text-xs font-bold text-blue-950 font-tabular">Fixed ₹25.00</span>
              </div>
            </div>
          </div>

          {/* Regulated Caps Table */}
          <div className="overflow-x-auto border border-slate-200 rounded-lg">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-50 border-b border-slate-200 text-slate-500 font-mono uppercase tracking-wider text-[10px]">
                <tr>
                  <th className="py-2.5 px-3">Trade Category</th>
                  <th className="py-2.5 px-3 font-tabular">Govt Ceiling</th>
                  <th className="py-2.5 px-3 font-tabular">Platform Avg</th>
                  <th className="py-2.5 px-3 font-tabular">Worker Take-Home</th>
                  <th className="py-2.5 px-3">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 font-medium">
                {priceRules.map((rule) => (
                  <tr key={rule.trade} className="hover:bg-slate-50">
                    <td className="py-2.5 px-3 font-semibold text-slate-900">{rule.trade}</td>
                    <td className="py-2.5 px-3 font-mono text-slate-700 font-tabular">₹{rule.govt_cap.toFixed(2)}</td>
                    <td className="py-2.5 px-3 font-mono font-bold text-blue-900 font-tabular">₹{rule.platform_avg.toFixed(2)}</td>
                    <td className="py-2.5 px-3 font-mono text-emerald-800 font-tabular">₹{rule.worker_take_home.toFixed(2)} ({rule.civic_margin_pct}%)</td>
                    <td className="py-2.5 px-3">
                      <span className="bg-emerald-100 text-emerald-800 px-2 py-0.5 rounded text-[10px] font-bold border border-emerald-200 flex items-center gap-1 w-fit">
                        <CheckCircle className="w-2.5 h-2.5" /> {rule.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="p-3 bg-slate-50 rounded-lg border border-slate-200 text-[11px] text-slate-600 space-y-1">
            <p className="font-semibold text-slate-800 flex items-center gap-1">
              <HelpCircle className="w-3 h-3 text-slate-400" />
              Civic Margin Rule:
            </p>
            <p>
              By capping platform fees at fixed ₹25.00, tradespeople retain between 90.9% and 94.8% of citizen payments, dramatically higher than private platforms that deduct 25% to 35%.
            </p>
          </div>
        </div>

        {/* Right Column (50%): Demand Density Heatmap & Vocational Intelligence */}
        <div className="lg:col-span-6 bg-white rounded-xl border border-slate-200 p-5 shadow-xs flex flex-col justify-between space-y-4">
          <div className="border-b border-slate-100 pb-3 flex items-center justify-between">
            <div>
              <span className="text-[10px] font-mono text-slate-400 uppercase font-bold tracking-wider">
                Geospatial Density · Decision A-D11
              </span>
              <h3 className="text-sm font-bold text-slate-900 tracking-tight flex items-center gap-1.5">
                <BarChart3 className="w-4 h-4 text-blue-800" />
                Historical Demand Density Heatmap
              </h3>
            </div>
            <div className="flex items-center space-x-2 text-[10px] font-mono">
              <span className="flex items-center gap-1 text-red-600"><span className="w-2 h-2 rounded-full bg-red-500"></span> High</span>
              <span className="flex items-center gap-1 text-amber-600"><span className="w-2 h-2 rounded-full bg-amber-500"></span> Medium</span>
              <span className="flex items-center gap-1 text-emerald-600"><span className="w-2 h-2 rounded-full bg-emerald-500"></span> Moderate</span>
            </div>
          </div>

          {/* Leaflet Heatmap Canvas */}
          <div className="h-64 rounded-xl overflow-hidden border border-slate-200 relative">
            <div ref={mapContainerRef} className="w-full h-full" />
          </div>

          {/* Historical Data Inference Card (A-D11) */}
          <div className="p-4 bg-slate-900 text-slate-100 rounded-xl border border-slate-800 space-y-2">
            <div className="flex items-center space-x-2">
              <span className="text-amber-400 text-xs">📊</span>
              <h4 className="text-xs font-bold uppercase tracking-wider text-amber-300 font-mono">
                Platform Historical Data Analytics (Inference)
              </h4>
            </div>
            <p className="text-xs text-slate-300 leading-relaxed">
              {heatmapData?.cluster_inference || (
                'Platform Data Analytics: High electrician booking density detected in T. Nagar cluster (34 requests/day, 42 active tradespeople). Historical fulfillment latency averages 8.2 mins. Suggests target priority zone for municipal vocational training cohort and skill certification drives.'
              )}
            </p>
          </div>

          <div className="text-[11px] text-slate-400 font-mono flex items-center justify-between border-t border-slate-100 pt-3">
            <span>Spatial Aggregation Engine: PostGIS ST_ClusterKMeans</span>
            <span>Cluster Count: 4 Wards</span>
          </div>
        </div>
      </div>
    </div>
  );
};
