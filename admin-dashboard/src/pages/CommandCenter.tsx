import React, { useEffect, useState } from 'react';
import { 
  Zap, 
  Users, 
  ShieldCheck, 
  IndianRupee, 
  CheckCircle2, 
  AlertTriangle,
  ArrowRight,
  TrendingUp,
  MapPin
} from 'lucide-react';
import { KpiStatCard } from '../components/KpiStatCard';
import { KpiData } from '../types/adminTypes';
import { fetchKpis } from '../api/adminApi';

interface CommandCenterProps {
  onNavigateTab: (tab: string) => void;
}

export const CommandCenter: React.FC<CommandCenterProps> = ({ onNavigateTab }) => {
  const [kpis, setKpis] = useState<KpiData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let isMounted = true;
    const loadData = async () => {
      try {
        const data = await fetchKpis();
        if (isMounted) {
          setKpis(data);
          setLoading(false);
        }
      } catch (err) {
        console.error('Failed to load KPIs:', err);
      }
    };
    loadData();
    const interval = setInterval(loadData, 5000); // 5s live polling synchronization
    return () => {
      isMounted = false;
      clearInterval(interval);
    };
  }, []);

  if (loading || !kpis) {
    return (
      <div className="p-8 flex items-center justify-center min-h-[400px]">
        <div className="flex flex-col items-center space-y-3">
          <div className="w-8 h-8 border-3 border-blue-900 border-t-transparent rounded-full animate-spin"></div>
          <p className="text-sm font-medium text-slate-500">Connecting to Civic Telemetry Server...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6 max-w-[1600px] mx-auto">
      {/* 6 Hero KPI Grid */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        <KpiStatCard
          label="ACTIVE JOBS"
          value={kpis.active_jobs}
          subtext="In-flight dispatches"
          icon={Zap}
          variant="amber"
          pulse={true}
        />
        <KpiStatCard
          label="ONLINE WORKERS"
          value={kpis.online_workers}
          subtext="Active GPS beacons"
          icon={Users}
          variant="emerald"
        />
        <KpiStatCard
          label="VERIFIED WORKFORCE"
          value={kpis.verified_workforce}
          subtext="e-Shram / DigiLocker"
          icon={ShieldCheck}
          variant="blue"
        />
        <KpiStatCard
          label="TODAY'S GMV"
          value={`₹${kpis.today_gmv.toLocaleString('en-IN')}`}
          subtext="Paid orders (₹25 fee)"
          icon={IndianRupee}
          variant="emerald"
        />
        <KpiStatCard
          label="COMPLETED TODAY"
          value={kpis.completed_today}
          subtext="Citizen tasks fulfilled"
          icon={CheckCircle2}
          variant="blue"
        />
        <KpiStatCard
          label="OPEN DISPUTES"
          value={kpis.open_disputes}
          subtext="Under arbitration"
          icon={AlertTriangle}
          variant="crimson"
        />
      </div>

      {/* Main Split Grid (60% Dispatch Stream & Table / 40% Capacity & Price Monitor) */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Left 60% Column */}
        <div className="lg:col-span-7 space-y-6">
          {/* Live Dispatch Stream Card */}
          <div className="bg-white rounded-xl border border-slate-200 shadow-xs overflow-hidden">
            <div className="px-5 py-4 border-b border-slate-100 flex items-center justify-between">
              <div className="flex items-center space-x-2">
                <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse"></span>
                <h3 className="font-bold text-slate-900 text-sm tracking-tight">
                  Live Dispatch Activity Stream
                </h3>
              </div>
              <button 
                onClick={() => onNavigateTab('fleet')}
                className="text-xs font-semibold text-blue-700 hover:text-blue-900 flex items-center gap-1 cursor-pointer"
              >
                Open Spatial Fleet Map <ArrowRight className="w-3 h-3" />
              </button>
            </div>

            <div className="divide-y divide-slate-100 max-h-[260px] overflow-y-auto">
              <div className="p-3.5 flex items-start justify-between hover:bg-slate-50 transition text-xs">
                <div className="flex items-start space-x-3">
                  <div className="w-7 h-7 rounded-full bg-emerald-100 text-emerald-800 flex items-center justify-center font-bold text-xs shrink-0 mt-0.5">
                    ⚡
                  </div>
                  <div>
                    <p className="font-semibold text-slate-900">
                      Rajesh Kumar (Senior Electrician) accepted Order #0891
                    </p>
                    <p className="text-slate-500 mt-0.5">
                      Customer: Senthil Nathan · Flat 4B, Shanti Nilayam, T. Nagar
                    </p>
                  </div>
                </div>
                <span className="font-mono text-[11px] text-slate-400 font-medium shrink-0">
                  Just now
                </span>
              </div>

              <div className="p-3.5 flex items-start justify-between hover:bg-slate-50 transition text-xs">
                <div className="flex items-start space-x-3">
                  <div className="w-7 h-7 rounded-full bg-blue-100 text-blue-800 flex items-center justify-center font-bold text-xs shrink-0 mt-0.5">
                    🚰
                  </div>
                  <div>
                    <p className="font-semibold text-slate-900">
                      Manikandan P. (Plumber) completed Order #0890
                    </p>
                    <p className="text-slate-500 mt-0.5">
                      Customer: Priya R. · ₹320.00 settled (Worker Payout: ₹295.00)
                    </p>
                  </div>
                </div>
                <span className="font-mono text-[11px] text-slate-400 font-medium shrink-0">
                  12 mins ago
                </span>
              </div>

              <div className="p-3.5 flex items-start justify-between hover:bg-slate-50 transition text-xs">
                <div className="flex items-start space-x-3">
                  <div className="w-7 h-7 rounded-full bg-amber-100 text-amber-800 flex items-center justify-center font-bold text-xs shrink-0 mt-0.5">
                    🪚
                  </div>
                  <div>
                    <p className="font-semibold text-slate-900">
                      Karthik V. (Carpenter) enroute to Order #0889
                    </p>
                    <p className="text-slate-500 mt-0.5">
                      Customer: Venkatesh S. · Usman Road North
                    </p>
                  </div>
                </div>
                <span className="font-mono text-[11px] text-slate-400 font-medium shrink-0">
                  28 mins ago
                </span>
              </div>
            </div>
          </div>

          {/* Recent Orders Audit Table */}
          <div className="bg-white rounded-xl border border-slate-200 shadow-xs overflow-hidden">
            <div className="px-5 py-3.5 border-b border-slate-100 flex items-center justify-between">
              <h3 className="font-bold text-slate-900 text-sm tracking-tight">
                Recent Orders Audit
              </h3>
              <button
                onClick={() => onNavigateTab('orders')}
                className="text-xs font-semibold text-blue-700 hover:text-blue-900 flex items-center gap-1 cursor-pointer"
              >
                View Full Registry <ArrowRight className="w-3 h-3" />
              </button>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 border-b border-slate-200 text-slate-500 font-mono uppercase tracking-wider text-[10px]">
                  <tr>
                    <th className="py-2.5 px-4">Order ID</th>
                    <th className="py-2.5 px-4">Trade</th>
                    <th className="py-2.5 px-4">Customer</th>
                    <th className="py-2.5 px-4">Amount</th>
                    <th className="py-2.5 px-4">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 font-medium">
                  <tr className="hover:bg-amber-50/50 bg-amber-50/20">
                    <td className="py-2.5 px-4 font-mono font-semibold text-slate-900">#ORD-0891</td>
                    <td className="py-2.5 px-4">Electrician</td>
                    <td className="py-2.5 px-4 text-slate-600">Senthil Nathan</td>
                    <td className="py-2.5 px-4 font-tabular font-bold text-slate-900">₹275.00</td>
                    <td className="py-2.5 px-4">
                      <span className="bg-amber-100 text-amber-800 px-2 py-0.5 rounded-full text-[10px] font-bold border border-amber-300">
                        DISPUTED
                      </span>
                    </td>
                  </tr>
                  <tr className="hover:bg-slate-50">
                    <td className="py-2.5 px-4 font-mono font-semibold text-slate-900">#ORD-0890</td>
                    <td className="py-2.5 px-4">Plumber</td>
                    <td className="py-2.5 px-4 text-slate-600">Priya R.</td>
                    <td className="py-2.5 px-4 font-tabular font-bold text-slate-900">₹320.00</td>
                    <td className="py-2.5 px-4">
                      <span className="bg-emerald-100 text-emerald-800 px-2 py-0.5 rounded-full text-[10px] font-bold border border-emerald-300">
                        PAID
                      </span>
                    </td>
                  </tr>
                  <tr className="hover:bg-slate-50">
                    <td className="py-2.5 px-4 font-mono font-semibold text-slate-900">#ORD-0889</td>
                    <td className="py-2.5 px-4">Carpenter</td>
                    <td className="py-2.5 px-4 text-slate-600">Venkatesh S.</td>
                    <td className="py-2.5 px-4 font-tabular font-bold text-slate-900">₹400.00</td>
                    <td className="py-2.5 px-4">
                      <span className="bg-emerald-100 text-emerald-800 px-2 py-0.5 rounded-full text-[10px] font-bold border border-emerald-300">
                        PAID
                      </span>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>

        {/* Right 40% Column */}
        <div className="lg:col-span-5 space-y-6">
          {/* Zone Capacity Breakdown */}
          <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs">
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-bold text-slate-900 text-sm tracking-tight flex items-center gap-1.5">
                <MapPin className="w-4 h-4 text-slate-600" />
                Zone Capacity Breakdown
              </h3>
              <span className="text-xs text-slate-400 font-mono">Chennai Metro</span>
            </div>

            <div className="space-y-4">
              {Object.entries(kpis.zone_breakdown).map(([zone, data]) => (
                <div key={zone} className="space-y-1.5">
                  <div className="flex items-center justify-between text-xs">
                    <span className="font-semibold text-slate-800">{zone}</span>
                    <div className="flex items-center space-x-2">
                      <span className="text-slate-500 text-[11px] font-mono">{data.active_jobs} active</span>
                      <span className="font-bold font-tabular text-slate-900">{data.capacity_pct}%</span>
                    </div>
                  </div>
                  <div className="w-full bg-slate-100 h-2 rounded-full overflow-hidden">
                    <div 
                      className={`h-full rounded-full ${
                        data.capacity_pct >= 80 
                          ? 'bg-amber-500' 
                          : data.capacity_pct >= 65 
                          ? 'bg-blue-600' 
                          : 'bg-emerald-500'
                      }`}
                      style={{ width: `${data.capacity_pct}%` }}
                    ></div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Civic Price Ceiling Monitor */}
          <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs">
            <div className="flex items-center justify-between mb-3">
              <h3 className="font-bold text-slate-900 text-sm tracking-tight flex items-center gap-1.5">
                <TrendingUp className="w-4 h-4 text-emerald-600" />
                Platform Price Governance Monitor
              </h3>
              <button 
                onClick={() => onNavigateTab('price')}
                className="text-[11px] font-semibold text-blue-700 hover:text-blue-900 cursor-pointer"
              >
                Inspect Caps
              </button>
            </div>
            
            <p className="text-xs text-slate-500 mb-3">
              Configured municipal price ceilings strictly prevent algorithmic surge pricing.
            </p>

            <div className="space-y-2.5 font-mono text-xs">
              <div className="flex items-center justify-between p-2.5 rounded-lg bg-slate-50 border border-slate-200">
                <span className="text-slate-700 font-sans font-medium">Electrician Diagnostic</span>
                <div className="text-right">
                  <span className="font-bold text-slate-900 font-tabular">₹275</span>
                  <span className="text-slate-400 text-[10px] block">Cap: ₹350</span>
                </div>
              </div>
              <div className="flex items-center justify-between p-2.5 rounded-lg bg-slate-50 border border-slate-200">
                <span className="text-slate-700 font-sans font-medium">Plumber Diagnostic</span>
                <div className="text-right">
                  <span className="font-bold text-slate-900 font-tabular">₹320</span>
                  <span className="text-slate-400 text-[10px] block">Cap: ₹380</span>
                </div>
              </div>
              <div className="flex items-center justify-between p-2.5 rounded-lg bg-emerald-50 border border-emerald-200 text-emerald-900">
                <span className="font-sans font-medium">Civic Commission Cap</span>
                <span className="font-bold font-tabular">Fixed ₹25.00</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
