import React, { useEffect, useState } from 'react';
import { 
  FileText, 
  AlertTriangle, 
  CheckCircle, 
  Clock, 
  X, 
  Scale, 
  IndianRupee, 
  Image as ImageIcon,
  User,
  ShieldCheck
} from 'lucide-react';
import { OrderItem, DisputeItem } from '../types/adminTypes';
import { fetchAdminOrders, fetchDisputes, resolveDispute } from '../api/adminApi';

export const OrdersAndDisputes: React.FC = () => {
  const [orders, setOrders] = useState<OrderItem[]>([]);
  const [disputes, setDisputes] = useState<DisputeItem[]>([]);
  const [selectedDispute, setSelectedDispute] = useState<DisputeItem | null>(null);
  const [activeTab, setActiveTab] = useState<'all' | 'in_flight' | 'completed' | 'disputed'>('disputed');
  const [resolutionStatus, setResolutionStatus] = useState<string | null>(null);
  const [isResolving, setIsResolving] = useState<boolean>(false);

  useEffect(() => {
    fetchAdminOrders().then(res => setOrders(res.orders));
    fetchDisputes().then(res => {
      setDisputes(res.disputes);
      if (res.disputes.length > 0) {
        setSelectedDispute(res.disputes[0]);
      }
    });
  }, []);

  const handleResolve = async (resolution: 'release_payout' | 'refund_customer' | 'split') => {
    if (!selectedDispute) return;
    setIsResolving(true);
    try {
      const res = await resolveDispute(selectedDispute.order_id, resolution);
      setResolutionStatus(res.test_mode_action);
    } catch (err) {
      console.error(err);
    } finally {
      setIsResolving(false);
    }
  };

  const filteredOrders = orders.filter((ord) => {
    if (activeTab === 'disputed') return ord.status === 'disputed';
    if (activeTab === 'completed') return ord.status === 'completed';
    if (activeTab === 'in_flight') return ['accepted', 'worker_enroute', 'in_progress'].includes(ord.status);
    return true;
  });

  return (
    <div className="p-6 space-y-6 max-w-[1600px] mx-auto">
      {/* Top Banner */}
      <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-xs flex items-center justify-between">
        <div>
          <h2 className="text-base font-bold text-slate-900 tracking-tight flex items-center gap-2">
            <Scale className="w-5 h-5 text-blue-900" />
            Order Registry & Judicial Arbitration Console
          </h2>
          <p className="text-xs text-slate-500">
            Audit complete order lifecycles and resolve citizen/worker disputes in Razorpay Sandbox mode.
          </p>
        </div>
        <div className="text-right text-xs font-mono">
          <span className="text-slate-400 block text-[10px] uppercase">Gateway Status:</span>
          <span className="font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200">
            Razorpay Test Sandbox Active
          </span>
        </div>
      </div>

      {/* Status Tabs */}
      <div className="flex space-x-2 border-b border-slate-200 pb-2 text-xs font-semibold">
        <button
          onClick={() => setActiveTab('disputed')}
          className={`px-3 py-1.5 rounded-lg transition cursor-pointer flex items-center gap-1.5 ${
            activeTab === 'disputed'
              ? 'bg-amber-600 text-white shadow-xs'
              : 'bg-white hover:bg-slate-100 text-slate-700 border border-slate-200'
          }`}
        >
          <AlertTriangle className="w-3.5 h-3.5" />
          ⚠️ Open Disputes ({disputes.length})
        </button>
        <button
          onClick={() => setActiveTab('all')}
          className={`px-3 py-1.5 rounded-lg transition cursor-pointer ${
            activeTab === 'all'
              ? 'bg-slate-900 text-white'
              : 'bg-white hover:bg-slate-100 text-slate-700 border border-slate-200'
          }`}
        >
          All Orders (142)
        </button>
        <button
          onClick={() => setActiveTab('in_flight')}
          className={`px-3 py-1.5 rounded-lg transition cursor-pointer ${
            activeTab === 'in_flight'
              ? 'bg-slate-900 text-white'
              : 'bg-white hover:bg-slate-100 text-slate-700 border border-slate-200'
          }`}
        >
          In-Flight (14)
        </button>
        <button
          onClick={() => setActiveTab('completed')}
          className={`px-3 py-1.5 rounded-lg transition cursor-pointer ${
            activeTab === 'completed'
              ? 'bg-slate-900 text-white'
              : 'bg-white hover:bg-slate-100 text-slate-700 border border-slate-200'
          }`}
        >
          Completed (127)
        </button>
      </div>

      {/* Main Workspace (60% Master Orders Table / 40% Arbitration Drawer) */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Left 60%: Master Orders Table */}
        <div className="lg:col-span-7 bg-white rounded-xl border border-slate-200 shadow-xs overflow-hidden">
          <div className="px-5 py-3.5 border-b border-slate-100 flex items-center justify-between">
            <h3 className="font-bold text-slate-900 text-sm tracking-tight">
              Order Lifecycle Registry
            </h3>
            <span className="text-[11px] font-mono text-slate-400">Showing {filteredOrders.length} records</span>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-50 border-b border-slate-200 text-slate-500 font-mono uppercase tracking-wider text-[10px]">
                <tr>
                  <th className="py-2.5 px-4">Order ID</th>
                  <th className="py-2.5 px-4">Trade</th>
                  <th className="py-2.5 px-4">Customer</th>
                  <th className="py-2.5 px-4">Worker</th>
                  <th className="py-2.5 px-4">Amount</th>
                  <th className="py-2.5 px-4">Status</th>
                  <th className="py-2.5 px-4 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 font-medium">
                {filteredOrders.map((ord) => {
                  const isDisputed = ord.status === 'disputed';
                  return (
                    <tr 
                      key={ord.id} 
                      className={`hover:bg-slate-50 transition ${isDisputed ? 'bg-amber-50/40 border-l-3 border-amber-500' : ''}`}
                    >
                      <td className="py-3 px-4 font-mono font-bold text-slate-900">{ord.order_number}</td>
                      <td className="py-3 px-4 text-slate-800">{ord.trade || 'Electrician'}</td>
                      <td className="py-3 px-4 text-slate-600">{ord.customer_name || 'Senthil Nathan'}</td>
                      <td className="py-3 px-4 text-slate-600">{ord.worker_name || 'Rajesh Kumar'}</td>
                      <td className="py-3 px-4 font-tabular font-bold text-slate-900">₹{ord.final_amount.toFixed(2)}</td>
                      <td className="py-3 px-4">
                        <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                          isDisputed
                            ? 'bg-amber-100 text-amber-900 border border-amber-300'
                            : 'bg-emerald-100 text-emerald-900 border border-emerald-300'
                        }`}>
                          {ord.status}
                        </span>
                      </td>
                      <td className="py-3 px-4 text-right">
                        {isDisputed ? (
                          <button
                            onClick={() => setSelectedDispute(disputes[0] || null)}
                            className="text-[11px] font-bold text-amber-700 hover:text-amber-900 bg-amber-100 px-2 py-1 rounded cursor-pointer border border-amber-200"
                          >
                            Inspect Grievance
                          </button>
                        ) : (
                          <span className="text-slate-400 text-[11px] font-mono">Audited</span>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>

        {/* Right 40%: Dispute Arbitration Drawer */}
        <div className="lg:col-span-5 bg-white rounded-xl border border-slate-200 shadow-xs flex flex-col justify-between overflow-hidden">
          {selectedDispute ? (
            <div className="flex flex-col h-full justify-between">
              <div>
                <div className="px-5 py-4 border-b border-slate-200 bg-slate-900 text-white flex items-center justify-between">
                  <div>
                    <span className="text-[10px] font-mono text-amber-400 font-semibold tracking-wider uppercase block">
                      Dispute Arbitration Dossier
                    </span>
                    <h3 className="text-sm font-bold tracking-tight">
                      Order {selectedDispute.order_number}
                    </h3>
                  </div>
                  <span className="bg-amber-500/20 text-amber-300 text-[10px] font-mono font-bold px-2 py-0.5 rounded border border-amber-500/40">
                    UNDER REVIEW
                  </span>
                </div>

                <div className="p-5 space-y-4 text-xs">
                  {/* Parties & Financials */}
                  <div className="grid grid-cols-2 gap-3 bg-slate-50 p-3 rounded-lg border border-slate-200">
                    <div>
                      <span className="text-[10px] text-slate-400 uppercase font-mono block">Citizen:</span>
                      <p className="font-bold text-slate-900">{selectedDispute.citizen.name}</p>
                      <p className="text-[11px] text-slate-500">⭐ {selectedDispute.citizen.rating} · Resident</p>
                    </div>
                    <div>
                      <span className="text-[10px] text-slate-400 uppercase font-mono block">Worker:</span>
                      <p className="font-bold text-slate-900">{selectedDispute.worker.name}</p>
                      <p className="text-[11px] text-slate-500">⭐ {selectedDispute.worker.rating} · {selectedDispute.worker.jobs_completed} jobs</p>
                    </div>
                  </div>

                  {/* Financial Breakdown (A-D09 Transparent Payouts) */}
                  <div className="p-3 bg-blue-50/50 rounded-lg border border-blue-200/80 space-y-1 font-mono text-xs">
                    <div className="flex items-center justify-between">
                      <span className="text-slate-600">Gross Paid by Citizen:</span>
                      <span className="font-bold text-slate-900 font-tabular">₹{selectedDispute.financials.gross_paid.toFixed(2)}</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-slate-600">Civic Platform Fee (Fixed):</span>
                      <span className="font-bold text-slate-900 font-tabular">₹{selectedDispute.financials.platform_commission.toFixed(2)}</span>
                    </div>
                    <div className="flex items-center justify-between pt-1 border-t border-blue-200/60 font-semibold text-emerald-900">
                      <span>Worker Take-Home Share:</span>
                      <span className="font-tabular font-bold">₹{selectedDispute.financials.worker_take_home.toFixed(2)}</span>
                    </div>
                  </div>

                  {/* Grievance Statement */}
                  <div className="p-3 bg-red-50/60 rounded-lg border border-red-200 space-y-1">
                    <span className="text-[10px] font-bold uppercase font-mono text-red-700 block">
                      Citizen Grievance Claim:
                    </span>
                    <p className="text-slate-800 italic leading-relaxed">
                      "{selectedDispute.citizen.statement}"
                    </p>
                  </div>

                  {/* Worker Evidence & Completion Note */}
                  <div className="p-3 bg-emerald-50/60 rounded-lg border border-emerald-200 space-y-2">
                    <span className="text-[10px] font-bold uppercase font-mono text-emerald-800 block">
                      Worker Completion Technical Evidence:
                    </span>
                    <p className="text-slate-800 leading-relaxed">
                      "{selectedDispute.worker.statement}"
                    </p>
                    <div className="flex items-center space-x-2 text-[11px] text-emerald-800 font-medium">
                      <ImageIcon className="w-3.5 h-3.5" />
                      <span>Attached: replaced_mcb_panel_inspection.jpg (Tamper-evident timestamp)</span>
                    </div>
                  </div>

                  {/* Resolution Feedback Alert */}
                  {resolutionStatus && (
                    <div className="p-3 bg-slate-900 text-emerald-400 rounded-lg text-xs font-mono font-semibold">
                      {resolutionStatus}
                    </div>
                  )}
                </div>
              </div>

              {/* Arbitration Actions */}
              <div className="p-5 border-t border-slate-100 bg-slate-50 space-y-2.5">
                <p className="text-[10px] font-bold font-mono text-slate-400 uppercase">
                  Execute Judicial Arbitration (Razorpay Test Mode)
                </p>
                <div className="space-y-2">
                  <button
                    onClick={() => handleResolve('release_payout')}
                    disabled={isResolving}
                    className="w-full py-2.5 px-3 rounded-lg bg-emerald-700 hover:bg-emerald-800 text-white font-semibold text-xs transition cursor-pointer shadow-xs text-center block"
                  >
                    Release Worker Payout (Demo) - ₹250.00
                  </button>
                  <div className="grid grid-cols-2 gap-2">
                    <button
                      onClick={() => handleResolve('refund_customer')}
                      disabled={isResolving}
                      className="py-2 px-2.5 rounded-lg border border-red-300 hover:bg-red-50 text-red-700 font-semibold text-xs transition cursor-pointer text-center"
                    >
                      Simulate Refund (Test Mode) - ₹275
                    </button>
                    <button
                      onClick={() => handleResolve('split')}
                      disabled={isResolving}
                      className="py-2 px-2.5 rounded-lg border border-slate-300 hover:bg-slate-200 text-slate-700 font-semibold text-xs transition cursor-pointer text-center"
                    >
                      50/50 Compromise
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ) : (
            <div className="p-8 text-center text-slate-400 text-xs">
              Select an order to inspect details.
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
