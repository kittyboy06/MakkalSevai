import React from 'react';
import { 
  LayoutDashboard, 
  MapPin, 
  ShieldCheck, 
  FileText, 
  TrendingUp, 
  Activity, 
  Radio, 
  UserCheck 
} from 'lucide-react';

interface CivicSidebarProps {
  currentTab: string;
  onSelectTab: (tab: string) => void;
  pendingKycCount?: number;
  openDisputesCount?: number;
}

export const CivicSidebar: React.FC<CivicSidebarProps> = ({
  currentTab,
  onSelectTab,
  pendingKycCount = 1,
  openDisputesCount = 1
}) => {
  const navItems = [
    { id: 'command', label: 'Command Center', icon: LayoutDashboard, badge: null },
    { id: 'fleet', label: 'Spatial Fleet Map', icon: MapPin, badge: null },
    { id: 'kyc', label: 'Worker Verification', icon: ShieldCheck, badge: pendingKycCount > 0 ? `${pendingKycCount}` : null, badgeColor: 'bg-amber-500' },
    { id: 'orders', label: 'Orders & Disputes', icon: FileText, badge: openDisputesCount > 0 ? `${openDisputesCount}` : null, badgeColor: 'bg-amber-500' },
    { id: 'price', label: 'Price & Demand Heatmap', icon: TrendingUp, badge: null }
  ];

  return (
    <aside className="w-64 bg-slate-900 text-slate-100 flex flex-col shrink-0 h-screen border-r border-slate-800 sticky top-0 z-30 select-none">
      {/* State Authority Header */}
      <div className="p-5 border-b border-slate-800/80 bg-slate-950/40">
        <div className="flex items-center space-x-3">
          <div className="w-10 h-10 rounded-lg bg-emerald-700/20 border border-emerald-500/30 flex items-center justify-center text-emerald-400 font-bold text-xl">
            🏛️
          </div>
          <div>
            <h1 className="font-bold text-base tracking-tight text-white flex items-center gap-1.5">
              MakkalSevai
              <span className="text-[10px] font-semibold bg-emerald-950 text-emerald-300 px-1.5 py-0.5 rounded border border-emerald-800">
                CIVIC
              </span>
            </h1>
            <p className="text-xs text-slate-400 font-medium">Chennai Smart City Portal</p>
          </div>
        </div>
        <div className="mt-3 flex items-center justify-between text-[11px] text-slate-400 font-mono bg-slate-800/50 px-2.5 py-1.5 rounded-md border border-slate-700/50">
          <span>ZONE 10 · T. NAGAR</span>
          <span className="text-emerald-400 flex items-center gap-1">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse"></span>
            ACTIVE
          </span>
        </div>
      </div>

      {/* Navigation List */}
      <nav className="flex-1 px-3 py-4 space-y-1.5 overflow-y-auto">
        <div className="px-3 pb-2 text-[10px] font-bold tracking-wider text-slate-400 uppercase">
          Operations & Governance
        </div>
        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = currentTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => onSelectTab(item.id)}
              className={`w-full flex items-center justify-between px-3.5 py-2.5 rounded-lg text-sm font-medium transition-all ${
                isActive
                  ? 'bg-blue-900/40 text-white border border-blue-600/50 shadow-sm'
                  : 'text-slate-300 hover:bg-slate-800/60 hover:text-white'
              }`}
            >
              <div className="flex items-center space-x-3">
                <Icon className={`w-4 h-4 ${isActive ? 'text-blue-400' : 'text-slate-400'}`} />
                <span>{item.label}</span>
              </div>
              {item.badge && (
                <span className={`text-[11px] font-bold px-2 py-0.5 rounded-full text-white ${item.badgeColor || 'bg-slate-700'}`}>
                  {item.badge}
                </span>
              )}
            </button>
          );
        })}
      </nav>

      {/* Realtime Telemetry & Officer Profile */}
      <div className="p-4 border-t border-slate-800 bg-slate-950/60 text-xs">
        <div className="space-y-2 mb-3 font-mono text-[11px] text-slate-400">
          <div className="flex items-center justify-between">
            <span className="flex items-center gap-1.5">
              <Activity className="w-3.5 h-3.5 text-emerald-400" />
              API Latency:
            </span>
            <span className="text-emerald-400 font-semibold font-tabular">22ms</span>
          </div>
          <div className="flex items-center justify-between">
            <span className="flex items-center gap-1.5">
              <Radio className="w-3.5 h-3.5 text-blue-400" />
              Supabase Realtime:
            </span>
            <span className="text-blue-400 font-semibold">Connected</span>
          </div>
        </div>

        <div className="pt-3 border-t border-slate-800 flex items-center space-x-3">
          <div className="w-8 h-8 rounded-full bg-slate-800 border border-slate-700 flex items-center justify-center text-slate-300 font-semibold text-xs">
            <UserCheck className="w-4 h-4 text-emerald-400" />
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-xs font-semibold text-white truncate">Insp. S. Meenakshi</p>
            <p className="text-[10px] text-slate-400 font-mono truncate">ID: TN-GCC-ZO-104</p>
          </div>
        </div>
      </div>
    </aside>
  );
};
