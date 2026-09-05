-- Enable PostGIS & UUID extensions
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (base auth entity)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone VARCHAR(20) UNIQUE NOT NULL,
  email VARCHAR(255),
  role VARCHAR(20) CHECK (role IN ('customer', 'worker', 'admin')) NOT NULL,
  full_name VARCHAR(120),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Service Categories (Ontology Parent)
CREATE TABLE IF NOT EXISTS service_categories (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  name_ta VARCHAR(100),
  icon VARCHAR(50),
  slug VARCHAR(100) UNIQUE NOT NULL
);

-- Services (Ontology Child)
CREATE TABLE IF NOT EXISTS services (
  id SERIAL PRIMARY KEY,
  category_id INT REFERENCES service_categories(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  name_ta VARCHAR(100),
  slug VARCHAR(100) UNIQUE NOT NULL,
  icon VARCHAR(50),
  base_diagnostic_fee NUMERIC(10, 2) DEFAULT 250.00,
  platform_fee NUMERIC(10, 2) DEFAULT 25.00,
  is_active BOOLEAN DEFAULT true
);

-- Customer Profiles
CREATE TABLE IF NOT EXISTS customer_profiles (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE PRIMARY KEY,
  saved_addresses JSONB DEFAULT '[]'::jsonb,
  default_location GEOGRAPHY(Point, 4326)
);

-- Worker Profiles (Tradesperson credentials & Digital Skill Passport metrics)
CREATE TABLE IF NOT EXISTS worker_profiles (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE PRIMARY KEY,
  kyc_status VARCHAR(20) CHECK (kyc_status IN ('pending', 'verified', 'rejected')) DEFAULT 'pending',
  id_document_url TEXT,
  face_capture_url TEXT,
  uan VARCHAR(50),
  primary_skill_id INT REFERENCES services(id),
  secondary_skill_ids INT[] DEFAULT '{}',
  current_location GEOGRAPHY(Point, 4326),
  is_available BOOLEAN DEFAULT false,
  is_on_active_job BOOLEAN DEFAULT false,
  rating_avg NUMERIC(3, 2) DEFAULT 0.00,
  rating_count INT DEFAULT 0,
  reliability_score NUMERIC(4, 3) DEFAULT 1.000,
  jobs_completed INT DEFAULT 0,
  earnings_total NUMERIC(12, 2) DEFAULT 0.00,
  joined_at TIMESTAMPTZ DEFAULT now(),
  last_location_update TIMESTAMPTZ
);

-- Orders (Full State Machine Lifecycle)
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES users(id) ON DELETE SET NULL,
  worker_id UUID REFERENCES users(id) ON DELETE SET NULL,
  service_id INT REFERENCES services(id) ON DELETE SET NULL,
  description TEXT,
  status VARCHAR(30) CHECK (status IN
    ('requested', 'matching', 'offered', 'accepted', 'worker_enroute', 'in_progress', 'completed', 'cancelled', 'disputed')
  ) DEFAULT 'requested',
  scheduled_type VARCHAR(20) CHECK (scheduled_type IN ('immediate', 'scheduled')) DEFAULT 'immediate',
  scheduled_time TIMESTAMPTZ,
  customer_location GEOGRAPHY(Point, 4326),
  match_score NUMERIC(5, 4),
  final_amount NUMERIC(10, 2),
  platform_commission NUMERIC(10, 2),
  worker_payout NUMERIC(10, 2),
  payment_status VARCHAR(20) CHECK (payment_status IN ('pending', 'paid', 'failed')) DEFAULT 'pending',
  razorpay_order_id VARCHAR(100),
  created_at TIMESTAMPTZ DEFAULT now(),
  accepted_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ
);

-- Real-time Order GPS Tracking History
CREATE TABLE IF NOT EXISTS order_tracking (
  id SERIAL PRIMARY KEY,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  worker_location GEOGRAPHY(Point, 4326),
  recorded_at TIMESTAMPTZ DEFAULT now()
);

