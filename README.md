# MakkalSevai (மக்கள் சேவை)
### *Trusted local skills, delivered digitally.*

[![SIH 2026](https://img.shields.io/badge/Smart%20India%20Hackathon-PS26089-blue.svg?style=for-the-badge&logo=target)](https://www.sih.gov.in/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.110+-009688.svg?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![React](https://img.shields.io/badge/React-19-61DAFB.svg?style=for-the-badge&logo=react&logoColor=black)](https://react.dev)
[![PostGIS](https://img.shields.io/badge/PostGIS-16--3.4-336791.svg?style=for-the-badge&logo=postgresql&logoColor=white)](https://postgis.net)
[![Supabase Realtime](https://img.shields.io/badge/Supabase-Realtime%20WS-3ECF8E.svg?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

> **Smart India Hackathon 2026 · Problem Statement PS26089**  
> *A Government-Backed Gig-Economy Marketplace for Verified Blue-Collar Workers*

---

## 📑 Table of Contents

1. [Executive Summary & Problem Statement](#1-executive-summary--problem-statement)
2. [Ecosystem Architecture & Data Flow](#2-ecosystem-architecture--data-flow)
3. [Technology Stack](#3-technology-stack)
4. [Monorepo Directory Structure](#4-monorepo-directory-structure)
5. [Demo Credentials & Live Test Accounts](#5-demo-credentials--live-test-accounts)
6. [Prerequisites & System Requirements](#6-prerequisites--system-requirements)
7. [Environment Variables Reference](#7-environment-variables-reference)
8. [Step-by-Step Local Development Guide](#8-step-by-step-local-development-guide)
9. [Core Technical Deep Dives](#9-core-technical-deep-dives)
   - [Spatial PostGIS Matching Engine](#91-spatial-postgis-matching-engine)
   - [Order Lifecycle State Machine](#92-order-lifecycle-state-machine)
   - [Digital Skill Passport & 1% Welfare Cess](#93-digital-skill-passport--1-welfare-cess)
   - [Real-Time Supabase Dispatch & Telemetry](#94-real-time-supabase-dispatch--telemetry)
   - [Dual Authentication & Physical Device Resilience](#95-dual-authentication--physical-device-resilience)
10. [Test Suites & Quality Verification](#10-test-suites--quality-verification)
11. [Production Deployment & Containerization](#11-production-deployment--containerization)
12. [Hackathon Demo Walkthrough for Judges](#12-hackathon-demo-walkthrough-for-judges)
13. [License & Acknowledgments](#13-license--acknowledgments)

---

## 1. Executive Summary & Problem Statement

### The Problem
- **For Citizens:** Difficulty finding trusted, verified domestic technicians; zero upfront price transparency; no standardized identity checks; cash-only transactions; and no formal dispute resolution.
- **For Blue-Collar Workers:** Exploitation by middlemen; high informal platform commissions (20–30%); unpredictable demand; lack of portable work identity; and total exclusion from state social welfare systems.

### The MakkalSevai Solution
**MakkalSevai** (*"People's Service"*) bridges the trust deficit with a **civic-backed digital marketplace** connecting certified tradespeople (electricians, plumbers, carpenters, masons, painters, AC mechanics) with nearby citizens via:
1. **Mathematical Spatial Matching:** PostGIS-powered matching combining real distance, verified ratings, reliability scores, and new-worker fairness boosts.
2. **Digital Skill Passport (UAN / National Skill Registry):** Portable, tamper-proof credential logging verified trades, lifetime ratings, and completed dispatches.
3. **1% Tamil Nadu Gig Worker Welfare Fund:** Automatic deduction transparency contributing toward state social security.
4. **Civic Command Center:** Full municipal governance over fleet telemetry, fraud prevention, verification queues, and dispute arbitration.
5. **Zero Platform Exploitation:** Fixed nominal ₹25 diagnostic/platform fee instead of exploitative percentage cuts.

---

## 2. Ecosystem Architecture & Data Flow

MakkalSevai is architected as a high-performance monorepo uniting two native Flutter mobile applications, a React 19 administrative command center, a FastAPI core engine, and a PostGIS/Supabase real-time spatial database.

### System Architecture Diagram

```
┌────────────────────────┐      ┌────────────────────────┐      ┌────────────────────────┐
│   Customer Mobile App  │      │   Worker Partner App   │      │ Admin Civic Dashboard  │
│  (Flutter Android APK) │      │  (Flutter Android APK) │      │(React 19 + Vite + Leaf)│
└───────────┬────────────┘      └───────────┬────────────┘      └───────────┬────────────┘
            │                               │                               │
            │ REST / HTTPS (Candidate URLs) │ REST / Realtime WS            │ Bearer JWT / REST
            ▼                               ▼                               ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        FastAPI Core Backend (Python 3.11+ / Uvicorn)                   │
│  ├─ Auth Engine (Email/Password + Dev OTP + JWT HS256)                                 │
│  ├─ Spatial Matching Engine (PostGIS ST_DWithin + Dynamic Multi-Factor Scoring)         │
│  ├─ Order State Machine (Requested → Enroute → Arrived → In Progress → Settled)        │
│  ├─ Worker Welfare & Digital Passport Service (UAN + 1% State Welfare Cess)            │
│  ├─ Municipal Governance & Dispute Arbitration API                                    │
│  └─ WebSocket Telemetry Streamer (/ws/orders/{id}/tracking)                            │
└───────────────────────────────────────────┬────────────────────────────────────────────┘
                                            │
               ┌────────────────────────────┴────────────────────────────┐
               ▼                                                         ▼
┌─────────────────────────────┐                           ┌──────────────────────────────┐
│     PostgreSQL 16 + PostGIS │                           │   Supabase Realtime Cloud    │
│  ├─ Spatial GIST Indexes    │                           │  ├─ Dispatch Broadcast WS    │
│  ├─ Row Level Security (RLS)│                           │  ├─ Presence State Channels  │
│  └─ Transaction Ledger      │                           │  └─ Cloud Storage (KYC/Docs) │
└─────────────────────────────┘                           └──────────────────────────────┘
```

### End-to-End Order Request Lifecycle

```
Citizen App               FastAPI Backend             Worker App             Admin Dashboard
    │                            │                        │                         │
    │── 1. Create Booking ──────▶│                        │                         │
    │   (GPS + Service ID)       │                        │                         │
    │                            │── 2. Run Spatial Match▶│                         │
    │                            │      (5km Radius)      │                         │
    │                            │── 3. Broadcast Offer ─▶│ (Realtime Sheet Modal)  │
    │                            │                        │                         │
    │                            │◀─ 4. Accept Dispatch ──│                         │
    │◀── 5. Status: Accepted ────│                        │                         │
    │                            │                        │                         │
    │◀── 6. Live GPS Telemetry ──│◀─ 7. Broadcast GPS ────│                         │
    │   (Leaflet/flutter_map)    │      (Geolocator)      │                         │
    │                            │                        │                         │
    │                            │◀─ 8. Complete & Verify─│                         │
    │◀── 9. Submit Rating (1-5) ─│                        │                         │
    │                            │── 10. Ledger Split ───▶│ (₹250 Payout + ₹2.5 Cess│
    │                            │                        │  to Digital Wallet)     │
    │                            │                        │                         │
    │                            │─────────────────────────────────────────────────▶│ 11. Fleet KPI,
    │                            │                                                  │     Audit Log
```

---

## 3. Technology Stack

| Layer | Technology | Version | Key Responsibilities & Capabilities |
|:---|:---|:---:|:---|
| **Backend Framework** | **FastAPI** (Python) | `^0.110.0` | Async RESTful API, WebSocket telemetry, Pydantic v2 schemas, JWT security |
| **ASGI Server** | **Uvicorn** | `^0.28.0` | Production async event loop handling concurrent citizen/worker traffic |
| **Primary Database** | **PostgreSQL** + **PostGIS** | `16-3.4` | Spatial storage, spherical distance calculations (`ST_Distance`), GIST spatial indexes |
| **ORM & Driver** | **SQLAlchemy** + **asyncpg** | `2.0+` / `^0.29` | Fully non-blocking async PostgreSQL access with connection pooling |
| **Realtime Engine** | **Supabase Realtime** | Cloud / WS | Low-latency dispatch offer broadcast, online worker heartbeat, presence |
| **Customer Mobile App** | **Flutter** (Dart) | `3.x` | Touch-first citizen app: Explore, Booking, Live Tracking, Activity, Profile |
| **Worker Partner App** | **Flutter** (Dart) | `3.x` | Partner app: Dispatch Radar, My Jobs, Wallet & Instant IMPS, Skill Passport |
| **Admin Command Center**| **React 19** + **TypeScript** | `19.2` / `~5.7`| Desktop operations: Fleet Map, KYC Verification Queue, Dispute Settlement |
| **Web Styling & UI** | **Tailwind CSS** + **Lucide** | `^3.4` / `^1.16`| High-density civic command center UI, operational alerts, status indicators |
| **Map Rendering** | **Leaflet** & **flutter_map** | `^1.9` / `^8.3` | OpenStreetMap vector tile rendering, worker pin overlays, live route tracking |
| **Device Hardware** | **Geolocator** (Android) | `^14.0.3` | Native GPS hardware polling, high-accuracy coordinate capture |
| **Payments Sandbox** | **Razorpay Test Mode** | Sandboxed | Simulated split escrow settlement: Diagnostic fee vs. Worker payout |
| **Testing** | **pytest-asyncio** + **flutter_test**| Latest | 100% passing test suites across API, database constraints, models & widgets |

---

## 4. Monorepo Directory Structure

```
d:\Projects\Hackathon\MakkalSevai├── .env.example                     # Environment template for local & Docker setups
├── docker-compose.yml               # Multi-container orchestration (PostGIS + Backend)
├── pytest.ini                       # Pytest test-runner configuration
├── README.md                        # Master project documentation (this file)
│
├── backend/                         # FastAPI Python Core Backend
│   ├── Dockerfile                   # Production container definition for backend API
│   ├── requirements.txt             # Python runtime dependencies
│   ├── app/
│   │   ├── main.py                  # FastAPI app entrypoint, CORS, router mounting, WS
│   │   ├── core/
│   │   │   ├── config.py            # Pydantic BaseSettings loading .env configurations
│   │   │   ├── database.py          # Async SQLAlchemy engine & async_sessionmaker
│   │   │   └── security.py          # Password hashing (bcrypt) & JWT issuance/validation
│   │   ├── db/
│   │   │   └── schema.sql           # PostGIS DDL, spatial indexes, RLS policies
│   │   ├── models/
│   │   │   ├── entities.py          # SQLAlchemy ORM mapped classes (User, Order, Wallet...)
│   │   │   └── schemas.py           # Pydantic request/response validation contracts
│   │   ├── services/
│   │   │   └── matching_engine.py   # Mathematical spatial matching & radius expansion
│   │   └── api/v1/                  # Isolated REST endpoint modules
│   │       ├── auth.py              # OTP request/verify, Email login/signup, Rajesh link
│   │       ├── customers.py         # Customer /me, saved addresses, booking profiles
│   │       ├── workers.py           # Worker /me/jobs, /me/wallet, /me/passport, GPS update
│   │       ├── services.py          # Service catalog & ontology hierarchy
│   │       ├── orders.py            # Order creation, dispatch accept, complete, tracking
│   │       ├── payments.py          # Razorpay sandbox order creation & split webhook
│   │       ├── ratings.py           # Review submission & worker average recalculation
│   │       └── admin.py             # Operations KPIs, fleet data, KYC queue, disputes
│   └── tests/
│       ├── test_api.py              # Health, auth flows, order lifecycle, /me endpoints
│       ├── test_matching.py         # Spatial distance, ratings, reliability, fairness math
│       └── test_admin.py            # Admin authentication, dispute resolutions, KPIs
│
├── customer-app/                    # Citizen Mobile Application (Flutter)
│   ├── pubspec.yaml                 # Flutter dependencies (flutter_map, geolocator...)
│   ├── lib/
│   │   ├── main.dart                # App entrypoint with persistent session routing
│   │   ├── core/
│   │   │   ├── constants/           # Candidate URLs (LAN, Emulator, Localhost)
│   │   │   ├── network/             # ApiClient with multi-host fallback & offline resilience
│   │   │   ├── theme/               # Emerald/Saffron civic design tokens
│   │   │   └── services/            # LocationService (native device GPS & reverse geocoding)
│   │   ├── models/                  # ServiceCategory, ServiceItem, OrderModel
│   │   └── features/
│   │       ├── auth/                # LoginScreen (Dual-tab Email/Password + Sign Up)
│   │       ├── home/                # HomeScreen (4-tab IndexedStack shell)
│   │       ├── booking/             # BookingTabScreen (Real device GPS, category picker)
│   │       ├── activity/            # ActivityTabScreen (Active order status & past history)
│   │       ├── tracking/            # TrackingScreen (Live flutter_map with worker pin)
│   │       └── profile/             # ProfileTabScreen (Verified citizen info, language)
│   └── test/
│       └── widget_test.dart         # Flutter widget test suite
│
├── worker-app/                      # Worker Partner Mobile Application (Flutter)
│   ├── pubspec.yaml                 # Dependencies (supabase_flutter, geolocator...)
│   ├── lib/
│   │   ├── main.dart                # Entrypoint with Supabase initialization & session route
│   │   ├── core/
│   │   │   ├── constants/           # Network candidate endpoints & civic welfare labels
│   │   │   ├── models/              # WorkerProfile, WorkerJob, WorkerWallet, Transactions
│   │   │   ├── network/             # ApiClient (auth, /me endpoints, Supabase Realtime)
│   │   │   └── theme/               # Slate Navy, Emerald Online, Saffron status colors
│   │   └── features/
│   │       ├── auth/                # WorkerLoginScreen (Email/Password + OTP + Demo chip)
│   │       ├── home/                # WorkerHomeScreen (4-tab IndexedStack shell + radar)
│   │       ├── dispatch/            # IncomingOfferSheet (30-second accept/decline modal)
│   │       ├── job/                 # ActiveJobScreen (Navigation, OTP verification, finish)
│   │       ├── jobs/                # WorkerJobsTabScreen (Active & completed job ledger)
│   │       ├── wallet/              # WorkerWalletTabScreen (IMPS payout, welfare cess, txs)
│   │       ├── profile/             # WorkerProfileTabScreen (Skill Passport, live GPS sync)
│   │       └── kyc/                 # VerificationScreen (Simulated DigiLocker/e-Shram)
│   └── test/
│       ├── widget_test.dart         # Smoke test
│       └── worker_models_test.dart  # Models & wallet ledger calculation unit tests
│
└── admin-dashboard/                 # Municipal Civic Command Center (React 19 + TS)
    ├── package.json                 # React 19, Vite, Tailwind CSS, Lucide, Leaflet
    ├── vite.config.ts               # Vite configuration with port 5173
    ├── src/
    │   ├── App.tsx                  # Navigation shell & 5-screen desktop route switcher
    │   ├── index.css                # Tailwind utility directives & custom scrollbars
    │   ├── components/
    │   │   ├── Navbar.tsx           # Civic authority branding & officer identity banner
    │   │   └── AdminAuthModal.tsx   # Municipal officer authentication dialog
    │   └── screens/
    │       ├── CommandCenter.tsx    # Live operational KPIs, active jobs, alerts
    │       ├── SpatialFleet.tsx     # Leaflet map with worker telemetry & radar zones
    │       ├── WorkerVerification.tsx# DigiLocker / e-Shram simulated review queue
    │       ├── OrdersDisputes.tsx   # Dispute arbitration & test payout actions
    │       └── PriceAnalytics.tsx   # Historical demand heatmap & dynamic tariff controls
    └── dist/                        # Production build bundle
```

---

## 5. Demo Credentials & Live Test Accounts

For hackathon judges, evaluators, and team members, MakkalSevai includes pre-seeded accounts equipped with realistic histories, verified KYC documents, and transaction ledgers:

| Portal / App | Role / User | Email / Username | Password / OTP | Pre-Seeded Context / Notes |
|:---|:---|:---|:---|:---|
| **Customer App** | **Citizen Customer** | `senthil.nathan@example.com` | `password123` *(or OTP `123456`)* | Pre-seeded with T. Nagar address, recent completed electrician service, and active booking history. |
| **Worker App** | **Electrician Partner** | `rajesh.kumar@example.com` *(Phone: `+919876543211`)* | `Makkal@2026` *(or OTP `123456`)* | **Rajesh Kumar** — Verified Grade-A Electrician. 4.9⭐ rating, 342 jobs completed, ₹1,250 available wallet balance, linked SBI account. Tap the **[ Rajesh Kumar ]** chip on login! |
| **Admin Dashboard**| **Municipal Inspector**| `inspector.meenakshi` | `makkalsevai2026` | **Inspector S. Meenakshi** (Badge: `TN-GCC-ZO-2026-104`). Full administrative control over verification, disputes, and analytics. |
| **Dev Bypass** | **Emergency Admin Key** | Header: `X-Admin-Key` | `makkalsevai-admin-dev-2026` | Allows direct API inspection in Postman or Swagger UI without logging in. |

---

## 6. Prerequisites & System Requirements

Ensure the following runtimes are installed on your development workstation:

- **Docker & Docker Compose** (v20.10+ / Compose v2.0+) — *Recommended for instant PostGIS database setup*.
- **Python** `3.11` to `3.14` — *For the FastAPI core backend*.
- **Node.js** `18.x` or `20.x` + **npm** — *For the React 19 Admin Dashboard*.
- **Flutter SDK** `3.19+` to `3.29+` (Channel stable) — *For compiling Customer and Worker mobile APKs*.
- **Android SDK** (API Level 34 / Android 14) + **Java 17 / 21** — *For building Android binaries*.

---

## 7. Environment Variables Reference

Create a `.env` file in the project root (or copy from `.env.example`):

```bash
cp .env.example .env
```

| Variable | Type | Default Value | Description |
|:---|:---:|:---|:---|
| `PORT` | Integer | `8001` | Core backend port for FastAPI |
| `HOST` | String | `0.0.0.0` | Listen host (binds to all network interfaces) |
| `DEBUG` | Boolean | `True` | Enables dev-mode OTP output in terminal logs |
| `DATABASE_URL` | String | `postgresql+asyncpg://postgres:postgrespassword@localhost:5433/makkalsevai` | Async SQLAlchemy connection string for PostGIS |
| `SYNC_DATABASE_URL` | String | `postgresql://postgres:postgrespassword@localhost:5433/makkalsevai` | Sync connection string for DDL migrations |
| `MATCH_WEIGHT_DISTANCE` | Float | `0.45` | Distance weight (alpha) in matching formula |
| `MATCH_WEIGHT_RATING` | Float | `0.30` | Rating weight (beta) in matching formula |
| `MATCH_WEIGHT_RELIABILITY` | Float | `0.15` | Reliability weight (gamma) in matching formula |
| `MATCH_WEIGHT_FAIRNESS` | Float | `0.10` | Fairness weight (delta) for new worker equity |
| `MATCH_DEFAULT_RADIUS_METERS`| Integer | `5000` | Initial search radius (5 kilometers) |
| `MATCH_MAX_RADIUS_METERS` | Integer | `15000` | Maximum expanded search radius (15 kilometers) |
| `JWT_SECRET` | String | `makkalsevai-hackathon-supersecret-jwt-key-2026` | Secret signing key for citizen/worker JWTs |
| `JWT_ALGORITHM` | String | `HS256` | JWT signing algorithm |
| `ACCESS_TOKEN_EXPIRE_MINUTES`| Integer | `1440` | Token expiration time (24 hours) |
| `ENABLE_MOCK_GOV_APIS` | Boolean | `true` | Simulates DigiLocker and e-Shram API responses |
| `SUPABASE_URL` | String | `https://ulplesjbvblspibdpspr.supabase.co` | Supabase Cloud instance URL |
| `SUPABASE_ANON_KEY` | String | `[Your Anon Key]` | Supabase public anonymous key |

---

## 8. Step-by-Step Local Development Guide

### Step 1: Clone Repository
```bash
git clone https://github.com/kittyboy06/MakkalSevai.git
cd MakkalSevai
```

### Step 2: Start PostGIS Database via Docker
Run the pre-configured PostGIS container on local port `5433`:
```bash
docker compose up -d makkalsevai-db
```
*Verify database health:*
```bash
docker ps
# Status should display: Up ... (healthy)
```

### Step 3: Run FastAPI Core Backend
1. Navigate to `backend/` and install requirements:
   ```bash
   cd backend
   python -m venv venv
   # Windows:
   .\venv\Scripts\activate
   # macOS/Linux:
   source venv/bin/activate
   pip install -r requirements.txt
   ```
2. Start the FastAPI server with auto-reload:
   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port 8001 --reload
   ```
3. Open interactive Swagger API docs in your browser:
   👉 **[http://localhost:8001/docs](http://localhost:8001/docs)**

---

### Step 4: Run the Admin Civic Command Center
1. Navigate to `admin-dashboard/`:
   ```bash
   cd ../admin-dashboard
   npm install
   ```
2. Start Vite development server:
   ```bash
   npm run dev
   ```
3. Open the desktop command center:
   👉 **[http://localhost:5173](http://localhost:5173)**  
   *Log in with: `inspector.meenakshi` / `makkalsevai2026`*

---

### Step 5: Run the Customer Mobile App
1. Navigate to `customer-app/`:
   ```bash
   cd ../customer-app
   flutter pub get
   ```
2. Launch on connected Android device or emulator:
   ```bash
   flutter run
   ```
   *Tip: Use the pre-filled demo login chip for instant access.*

---

### Step 6: Run the Worker Partner App
1. Navigate to `worker-app/`:
   ```bash
   cd ../worker-app
   flutter pub get
   ```
2. Launch on a second emulator or physical phone:
   ```bash
   flutter run
   ```
   *Tip: Tap the **Rajesh Kumar** chip to log in immediately as the primary certified electrician.*

---

## 9. Core Technical Deep Dives

### 9.1 Spatial PostGIS Matching Engine
MakkalSevai eliminates predatory algorithmic black-boxes by using an **open, multi-factor deterministic scoring equation**:

$$\text{Score}_i = \left(\alpha \cdot \min\left(\frac{1}{d_i}, 5.0\right)\right) + (\beta \cdot \text{RatingNorm}_i) + (\gamma \cdot \text{RelNorm}_i) + (\delta \cdot \text{FairnessBoost}_i)$$

Where:
- $\alpha = 0.45$: Proximity priority (closest workers are ranked first).
- $\beta = 0.30$: Customer rating history normalized to $[0.0, 1.0]$.
- $\gamma = 0.15$: Platform reliability (on-time rate, non-cancellation record).
- $\delta = 0.10$: **New-Worker Fairness Boost** ($1.0$ if $< 5$ reviews, else $0.3$) ensuring newcomers receive job leads and preventing senior monopoly.
- **Dynamic Radius Expansion:** Queries start at **5,000m (5 km)**. If 0 eligible workers are online, the radius expands automatically to **10,000m (10 km)** and **15,000m (15 km)** using PostGIS `ST_DWithin`.

### 9.2 Order Lifecycle State Machine
Orders progress strictly through an immutable state machine audited in PostgreSQL:

```
[ requested ]
      │ (Matching Engine finds candidate)
      ▼
 [ matching ]
      │ (Offer pushed to candidate phone via Supabase Realtime)
      ▼
  [ offered ] ──(Decline / 30s Timeout)──▶ Fallback to Next Candidate
      │
      ▼ (Worker taps "Accept")
 [ accepted ]
      │ (Worker begins travel)
      ▼
[ worker_enroute ]
      │ (Worker arrives at citizen premises)
      ▼
  [ arrived ]
      │ (Citizen gives 4-digit start OTP)
      ▼
[ in_progress ]
      │ (Job completed, invoice confirmed)
      ▼
 [ completed ] ──▶ Digital Settlement (₹250 Payout + ₹2.5 Welfare Fund)
      │
      ▼ (Optional citizen dispute)
 [ disputed ] ──▶ Escalated to Municipal Admin Dashboard for Arbitration
```

### 9.3 Digital Skill Passport & 1% Welfare Cess
- **Digital Skill Passport:** Inspired by India's National Skill Development Corporation (NSDC) and e-Shram, every worker profile maintains a permanent, verifiable passport logging primary and secondary trades, total hours worked, citizen reviews, and government KYC status.
- **1% Tamil Nadu Gig Worker Welfare Fund Cess:** Every completed transaction automatically computes a 1% welfare contribution logged transparently in `worker_transactions` as `WELFARE_CESS`. This provides verifiable social security tracking without opaque corporate skimming.

### 9.4 Real-Time Supabase Dispatch & Telemetry
- Replaces heavy custom MQTT brokers with **Supabase Realtime PostgreSQL Change Data Capture (CDC)** and WebSocket channels.
- When an order enters `offered`, a broadcast event triggers the worker's **30-second countdown bottom sheet** with haptic audio feedback.
- During `worker_enroute`, the worker's device stream emits GPS telemetry to `/ws/orders/{id}/tracking`, enabling live Leaflet map updates on the citizen's screen.

### 9.5 Dual Authentication & Physical Device Resilience
- **Dual Sign-In:** Both Customer and Worker apps feature standard **Email & Password** and **Mobile OTP** sign-in options.
- **Multi-Host Polling:** To solve the standard Android emulator `10.0.2.2` versus physical phone WiFi LAN IP problem, `ApiClient` dynamically tests candidate hosts (`192.168.1.2:8001`, `10.0.2.2:8001`, `localhost:8001`) with a 3-second failover and offline session fallback, ensuring physical phones never hang with a `TimeoutException`.

---

## 10. Test Suites & Quality Verification

MakkalSevai maintains strict continuous quality gates across the entire monorepo:

### Backend Pytest Suite (`pytest tests/ -v`)
17/17 tests passing across authentication, admin privileges, order state machines, and PostGIS spatial queries:
```
tests/test_admin.py::test_admin_auth_required PASSED                     [  5%]
tests/test_admin.py::test_admin_login_and_kpis PASSED                    [ 11%]
tests/test_api.py::test_health_and_root PASSED                           [ 17%]
tests/test_api.py::test_auth_otp_flow PASSED                             [ 23%]
tests/test_api.py::test_auth_email_flow PASSED                           [ 29%]
tests/test_service_ontology PASSED                                        [ 35%]
tests/test_full_order_demo_lifecycle PASSED                               [ 41%]
tests/test_customer_me_and_orders_flow PASSED                             [ 47%]
tests/test_worker_me_and_wallet_flow PASSED                               [ 52%]
tests/test_matching.py::test_matching_finds_verified_electrician PASSED  [ 58%]
tests/test_matching.py::test_worker_unavailable_excluded PASSED          [ 64%]
tests/test_matching.py::test_worker_on_active_job_excluded PASSED        [ 70%]
tests/test_matching.py::test_worker_unverified_excluded PASSED           [ 76%]
tests/test_matching.py::test_secondary_skill_matching PASSED             [ 82%]
tests/test_matching.py::test_fairness_boost_for_new_workers PASSED       [ 88%]
tests/test_matching.py::test_progressive_radius_expansion PASSED         [ 94%]
tests/test_matching.py::test_rejection_fallback_next_candidate PASSED    [100%]

======================= 17 passed in 3.53s =======================
```

### Mobile App Static Analysis (`flutter analyze --no-pub`)
Both mobile apps pass Flutter lints with **0 errors, 0 warnings, and 0 deprecations**:
```bash
# In customer-app:
Analyzing customer-app...
No issues found! (ran in 2.7s)

# In worker-app:
Analyzing worker-app...
No issues found! (ran in 4.8s)
```

### Mobile Unit & Widget Tests (`flutter test`)
```bash
# In customer-app:
00:01 +6: All tests passed! (HomeScreen, BookingTabScreen, Activity, Profile, Login)

# In worker-app:
00:01 +3: All tests passed! (Worker App smoke test, WorkerJobItemModel, WorkerWalletModel)
```

---

## 11. Production Deployment & Containerization

### Docker Production Deployment
The entire backend stack can be deployed to any Linux VPS, AWS EC2, or DigitalOcean Droplet using Docker Compose:

```bash
# Build and launch all services in detached mode
docker compose up -d --build
```

### Standalone Release Android APKs
Both mobile apps compile to standalone, production-ready release APKs:
- **Customer App Release APK:** `customer-app/build/app/outputs/flutter-apk/app-release.apk` *(~51.5 MB)*
- **Worker App Release APK:** `worker-app/build/app/outputs/flutter-apk/app-release.apk` *(~53.6 MB)*

Build them anytime with:
```bash
cd customer-app && flutter build apk --release
cd ../worker-app && flutter build apk --release
```

### Admin Dashboard Production Build
```bash
cd admin-dashboard
npm run build
# Generates high-performance static SPA in admin-dashboard/dist/
```
Deploy the resulting `dist/` directory instantly to **Vercel**, **Cloudflare Pages**, or **Netlify**.

---

## 12. Hackathon Demo Walkthrough for Judges

To demonstrate the full ecosystem in **under 4 minutes** during an evaluation:

1. **Step 1: Open Admin Command Center (`http://localhost:5173`)**
   - Log in as `inspector.meenakshi` / `makkalsevai2026`.
   - Show live operational KPIs, active jobs, and the **Spatial Fleet Map** displaying verified technicians around Chennai.
2. **Step 2: Launch Worker Partner App (`worker-app`)**
   - Tap the **[ Rajesh Kumar ]** demo chip to log in instantly.
   - Toggle status to **🟢 ONLINE • Receiving Jobs** — point out the glowing radar pulse.
   - Switch between **Dashboard**, **My Jobs**, **Wallet** (showing ₹1,250 balance & 1% Welfare contribution), and **Profile** (showing Digital Skill Passport).
3. **Step 3: Launch Customer App (`customer-app`)**
   - Log in as `senthil.nathan@example.com` / `password123`.
   - Tap **Electrician (மின்சார பணியாளர்)**.
   - The device GPS captures live coordinates in T. Nagar. Tap **[ Confirm & Request Service ]**.
4. **Step 4: Realtime Match & Acceptance**
   - In milliseconds, the Worker phone sounds an incoming offer chime and opens the 30-second **Incoming Offer Sheet**.
   - Tap **[ Accept Job (ஏற்றுக்கொள்) ]**.
   - Show the Customer App immediately transitioning to **Live Tracking Mode** with real-time ETA and worker marker.
5. **Step 5: Job Execution & Instant Settlement**
   - Advance worker status to **Start Job** and **Complete Work**.
   - Rate the service 5.0⭐ on the Customer phone.
   - Show the Worker's **Wallet Tab** immediately update with the ₹250 payout and new ledger record!

---

## 13. License & Acknowledgments

- **License:** Open source under the [MIT License](LICENSE).
- **Hackathon:** Developed for **Smart India Hackathon (SIH 2026)**, Problem Statement **PS26089**.
- **Civic Vision:** Dedicated to formalizing blue-collar gig work across Tamil Nadu and India, protecting worker livelihoods while restoring citizen trust through transparent, public-interest software engineering.

---

<p align="center">
  <b>MakkalSevai Ecosystem</b> • Built with ❤️ for Smart India Hackathon 2026
</p>
