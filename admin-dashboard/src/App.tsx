import React, { useState, useEffect } from 'react';
import { CivicSidebar } from './components/CivicSidebar';
import { TopHeader } from './components/TopHeader';
import { CommandCenter } from './pages/CommandCenter';
import { SpatialFleetMap } from './pages/SpatialFleetMap';
import { WorkerKycQueue } from './pages/WorkerKycQueue';
import { OrdersAndDisputes } from './pages/OrdersAndDisputes';
import { PriceAndDemand } from './pages/PriceAndDemand';
import { getAuthToken, adminLogin, fetchKpis, fetchKycQueue, fetchDisputes } from './api/adminApi';
import { Shield, Lock } from 'lucide-react';

export const App: React.FC = () => {
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(true); // Demo mode starts authenticated
  const [currentTab, setCurrentTab] = useState<string>('command');
  const [pendingKycCount, setPendingKycCount] = useState<number>(1);
  const [openDisputesCount, setOpenDisputesCount] = useState<number>(1);
  const [isRefreshing, setIsRefreshing] = useState<boolean>(false);

  // Login credentials state if modal active
  const [loginUsername, setLoginUsername] = useState('inspector.meenakshi');
  const [loginPassword, setLoginPassword] = useState('makkalsevai2026');

  // Load badge counts
  const loadBadges = async () => {
    try {
      const kyc = await fetchKycQueue();
      setPendingKycCount(kyc.pending_count);
      const disp = await fetchDisputes();
      setOpenDisputesCount(disp.disputes.length);
    } catch {
      // Keep seeded demo counts
    }
  };

  useEffect(() => {
    loadBadges();
    const interval = setInterval(loadBadges, 8000);
    return () => clearInterval(interval);
  }, []);

  const handleRefresh = async () => {
    setIsRefreshing(true);
    await loadBadges();
    setTimeout(() => setIsRefreshing(false), 600);
  };

  const handleLoginSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await adminLogin(loginUsername, loginPassword);
    setIsAuthenticated(true);
  };

  if (!isAuthenticated) {
    return (
      <div className="min-h-screen bg-slate-900 flex items-center justify-center p-4">
        <div className="w-full max-w-md bg-white rounded-2xl p-8 shadow-2xl space-y-6">
          <div className="text-center space-y-2">
            <div className="w-14 h-14 bg-blue-900/10 text-blue-900 rounded-xl mx-auto flex items-center justify-center text-3xl">
              🏛️
            </div>
            <h1 className="text-xl font-bold text-slate-900 tracking-tight">
              MakkalSevai Civic Portal
            </h1>
            <p className="text-xs text-slate-500 font-medium">
              Government of Tamil Nadu · Municipal Operations Access
            </p>
          </div>

          <form onSubmit={handleLoginSubmit} className="space-y-4 text-xs">
            <div>
              <label className="font-bold text-slate-700 block mb-1 font-mono uppercase text-[10px]">
                Officer Identifier / Email
              </label>
              <input
                type="text"
                value={loginUsername}
                onChange={(e) => setLoginUsername(e.target.value)}
                className="w-full p-2.5 rounded-lg border border-slate-300 text-slate-900 focus:outline-none focus:border-blue-800"
                required
              />
            </div>
            <div>
              <label className="font-bold text-slate-700 block mb-1 font-mono uppercase text-[10px]">
                Passcode
              </label>
              <input
                type="password"
                value={loginPassword}
                onChange={(e) => setLoginPassword(e.target.value)}
                className="w-full p-2.5 rounded-lg border border-slate-300 text-slate-900 focus:outline-none focus:border-blue-800"
                required
              />
            </div>
            <button
              type="submit"
              className="w-full py-2.5 rounded-lg bg-blue-900 hover:bg-blue-950 text-white font-bold transition shadow-xs cursor-pointer text-xs"
            >
              Sign In to Command Center
            </button>
          </form>

          <div className="p-3 bg-slate-50 rounded-lg border border-slate-200 text-[11px] text-slate-500 text-center font-mono">
            Demo Zonal Credentials: inspector.meenakshi / makkalsevai2026
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-screen w-screen overflow-hidden bg-slate-50 font-sans">
      {/* Persistent Civic Command Sidebar (256px) */}
      <CivicSidebar
        currentTab={currentTab}
        onSelectTab={setCurrentTab}
        pendingKycCount={pendingKycCount}
        openDisputesCount={openDisputesCount}
      />

      {/* Main Content Viewport */}
      <div className="flex-1 flex flex-col h-screen overflow-hidden">
        <TopHeader
          currentTab={currentTab}
          onRefresh={handleRefresh}
          isRefreshing={isRefreshing}
        />

        <main className="flex-1 overflow-y-auto">
          {currentTab === 'command' && <CommandCenter onNavigateTab={setCurrentTab} />}
          {currentTab === 'fleet' && <SpatialFleetMap onNavigateTab={setCurrentTab} />}
          {currentTab === 'kyc' && <WorkerKycQueue />}
          {currentTab === 'orders' && <OrdersAndDisputes />}
          {currentTab === 'price' && <PriceAndDemand />}
        </main>
      </div>
    </div>
  );
};

export default App;
