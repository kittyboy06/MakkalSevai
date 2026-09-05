import React from 'react';
import { LucideIcon } from 'lucide-react';

interface KpiStatCardProps {
  label: string;
  value: string | number;
  subtext: string;
  icon: LucideIcon;
  variant?: 'emerald' | 'amber' | 'blue' | 'crimson' | 'slate';
  pulse?: boolean;
}

export const KpiStatCard: React.FC<KpiStatCardProps> = ({
  label,
  value,
  subtext,
  icon: Icon,
  variant = 'blue',
  pulse = false
}) => {
  const getColors = () => {
    switch (variant) {
      case 'emerald':
        return {
          bg: 'bg-emerald-50/50',
          border: 'border-emerald-200/80',
          iconBg: 'bg-emerald-100 text-emerald-700',
          valueColor: 'text-emerald-950',
          pulseColor: 'bg-emerald-500'
        };
      case 'amber':
        return {
          bg: 'bg-amber-50/50',
          border: 'border-amber-200/80',
          iconBg: 'bg-amber-100 text-amber-700',
          valueColor: 'text-amber-950',
          pulseColor: 'bg-amber-500'
        };
      case 'crimson':
        return {
          bg: 'bg-red-50/50',
          border: 'border-red-200/80',
          iconBg: 'bg-red-100 text-red-700',
          valueColor: 'text-red-950',
          pulseColor: 'bg-red-500'
        };
      case 'slate':
        return {
          bg: 'bg-slate-50',
          border: 'border-slate-200',
          iconBg: 'bg-slate-100 text-slate-700',
          valueColor: 'text-slate-900',
          pulseColor: 'bg-slate-500'
        };
      case 'blue':
      default:
        return {
          bg: 'bg-blue-50/30',
          border: 'border-blue-200/80',
          iconBg: 'bg-blue-100 text-blue-700',
          valueColor: 'text-blue-950',
          pulseColor: 'bg-blue-500'
        };
    }
  };

  const colors = getColors();

  return (
    <div className={`p-4 rounded-xl border ${colors.border} bg-white shadow-xs hover:shadow-sm transition`}>
      <div className="flex items-center justify-between mb-2">
        <span className="text-[11px] font-bold text-slate-400 uppercase tracking-wider font-mono">
          {label}
        </span>
        <div className={`w-7 h-7 rounded-lg ${colors.iconBg} flex items-center justify-center`}>
          <Icon className="w-4 h-4" />
        </div>
      </div>

      <div className="flex items-baseline space-x-2">
        <span className={`text-2xl font-bold tracking-tight font-tabular ${colors.valueColor}`}>
          {value}
        </span>
        {pulse && (
          <span className="flex h-2 w-2 relative">
            <span className={`animate-ping absolute inline-flex h-full w-full rounded-full ${colors.pulseColor} opacity-75`}></span>
            <span className={`relative inline-flex rounded-full h-2 w-2 ${colors.pulseColor}`}></span>
          </span>
        )}
      </div>

      <p className="mt-1.5 text-xs text-slate-600 font-medium truncate">
        {subtext}
      </p>
    </div>
  );
};
