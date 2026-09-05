export interface KpiData {
  active_jobs: number;
  online_workers: number;
  verified_workforce: number;
  completed_today: number;
  open_disputes: number;
  today_gmv: number;
  platform_fee_collected: number;
  worker_payout_total: number;
  fee_model: string;
  zone_breakdown: Record<string, { capacity_pct: number; active_jobs: number; status: string }>;
  recent_stream: Array<{
    order_id: string;
    status: string;
    payment_status: string;
    amount: number;
    timestamp: string;
  }>;
}

export interface WorkerTelemetry {
  worker_id: string;
  name: string;
  phone: string;
  trade: string;
  is_available: boolean;
  is_on_active_job: boolean;
  status: 'available' | 'enroute' | 'in_progress' | 'offline';
  rating_avg: number;
  jobs_completed: number;
  lat: number;
  lng: number;
  battery_pct: number;
  speed_kmh: number;
  last_gps_ping: string;
  active_order_id?: string | null;
  customer_destination?: string | null;
  eta_mins?: number | null;
}

export interface KycItem {
  worker_id: string;
  full_name: string;
  phone: string;
  trade: string;
  kyc_status: string;
  uan: string;
  experience_years: number;
  prior_jobs: number;
  submitted_at: string;
  documents: {
    aadhaar_name: string;
    aadhaar_dob: string;
    aadhaar_gender: string;
    aadhaar_address: string;
    uan_registry_status: string;
    face_match_status: string;
    trade_certification: string;
  };
}

export interface OrderItem {
  id: string;
  order_number: string;
  customer_name?: string;
  worker_name?: string;
  trade?: string;
  status: string;
  payment_status: string;
  final_amount: number;
  platform_commission: number;
  worker_payout: number;
  created_at: string;
}

export interface DisputeItem {
  order_id: string;
  order_number: string;
  service: string;
  citizen: {
    name: string;
    rating: number;
    address: string;
    statement: string;
  };
  worker: {
    name: string;
    rating: number;
    jobs_completed: number;
    statement: string;
    evidence_photos: string[];
  };
  financials: {
    gross_paid: number;
    platform_commission: number;
    worker_take_home: number;
    gateway: string;
  };
  arbitration_status: string;
}

export interface PriceRule {
  trade: string;
  govt_cap: number;
  platform_avg: number;
  worker_take_home: number;
  civic_margin_pct: number;
  status: string;
}

export interface HeatmapFeature {
  type: string;
  properties: {
    cluster_name: string;
    intensity: number;
    orders_count: number;
    dominant_trade: string;
    category_color: string;
  };
  geometry: {
    type: string;
    coordinates: [number, number];
  };
}
