import React, { useEffect, useState } from 'react';
import { 
  ShieldAlert, 
  CheckCircle2, 
  XCircle, 
  FileText, 
  Award, 
  Camera, 
  UserCheck, 
  AlertCircle,
  Clock
} from 'lucide-react';
import { KycItem } from '../types/adminTypes';
import { fetchKycQueue, reviewWorkerKyc } from '../api/adminApi';

export const WorkerKycQueue: React.FC = () => {
  const [queue, setQueue] = useState<KycItem[]>([]);
  const [activeDocTab, setActiveDocTab] = useState<'aadhaar' | 'eshram' | 'selfie'>('aadhaar');
  const [decisionFeedback, setDecisionFeedback] = useState<string | null>(null);
  const [isProcessing, setIsProcessing] = useState<boolean>(false);

  useEffect(() => {
    fetchKycQueue().then(res => setQueue(res.queue));
  }, []);

  const currentWorker = queue[0];

  const handleReview = async (action: 'approve' | 'reject') => {
    if (!currentWorker) return;
    setIsProcessing(true);
    try {
      const res = await reviewWorkerKyc(currentWorker.worker_id, action);
      setDecisionFeedback(
        action === 'approve'
          ? `✅ Approved! Rajesh Kumar has been issued a verified Digital Skill Passport.`
          : `❌ Application rejected. Worker notified with requested correction.`
      );
      // Update local state
      setQueue(prev => prev.map(w => w.worker_id === currentWorker.worker_id ? { ...w, kyc_status: action === 'approve' ? 'verified' : 'rejected' } : w));
    } catch (err) {
      console.error(err);
    } finally {
      setIsProcessing(false);
    }
  };

  if (!currentWorker) {
    return (
      <div className="p-8 text-center text-slate-500">
        <p>No pending verification audits in queue.</p>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6 max-w-[1600px] mx-auto">
      {/* Mandatory Sandbox Alert Banner */}
      <div className="p-3.5 bg-amber-50 border border-amber-300 rounded-xl text-xs text-amber-900 flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <ShieldAlert className="w-4 h-4 text-amber-600 shrink-0" />
          <span>
            <strong>⚠️ DEMO VERIFICATION (SIMULATED GOVERNMENT INTEGRATION):</strong> Sandbox environment. DigiLocker and e-Shram database queries run against local demo seeds.
          </span>
        </div>
        <span className="font-mono text-[10px] font-bold bg-amber-200/60 text-amber-800 px-2 py-0.5 rounded">
          SANDBOX ACTIVE
        </span>
      </div>

      {/* 3 Metric Cards Across Top */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-[10px] font-bold font-mono text-slate-400 uppercase">Pending Audits</p>
            <p className="text-2xl font-bold text-amber-900 font-tabular">1</p>
            <p className="text-xs text-slate-500">Rajesh Kumar (Senior Electrician)</p>
          </div>
          <div className="w-10 h-10 rounded-lg bg-amber-100 text-amber-700 flex items-center justify-center font-bold">
            ⏳
          </div>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-[10px] font-bold font-mono text-slate-400 uppercase">Verified Workforce</p>
            <p className="text-2xl font-bold text-emerald-900 font-tabular">189</p>
            <p className="text-xs text-slate-500">Tradespeople certified across Chennai</p>
          </div>
          <div className="w-10 h-10 rounded-lg bg-emerald-100 text-emerald-700 flex items-center justify-center font-bold">
            🛡️
          </div>
        </div>

        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-xs flex items-center justify-between">
          <div>
            <p className="text-[10px] font-bold font-mono text-slate-400 uppercase">Average Audit Duration</p>
            <p className="text-2xl font-bold text-blue-900 font-tabular">1.4 mins</p>
            <p className="text-xs text-slate-500">Rapid officer turnaround</p>
          </div>
          <div className="w-10 h-10 rounded-lg bg-blue-100 text-blue-700 flex items-center justify-center font-bold">
            <Clock className="w-5 h-5" />
          </div>
        </div>
      </div>

      {/* Main Split Inspector Workspace (50/50) */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Left Column (50%): Submitted Citizen Documents */}
        <div className="lg:col-span-6 bg-white rounded-xl border border-slate-200 p-5 shadow-xs flex flex-col justify-between">
          <div className="space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <div>
                <h3 className="font-bold text-slate-900 text-sm tracking-tight">
                  Submitted Citizen Documents
                </h3>
                <p className="text-xs text-slate-500">Original evidence files uploaded during onboarding</p>
              </div>
              <span className="text-[10px] font-mono bg-slate-100 text-slate-600 px-2 py-0.5 rounded font-semibold">
                APPLICANT: {currentWorker.full_name}
              </span>
            </div>

            {/* Document Tabs */}
            <div className="flex space-x-2 border-b border-slate-200 pb-2">
              <button
                onClick={() => setActiveDocTab('aadhaar')}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition cursor-pointer flex items-center gap-1.5 ${
                  activeDocTab === 'aadhaar'
                    ? 'bg-blue-900 text-white shadow-xs'
                    : 'bg-slate-100 hover:bg-slate-200 text-slate-700'
                }`}
              >
                <FileText className="w-3.5 h-3.5" />
                Aadhaar e-KYC
              </button>
              <button
                onClick={() => setActiveDocTab('eshram')}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition cursor-pointer flex items-center gap-1.5 ${
                  activeDocTab === 'eshram'
                    ? 'bg-blue-900 text-white shadow-xs'
                    : 'bg-slate-100 hover:bg-slate-200 text-slate-700'
                }`}
              >
                <Award className="w-3.5 h-3.5" />
                e-Shram Card
              </button>
              <button
                onClick={() => setActiveDocTab('selfie')}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition cursor-pointer flex items-center gap-1.5 ${
                  activeDocTab === 'selfie'
                    ? 'bg-blue-900 text-white shadow-xs'
                    : 'bg-slate-100 hover:bg-slate-200 text-slate-700'
                }`}
              >
                <Camera className="w-3.5 h-3.5" />
                Live Selfie
              </button>
            </div>

            {/* Document Preview Canvas */}
            <div className="bg-slate-50 border border-slate-200 rounded-xl p-5 min-h-[300px]">
              {activeDocTab === 'aadhaar' && (
                <div className="space-y-4">
                  <div className="flex items-center justify-between border-b border-slate-200 pb-3">
                    <div className="flex items-center space-x-2">
                      <span className="text-xl">🇮🇳</span>
                      <div>
                        <p className="font-bold text-slate-900 text-xs uppercase">Government of India · UIDAI</p>
                        <p className="text-[10px] text-slate-500">DigiLocker Verified e-Aadhaar Extract</p>
                      </div>
                    </div>
                    <span className="text-[10px] font-mono font-bold bg-emerald-100 text-emerald-800 px-2 py-0.5 rounded border border-emerald-300">
                      DIGILOCKER VERIFIED
                    </span>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4 pt-2">
                    <div className="w-28 h-32 bg-slate-200 rounded-lg border border-slate-300 flex flex-col items-center justify-center text-slate-500 text-xs">
                      <UserCheck className="w-10 h-10 text-slate-400 mb-1" />
                      <span>Photo: Rajesh</span>
                    </div>

                    <div className="md:col-span-2 space-y-2 text-xs">
                      <div>
                        <span className="text-[10px] text-slate-400 uppercase font-mono block">Full Name:</span>
                        <p className="font-bold text-slate-900 text-sm">{currentWorker.documents.aadhaar_name}</p>
                      </div>
                      <div className="grid grid-cols-2 gap-2">
                        <div>
                          <span className="text-[10px] text-slate-400 uppercase font-mono block">Date of Birth:</span>
                          <p className="font-semibold text-slate-800 font-mono">{currentWorker.documents.aadhaar_dob}</p>
                        </div>
                        <div>
                          <span className="text-[10px] text-slate-400 uppercase font-mono block">Gender:</span>
                          <p className="font-semibold text-slate-800">{currentWorker.documents.aadhaar_gender}</p>
                        </div>
                      </div>
                      <div>
                        <span className="text-[10px] text-slate-400 uppercase font-mono block">Registered Address:</span>
                        <p className="font-medium text-slate-700 leading-relaxed">{currentWorker.documents.aadhaar_address}</p>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {activeDocTab === 'eshram' && (
                <div className="space-y-4">
                  <div className="flex items-center justify-between border-b border-slate-200 pb-3">
                    <div>
                      <p className="font-bold text-slate-900 text-xs uppercase">Ministry of Labour & Employment</p>
                      <p className="text-[10px] text-slate-500">National Database of Unorganised Workers (e-Shram)</p>
                    </div>
                    <span className="text-[10px] font-mono font-bold bg-emerald-100 text-emerald-800 px-2 py-0.5 rounded border border-emerald-300">
                      UAN VERIFIED
                    </span>
                  </div>

                  <div className="p-4 bg-white rounded-lg border border-slate-200 space-y-3 text-xs">
                    <div className="flex items-center justify-between">
                      <span className="text-slate-500">Universal Account Number (UAN):</span>
                      <span className="font-bold text-blue-950 font-mono text-sm tracking-wider">{currentWorker.uan}</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-slate-500">Primary Skill Category:</span>
                      <span className="font-bold text-slate-900">Electrical Domestic Wiring</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-slate-500">Sub-Occupation:</span>
                      <span className="font-medium text-slate-800">Home Maintenance & Appliance Repair</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-slate-500">State Social Security Board:</span>
                      <span className="font-medium text-slate-800">Tamil Nadu Unorganised Workers Welfare Board</span>
                    </div>
                  </div>
                </div>
              )}

              {activeDocTab === 'selfie' && (
                <div className="space-y-3 text-center">
                  <div className="w-36 h-44 mx-auto bg-slate-800 rounded-xl border-2 border-emerald-500 flex flex-col items-center justify-center text-white relative overflow-hidden">
                    <UserCheck className="w-16 h-16 text-emerald-400" />
                    <span className="absolute bottom-2 text-[10px] bg-emerald-950/80 text-emerald-300 px-2 py-0.5 rounded font-mono">
                      Mesh: 68 points
                    </span>
                  </div>
                  <p className="text-xs font-semibold text-slate-900">
                    Live Onboarding Biometric Capture
                  </p>
                  <span className="inline-block bg-emerald-100 text-emerald-800 text-[11px] font-bold px-3 py-1 rounded-full border border-emerald-300">
                    Face Match: ✓ Demo Passed (Simulation)
                  </span>
                </div>
              )}
            </div>
          </div>

          <div className="pt-4 border-t border-slate-100 text-[11px] text-slate-400 font-mono">
            Audit Packet ID: TN-AUDIT-2026-0891 · Submitted {currentWorker.submitted_at}
          </div>
        </div>

        {/* Right Column (50%): Automated Institutional Verification Audit */}
        <div className="lg:col-span-6 bg-white rounded-xl border border-slate-200 p-5 shadow-xs flex flex-col justify-between">
          <div className="space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <div>
                <h3 className="font-bold text-slate-900 text-sm tracking-tight">
                  Automated Institutional Audit
                </h3>
                <p className="text-xs text-slate-500">Algorithmic cross-verification checks</p>
              </div>
              <span className={`text-[11px] font-bold px-2.5 py-0.5 rounded-full uppercase tracking-wider ${
                currentWorker.kyc_status === 'verified'
                  ? 'bg-emerald-100 text-emerald-900 border border-emerald-300'
                  : 'bg-amber-100 text-amber-900 border border-amber-300'
              }`}>
                {currentWorker.kyc_status === 'verified' ? 'APPROVED' : 'PENDING REVIEW'}
              </span>
            </div>

            {/* Checklist of 5 institutional checks */}
            <div className="space-y-2.5">
              <div className="p-3 rounded-lg bg-emerald-50/60 border border-emerald-200 flex items-start justify-between text-xs">
                <div className="flex items-start space-x-2.5">
                  <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                  <div>
                    <p className="font-bold text-slate-900">1. DigiLocker Identity Matching</p>
                    <p className="text-slate-600 mt-0.5">Name, DOB and address verified against UIDAI ledger.</p>
                  </div>
                </div>
                <span className="text-[10px] font-bold font-mono text-emerald-700 bg-emerald-100 px-2 py-0.5 rounded shrink-0">
                  MATCHED
                </span>
              </div>

              <div className="p-3 rounded-lg bg-emerald-50/60 border border-emerald-200 flex items-start justify-between text-xs">
                <div className="flex items-start space-x-2.5">
                  <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                  <div>
                    <p className="font-bold text-slate-900">2. Ministry of Labour e-Shram Registration</p>
                    <p className="text-slate-600 mt-0.5">Active UAN {currentWorker.uan} in unorganized worker registry.</p>
                  </div>
                </div>
                <span className="text-[10px] font-bold font-mono text-emerald-700 bg-emerald-100 px-2 py-0.5 rounded shrink-0">
                  ACTIVE
                </span>
              </div>

              <div className="p-3 rounded-lg bg-emerald-50/60 border border-emerald-200 flex items-start justify-between text-xs">
                <div className="flex items-start space-x-2.5">
                  <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                  <div>
                    <p className="font-bold text-slate-900">3. Biometric Facial Verification</p>
                    <p className="text-slate-600 mt-0.5">Live selfie verified against ID photo landmark vectors.</p>
                  </div>
                </div>
                <span className="text-[10px] font-bold font-mono text-emerald-700 bg-emerald-100 px-2 py-0.5 rounded shrink-0">
                  ✓ DEMO PASSED
                </span>
              </div>

              <div className="p-3 rounded-lg bg-blue-50/60 border border-blue-200 flex items-start justify-between text-xs">
                <div className="flex items-start space-x-2.5">
                  <CheckCircle2 className="w-4 h-4 text-blue-600 shrink-0 mt-0.5" />
                  <div>
                    <p className="font-bold text-slate-900">4. Vocational Trade Certification</p>
                    <p className="text-slate-600 mt-0.5">NSDC Level 4 Electrician - Chennai Metro Skill Council.</p>
                  </div>
                </div>
                <span className="text-[10px] font-bold font-mono text-blue-700 bg-blue-100 px-2 py-0.5 rounded shrink-0">
                  CERTIFIED
                </span>
              </div>

              <div className="p-3 rounded-lg bg-emerald-50/60 border border-emerald-200 flex items-start justify-between text-xs">
                <div className="flex items-start space-x-2.5">
                  <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                  <div>
                    <p className="font-bold text-slate-900">5. Civic Background & Dispute History</p>
                    <p className="text-slate-600 mt-0.5">Zero prior disciplinary violations across municipal zones.</p>
                  </div>
                </div>
                <span className="text-[10px] font-bold font-mono text-emerald-700 bg-emerald-100 px-2 py-0.5 rounded shrink-0">
                  CLEAN
                </span>
              </div>
            </div>

            {/* Decision Feedback message */}
            {decisionFeedback && (
              <div className="p-3 rounded-lg bg-slate-900 text-white text-xs font-semibold">
                {decisionFeedback}
              </div>
            )}
          </div>

          {/* Action CTAs */}
          <div className="pt-5 border-t border-slate-100 space-y-3">
            <div className="grid grid-cols-2 gap-3">
              <button
                onClick={() => handleReview('approve')}
                disabled={isProcessing}
                className="py-2.5 px-4 rounded-lg bg-emerald-700 hover:bg-emerald-800 text-white font-semibold text-xs transition flex items-center justify-center gap-1.5 shadow-xs cursor-pointer"
              >
                <CheckCircle2 className="w-4 h-4" />
                {isProcessing ? 'Processing...' : 'APPROVE & ISSUE PASSPORT'}
              </button>
              <button
                onClick={() => handleReview('reject')}
                disabled={isProcessing}
                className="py-2.5 px-4 rounded-lg border border-red-300 hover:bg-red-50 text-red-700 font-semibold text-xs transition flex items-center justify-center gap-1.5 cursor-pointer"
              >
                <XCircle className="w-4 h-4" />
                REJECT WITH REASON
              </button>
            </div>
            <p className="text-[11px] text-slate-400 text-center font-medium">
              Approval activates the worker in Rozgar PostGIS matching and initializes their tamper-evident Digital Skill Passport.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};