-- Ratings & Citizen Reviews
CREATE TABLE IF NOT EXISTS ratings (
  id SERIAL PRIMARY KEY,
  order_id UUID UNIQUE REFERENCES orders(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES users(id) ON DELETE SET NULL,
  worker_id UUID REFERENCES users(id) ON DELETE SET NULL,
  stars INT CHECK (stars BETWEEN 1 AND 5),
  review_text TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Push & In-app Notifications
CREATE TABLE IF NOT EXISTS notifications (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  type VARCHAR(50),
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Disputes & Resolution Queue
CREATE TABLE IF NOT EXISTS disputes (
  id SERIAL PRIMARY KEY,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  raised_by UUID REFERENCES users(id) ON DELETE SET NULL,
  reason TEXT NOT NULL,
  status VARCHAR(20) CHECK (status IN ('open', 'resolved', 'rejected')) DEFAULT 'open',
  resolution_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Live Configurable Matching Weights (for judge demonstrations)
CREATE TABLE IF NOT EXISTS matching_config (
  id SERIAL PRIMARY KEY,
  param_key VARCHAR(50) UNIQUE NOT NULL,
  param_value NUMERIC(10, 4) NOT NULL,
  description TEXT
);

-- Spatial & Operational Indexes
CREATE INDEX IF NOT EXISTS idx_worker_location ON worker_profiles USING GIST (current_location);
CREATE INDEX IF NOT EXISTS idx_customer_location ON customer_profiles USING GIST (default_location);
CREATE INDEX IF NOT EXISTS idx_order_customer_location ON orders USING GIST (customer_location);
CREATE INDEX IF NOT EXISTS idx_order_tracking_loc ON order_tracking USING GIST (worker_location);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_worker_active_filters ON worker_profiles(primary_skill_id, is_available, is_on_active_job, kyc_status);

-- Enable Row Level Security (RLS) on all application tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE worker_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE disputes ENABLE ROW LEVEL SECURITY;
ALTER TABLE matching_config ENABLE ROW LEVEL SECURITY;

-- 1. Service Categories: Public Read
CREATE POLICY "Public read service_categories" ON service_categories FOR SELECT USING (true);

-- 2. Services: Public Read
CREATE POLICY "Public read services" ON services FOR SELECT USING (true);

-- 3. Customer Profiles: Own Only
CREATE POLICY "Customers view own profile" ON customer_profiles FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Customers update own profile" ON customer_profiles FOR UPDATE USING (auth.uid() = user_id);

-- 4. Worker Profiles: Public Read for Verified Workers, Own Update
CREATE POLICY "Public view verified worker profiles" ON worker_profiles FOR SELECT USING (kyc_status = 'verified');
CREATE POLICY "Workers update own profile" ON worker_profiles FOR UPDATE USING (auth.uid() = user_id);

-- 5. Orders: Customers and Assigned Workers Access
CREATE POLICY "Users view own orders" ON orders FOR SELECT USING (auth.uid() = customer_id OR auth.uid() = worker_id);
CREATE POLICY "Customers create own orders" ON orders FOR INSERT WITH CHECK (auth.uid() = customer_id);
CREATE POLICY "Involved parties update orders" ON orders FOR UPDATE USING (auth.uid() = customer_id OR auth.uid() = worker_id);

-- 6. Order Tracking: Order Participants Access
CREATE POLICY "View tracking for own orders" ON order_tracking FOR SELECT 
USING (EXISTS (SELECT 1 FROM orders WHERE orders.id = order_tracking.order_id AND (orders.customer_id = auth.uid() OR orders.worker_id = auth.uid())));
CREATE POLICY "Workers log tracking for own orders" ON order_tracking FOR INSERT 
WITH CHECK (EXISTS (SELECT 1 FROM orders WHERE orders.id = order_tracking.order_id AND orders.worker_id = auth.uid()));

-- 7. Ratings: Public Read, Customer Insert
CREATE POLICY "Public read reviews" ON ratings FOR SELECT USING (true);
CREATE POLICY "Customers submit rating for own order" ON ratings FOR INSERT WITH CHECK (auth.uid() = customer_id);

-- 8. Notifications: Own Only
CREATE POLICY "Users view own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users update own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);

-- 9. Disputes: Own Only
CREATE POLICY "Users view own disputes" ON disputes FOR SELECT USING (auth.uid() = raised_by);
CREATE POLICY "Users create own disputes" ON disputes FOR INSERT WITH CHECK (auth.uid() = raised_by);

-- 10. Users: Own Only
CREATE POLICY "Users view own record" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users update own record" ON users FOR UPDATE USING (auth.uid() = id);
