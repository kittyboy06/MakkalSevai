import React, { useState, useEffect } from 'react';
import { ShieldAlert, Clock, Bell, RefreshCw } from 'lucide-react';

interface TopHeaderProps {
  currentTab: string;
  onRefresh?: () => void;
  isRefreshing?: boolean;
}

export const TopHeader: React.FC<TopHeaderProps> = ({ currentTab, onRefresh, isRefreshing = false }) => {
  const [timeStr, setTimeStr] = useState<string>('');

  useEffect(() => {
    const update = () => {
      const now = new Date();
      setTimeStr(now.toLocaleDateString('en-IN', {
        weekday: 'short',
        day: '2-digit',
        month: 'short',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
      }));
    };
    update();
    const interval = setInterval(update, 1000);
    return () => clearInterval(interval);
  }, []);

  const getBreadcrumbs = () => {
    switch (currentTab) {
      case 'fleet':
        return 'Operations > Spatial Fleet Map & Realtime GPS Telemetry';
      case 'kyc':
        return 'Workforce Governance > Worker Credential Verification Queue';
      case 'orders':
        return 'Marketplace Operations > Order Registry & Judicial Arbitration';
      case 'price':
        return 'Economic Governance > Civic Price Ceilings & Demand Intelligence';
      case 'command':
      default:
        return 'Chennai Central Zone > T. Nagar Operations Command Center';
    }
  };

  return (
    <header className="bg-white border-b border-slate-200 sticky top-0 z-20 shadow-xs">
      {/* Emergency & Municipal Statutory Banner */}
      <div className="bg-amber-500/10 border-b border-amber-500/20 px-6 py-1.5 flex items-center justify-between text-xs text-amber-900 font-medium">
        <div className="flex items-center space-x-2">
          <ShieldAlert className="w-3.5 h-3.5 text-amber-600 shrink-0" />
          <span>
            <strong>CIVIC FAIR FARE MANDATE:</strong> All electrician and plumbing rates strictly locked to municipal ceiling caps. Platform commission capped at fixed ₹25.00.
          </span>
        </div>
        <span className="hidden md:inline font-mono text-[10px] text-amber-700 font-semibold uppercase tracking-wider">
          Smart City Act · Rule 14-B
        </span>
      </div>

      {/* Main Top Header Controls */}
      <div className="px-6 py-3.5 flex items-center justify-between">
        <div>
          <p className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider font-mono">
            {getBreadcrumbs()}
          </p>
          <h2 className="text-lg font-bold text-slate-900 tracking-tight flex items-center gap-2">
            MakkalSevai Civic Authority Portal
            <span className="text-xs font-normal text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-200 flex items-center gap-1">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
              LIVE DISPATCH ACTIVE
            </span>
          </h2>
        </div>

        <div className="flex items-center space-x-4 text-xs">
          {/* Live Clock */}
          <div className="hidden sm:flex items-center space-x-1.5 text-slate-600 bg-slate-100 px-3 py-1.5 rounded-md font-mono border border-slate-200">
            <Clock className="w-3.5 h-3.5 text-slate-500" />
            <span className="font-tabular">{timeStr}</span>
          </div>

          {/* Refresh Action */}
          {onRefresh && (
            <button
              onClick={onRefresh}
              disabled={isRefreshing}
              className="flex items-center space-x-1 px-2.5 py-1.5 rounded-md border border-slate-200 bg-white hover:bg-slate-50 text-slate-700 font-medium transition cursor-pointer"
              title="Refresh Data"
            >
              <RefreshCw className={`w-3.5 h-3.5 text-slate-600 ${isRefreshing ? 'animate-spin' : ''}`} />
              <span className="hidden sm:inline">Refresh</span>
            </button>
          )}

          {/* Alerts Bell */}
          <div className="relative p-1.5 rounded-md text-slate-600 hover:bg-slate-100 cursor-pointer">
            <Bell className="w-4 h-4" />
            <span className="absolute top-1 right-1 w-2 h-2 bg-amber-500 rounded-full ring-2 ring-white"></span>
          </div>
        </div>
      </div>
    </header>
  );
};
