# MakkalSevai — Admin & Civic Authority Dashboard Design Specification
### SIH 2026 · PS26089 · Civic Oversight & Operations Platform

---

## 1. Executive Summary & Civic Purpose

The **MakkalSevai Admin & Civic Authority Dashboard** is the command center and regulatory governance platform for municipal authorities, smart city administrators, and platform operations directors.

While the **Customer App** prioritizes effortless booking and transparent trust, and the **Worker App** prioritizes sunlight legibility and rapid one-thumb task execution, the **Admin Dashboard** operates with a distinct mandate:
1. **Public Sector Accountability:** Enforce fair civic price ceilings, monitor platform commissions (fixed ₹25), and ensure zero exploitation of informal gig workers.
2. **Real-Time Spatial Governance:** Maintain an unblinking, live operational overview of city-wide trade supply, ongoing dispatches, and emergency escalations across Chennai clusters (focusing on T. Nagar).
3. **Institutional Worker Onboarding:** Provide human-in-the-loop verification for unorganized trade workers submitting Aadhaar, e-Shram, and Skill India credentials with clear **DEMO VERIFICATION (SIMULATED GOVERNMENT INTEGRATION)** transparency.
4. **Dispute Arbitration:** Offer evidence-grounded grievance redressal with one-click financial simulation (**Release Worker Payout (Demo)** or **Simulate Refund (Test Mode)**).
5. **Demand Density Heatmap:** Historical spatial order aggregation into GeoJSON density layers to inform municipal skill development programs, trade training centers, and ward-level economic interventions.

---

## 2. Locked Decision Log (Phase 3)

| ID | Decision Item | Selected Option | Status | Rationale |
|---|---|---|:---:|---|
| **A-D01** | Stack & Architecture | **React 19 + TypeScript + Vite + Tailwind CSS + Lucide Icons + Leaflet/OpenStreetMap** | 🔒 LOCKED | React + Vite delivers instantaneous loading, pixel-perfect design fidelity, and native Leaflet performance without proprietary map billing keys. |
| **A-D02** | Visual Theme & Identity | **Civic Command Center** (`#0F172A` Deep Navy, `#F8FAFC` Clean Canvas, `#047857` Institutional Emerald) | 🔒 LOCKED | High data density, authoritative municipal portal identity, high contrast tabular grids. Distinct from touch-first mobile apps. |
| **A-D03** | Viewport & Layout | **Desktop Landscape (1440×900 baseline, responsive to 1024px)** | 🔒 LOCKED | Control room layout with persistent 256px civic sidebar, top telemetry bar, and multi-pane workspace drawers. |
| **A-D04** | Core Screen Architecture | **5 Coordinated Civic Portals (A-01 to A-05)** | 🔒 LOCKED | Covers full municipal lifecycle: Command KPIs, Spatial Fleet, Worker KYC, Orders & Disputes, Price Ceilings & Demand Heatmap. |
| **A-D05** | Live Telemetry & Data Sync | **FastAPI Admin Router + Supabase Realtime Channels (5s Polling Fallback)** | 🔒 LOCKED | Admin observes the same single source of truth (`public:orders`, `worker_profiles`) shared by both Customer and Worker APKs. |
| **A-D06** | Historical Demand Heatmap | **Historical Order Lat/Lng Aggregation $\rightarrow$ GeoJSON Density Layer** | 🔒 LOCKED | Transparent spatial aggregation without overpromising unseeded municipal boundary polygons or unbuilt ML forecasting. |
| **A-D07** | Transparent Demo KYC Badging | **Explicit "DEMO VERIFICATION (SIMULATED GOVERNMENT INTEGRATION)" Banner** | 🔒 LOCKED | Preserves academic/hackathon integrity; displays "Face Match: ✓ Demo Passed" rather than fabricated 99.9% statistical claims. |
| **A-D08** | Sandbox Dispute Financials | **"Release Worker Payout (Demo)" / "Simulate Refund (Test Mode)"** | 🔒 LOCKED | Accurately models administrative dispute redressal while reflecting that payments operate in Razorpay Test Mode without production escrow rails. |

---

## 3. Design Tokens & Visual Hierarchy (Gate A-02)

### 3.1 Color Roles (Civic Command Palette)
* **Command Navy (Dominant Authority & Header/Nav):**
  * Sidebar & Brand Header: `#0F172A` (Slate 900)
  * Secondary Surface / Nav Active: `#1E293B` (Slate 800)
  * Civic Blue Accent: `#1E40AF` (Blue 800 — Official State Seal Blue)
  * Structural Border: `#E2E8F0` (Slate 200)
* **Canvas & Surface System:**
  * Application Canvas: `#F8FAFC` (Slate 50 — low eye strain for 8-hour operator shifts)
  * Card Surfaces: `#FFFFFF` (Pure White with 1px border `#E2E8F0`, subtle shadow `0 1px 3px rgba(0,0,0,0.05)`)
  * Table Hover / Striping: `#F1F5F9` (Slate 100)
* **Civic Operational Status System:**
  * **Verified / Operational Emerald:** `#059669` (Emerald 600, surface `#ECFDF5`, border `#A7F3D0`)
  * **Urgent / In-Flight Saffron:** `#D97706` (Amber 600, surface `#FEF3C7`, border `#FDE68A`)
  * **Disputed / Critical Crimson:** `#DC2626` (Red 600, surface `#FEE2E2`, border `#FECACA`)
  * **Neutral / Inactive Slate:** `#64748B` (Slate 500, surface `#F1F5F9`, border `#CBD5E1`)
  * **Interactive Focus Indigo:** `#4F46E5` (Indigo 600 — for active inputs, primary CTA focus)

### 3.2 Typography Scale (`Plus Jakarta Sans` / `Inter`)
All numeric figures use tabular figures (`font-variant-numeric: tabular-nums`) to prevent alignment jitter during realtime updates:
* **Page Title / Hero Header:** 24px / 32px Bold (`font-weight: 700`, `letter-spacing: -0.02em`)
* **KPI Metric Figure:** 28px / 36px ExtraBold (`tabular-nums`, `#0F172A`)
* **Section Header:** 16px / 22px SemiBold (`font-weight: 600`, `#1E293B`)
* **Table Header:** 11px / 16px Bold Uppercase (`letter-spacing: 0.06em`, `#64748B`)
* **Table Body / Data Cell:** 13px / 20px Regular (`#0F172A`)
* **Micro-Data / Timestamps / IDs:** 11px / 14px Mono (`ui-monospace, monospace`, `#64748B`)
* **Status Badges / Chips:** 11px / 16px SemiBold (`letter-spacing: 0.03em`)

### 3.3 Elevation, Borders & Geometry
* **Border Radius:**
  * System Cards & Panels: `12px` (`rounded-xl`)
  * Buttons & Form Controls: `8px` (`rounded-lg`)
  * Status Pills & Badges: `9999px` (`rounded-full`)
* **Card Elevation:** Flat with crisp 1px border (`border border-slate-200 shadow-sm`)
* **Modal / Drawer Overlay:** Dark backdrop (`bg-slate-900/60 backdrop-blur-sm`) with slide-in 480px or 600px drawer.

---

## 4. Component Library & Semantic Rules (Gate A-03)

### 4.1 Master Civic Navigation Bar (`CivicSidebar`)
* Width: `256px` fixed left.
* Header: Tamil Nadu State Seal emblem + **MakkalSevai Civic Authority Portal** + Smart City Chennai badge.
* Navigation Items:
  1. `Command Center` (LayoutDashboard icon)
  2. `Spatial Fleet Map` (MapPin icon)
  3. `Worker Verification` (ShieldCheck icon) — with red pending counter badge `[ 1 ]`
  4. `Orders & Disputes` (FileText icon) — with amber dispute badge `[ 1 ]`
  5. `Price & Demand Heatmap` (TrendingUp icon)
* Bottom Section: Live system latency indicator (`🟢 API 22ms | ⚡ Realtime Connected`) + Logged in officer avatar ("Inspector S. Meenakshi, Zonal Officer").

### 4.2 High-Density KPI Stat Tile (`KpiStatCard`)
* Visual Anatomy:
  * Icon container (Emerald/Amber/Navy tint)
  * Metric Label (uppercase, 11px, Slate 500)
  * Primary Numeric Value (28px Bold, tabular figures)
  * Secondary Subtitle / Context (e.g., *"₹25 platform fee fixed"* or *"+12% vs yesterday"*)
  * Status indicator dot (pulsing green if live stream active)

### 4.3 Interactive Leaflet Map Shell (`SpatialFleetMap`)
* 100% full-height container with OpenStreetMap vector tiles.
* Custom SVG Markers:
  * 🟢 **Available Worker:** Green pin with pulse radar animation (Rajesh Kumar).
  * 🟡 **Enroute Worker:** Amber pin connected by dotted directional polyline to customer pin.
  * 🔵 **In-Progress Work:** Blue tools icon anchored at customer house.
  * 🔴 **Pending Request:** Pulsing red target pin.
* Left Filter Floating Bar: Toggle Trades (`All`, `Electrician`, `Plumber`, `Carpenter`) + Status (`All`, `Available`, `Active`, `Offline`).
* Right Telemetry Drawer (`WorkerTelemetryDrawer`): Slides in when a worker pin is clicked. Displays live speed, battery %, current order ID, customer ETA, and call worker button.

### 4.4 Split-Screen KYC Verification Inspector (`KycInspectorDrawer`)
* **Header Banner:** Prominent high-contrast alert badge:
  `⚠️ DEMO VERIFICATION (SIMULATED GOVERNMENT INTEGRATION) — Sandbox Environment`
* **Left Column (Document Preview):**
  * Tab 1: DigiLocker Aadhaar e-KYC Card (Name: Rajesh Kumar, DOB: 14/08/1988, Gender: Male, Address: T. Nagar).
  * Tab 2: e-Shram Registration UAN Certificate (UAN-TN-2026-88392, Skill: Electrical Domestic Wiring).
  * Tab 3: Onboarding Live Selfie.
* **Right Column (Algorithmic Verification Result):**
  * Name & Identity Match: `✓ Matched (DigiLocker)`
  * e-Shram UAN Status: `✓ Active & Registered (Govt Database)`
  * Biometric Face Match: `✓ Demo Passed (Simulation)`
  * Self-Declared Experience: `3.2 Years • 142 Prior Jobs`
* **Action Footer:**
  * Emerald CTA: **[ APPROVE & ISSUE SKILL PASSPORT ]**
  * Crimson Outline: **[ REJECT WITH REASON ]** (with dropdown: *"Incomplete ID / Blur Image / Mismatched Skill"*)

### 4.5 Order Registry & Dispute Arbitration Console (`DisputeArbitrationModal`)
* Order Header: `#ORD-2026-0891` | Electrician Service | T. Nagar
* Parties: Citizen **Senthil Nathan** (4.9⭐) $\leftrightarrow$ Worker **Rajesh Kumar** (4.9⭐)
* Order Financials: Gross ₹275.00 | Civic Platform Fee ₹25.00 | Worker Take-Home ₹250.00
* Complaint Summary: Citizen reported: *"Switchboard spark resolved in 10 mins, felt price was full hour rate"*.
* Worker Proof: Completion photo uploaded showing replaced burned MCB circuit breaker.
* Transparent Arbitration CTAs:
  * **[ Release Worker Payout (Demo) ]** — Credits ₹250 to worker, closes ticket.
  * **[ Simulate Refund (Test Mode) ]** — Returns ₹275 to customer, logs warning.
  * **[ Split Resolution (50/50) ]** — Payout ₹125, Refund ₹125.

### 4.6 Civic Price Governance & Demand Density Heatmap Card (`DemandHeatmapCard`)
* **Left Column (Municipal Price Ceilings):**
  * Table of 6 regulated trades with Government Price Cap (e.g. Electrician ₹350, Plumber ₹350, AC Tech ₹450).
  * Current Average Platform Rate (e.g. ₹275).
  * Zero-Surge Enforcement Badge (`🔒 Algorithmic Surge Locked at 0%`).
* **Right Column (Historical Demand Density):**
  * Leaflet density layer showing clustered service requests across Chennai coordinates.
  * Historical Platform Analytics Insight Box:
    *"Platform Data Analytics: High electrician booking density in T. Nagar cluster (34 requests/day). Suggests target zone for municipal vocational training cohort."*

---

## 5. Screen Layout Compositions (Gate A-04)

### Screen A-01: Operations Command Center
```
┌─────────────────────────────────────────────────────────────────────────────┐
│ 🏛️ MAKKALSEVAI CIVIC PORTAL   [T. Nagar Zonal Command]   🟢 LIVE: 22ms  🔔 │
├──────────┬──────────────────────────────────────────────────────────────────┤
│          │ [KPIs]                                                           │
│  Command │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────────┐ │
│  Center  │  │ ACTIVE  │ │ ONLINE  │ │VERIFIED │ │TODAY GMV│ │OPEN DISPUTE│ │
│          │  │  14     │ │   42    │ │  189    │ │ ₹14,250 │ │   1 (Demo)  │ │
│  Fleet   │  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────────┘ │
│  Map     │                                                                  │
│          │ ┌──────────────────────────────┬───────────────────────────────┐ │
│  Worker  │ │ LIVE DISPATCH ACTIVITY (STREAM)│ ZONE CAPACITY BREAKDOWN       │ │
│  KYC [1] │ │ • Rajesh Kumar accepted #0891│ • T. Nagar: 88% capacity      │ │
│          │ │ • Manikandan completed #0889 │ • Mylapore: 65% capacity      │ │
│  Orders  │ │ • Arumugam enroute #0890     │ • Anna Nagar: 72% capacity    │ │
│  & [1]   │ ├──────────────────────────────┼───────────────────────────────┤ │
│  Disputes│ │ RECENT ORDERS AUDIT          │ CIVIC PRICE CEILING MONITOR   │ │
│          │ │ #0891 | Electrician | ₹275   │ Electrician: ₹275 (Cap: ₹350) │ │
│  Price & │ │ #0890 | Plumber     | ₹320   │ Plumber:     ₹320 (Cap: ₹380) │ │
│  Demand  │ │ #0889 | Carpenter   | ₹400   │ Fixed Fee:   ₹25 (Enforced)   │ │
│          │ └──────────────────────────────┴───────────────────────────────┘ │
└──────────┴──────────────────────────────────────────────────────────────────┘
```

### Screen A-02: Live Spatial Operations & Fleet Map
```
┌─────────────────────────────────────────────────────────────────────────────┐
│ 🏛️ MAKKALSEVAI CIVIC PORTAL   [Live Spatial Fleet Tracking] 🟢 REALTIME     │
├──────────┬───────────┬──────────────────────────────────┬───────────────────┤
│          │ FILTERS   │                                  │ WORKER TELEMETRY  │
│  Command │           │       CHENNAI SPATIAL MAP        │                   │
│  Center  │ Trades:   │                                  │ Rajesh Kumar      │
│          │ [x] Elec  │      🟢 Rajesh (Available)       │ Sr. Electrician   │
│  Fleet   │ [x] Plumb │         \                        │ ⭐ 4.9 (142 jobs) │
│  Map [•] │ [x] Carp  │          \ (Dashed Path)         │ Speed: 18 km/h    │
│          │           │           🟡 Manikandan (Enroute)│ Battery: 88%      │
│  Worker  │ Status:   │            \                     │ Active Job: #0891 │
│  KYC [1] │ [x] Online│             🏠 Senthil (Customer)│ Customer: Senthil │
│          │ [x] Busy  │                                  │ ETA: 4 mins       │
│  Orders  │ [ ] Off   │         🔵 Murugan (In-Progress) │ [CALL WORKER]     │
│          │           │                                  │ [VIEW ORDER]      │
└──────────┴───────────┴──────────────────────────────────┴───────────────────┘
```

### Screen A-03: Worker KYC & Credential Verification Queue
```
┌─────────────────────────────────────────────────────────────────────────────┐
│ 🏛️ MAKKALSEVAI CIVIC PORTAL   [Worker Onboarding & KYC Queue]  ⚠️ SANDBOX   │
├──────────┬──────────────────────────────────────────────────────────────────┤
│          │ ⚠️ DEMO VERIFICATION (SIMULATED GOVERNMENT INTEGRATION)          │
│  Command ├──────────────────────────────┬───────────────────────────────────┤
│  Center  │ SUBMITTED CREDENTIALS        │ AUTOMATED VERIFICATION AUDIT      │
│          │ Worker: Rajesh Kumar         │                                   │
│  Fleet   │ Trade:  Electrician          │ 1. DigiLocker Aadhaar e-KYC       │
│  Map     │ Phone:  +91 98765 43211      │    Name: Rajesh Kumar (✓ Match)   │
│          │                              │    Address: T. Nagar, Chennai     │
│  Worker  │ [ Aadhaar Preview (Front) ]  │                                   │
│  KYC [1] │ [ e-Shram Card Preview    ]  │ 2. e-Shram Registry Verification  │
│          │ [ Live Selfie Capture     ]  │    UAN: TN-2026-88392 (✓ Active)  │
│  Orders  │                              │                                   │
│  &       │                              │ 3. Biometric Facial Matching      │
│  Disputes│                              │    Face Match: ✓ Demo Passed      │
│          │                              │                                   │
│  Price & │                              │ 4. Trade Certification            │
│  Demand  │                              │    NSDC Electrician Level 4       │
│          │                              ├───────────────────────────────────┤
│          │                              │ [ APPROVE & ISSUE SKILL PASSPORT ]│
│          │                              │ [ REJECT WITH REASON            ] │
└──────────┴──────────────────────────────┴───────────────────────────────────┘
```

### Screen A-04: Order Registry & Dispute Arbitration Console
```
┌─────────────────────────────────────────────────────────────────────────────┐
│ 🏛️ MAKKALSEVAI CIVIC PORTAL   [Order Registry & Dispute Arbitration]        │
├──────────┬──────────────────────────────────────────────────────────────────┤
│          │ Tabs: [All Orders (142)] [In Progress (3)] [⚠️ Disputed (1)]     │
│  Command ├──────────────────────────────────────────────────────────────────┤
│  Center  │ ORDER DISPUTE INSPECTION DRAWER: #ORD-2026-0891                  │
│          │ Customer: Senthil Nathan (T. Nagar) | Worker: Rajesh Kumar       │
│  Fleet   │ Service: Electrician (Wiring Repair) | Amount: ₹275.00           │
│  Map     ├──────────────────────────────┬───────────────────────────────────┤
│          │ CITIZEN GRIEVANCE STATEMENT  │ WORKER COMPLETION EVIDENCE        │
│  Worker  │ "Technician arrived promptly │ "Burned MCB switchboard replaced. │
│  KYC     │ but job took 10 mins. Felt   │ Tested load and safety trip.      │
│          │ standard ₹275 rate was high."│ New copper wiring installed."     │
│  Orders  │                              │ [ Photo: Replaced MCB Panel.jpg ] │
│  & [1]   ├──────────────────────────────┴───────────────────────────────────┤
│  Disputes│ ARBITRATION ACTIONS (TEST MODE)                                  │
│          │ [ Release Worker Payout (Demo) - ₹250.00 ]                       │
│  Price & │ [ Simulate Refund (Test Mode) - ₹275.00 ]                        │
│  Demand  │ [ 50/50 Compromise Resolution - ₹125.00 / ₹125.00 ]              │
└──────────┴──────────────────────────────────────────────────────────────────┘
```

### Screen A-05: Civic Price Ceilings & Demand Density Heatmap
```
┌─────────────────────────────────────────────────────────────────────────────┐
│ 🏛️ MAKKALSEVAI CIVIC PORTAL   [Price Governance & Demand Intelligence]      │
├──────────┬──────────────────────────────────────────────────────────────────┤
│          │ ┌──────────────────────────────┬───────────────────────────────┐ │
│  Command │ │ MUNICIPAL PRICE CEILINGS     │ DEMAND DENSITY HEATMAP        │ │
│  Center  │ │ Trade      | Cap  | Mkt Avg  │ (Historical Order Density)    │ │
│          │ │ Electrician| ₹350 | ₹275 ✓   │                               │ │
│  Fleet   │ │ Plumber    | ₹380 | ₹320 ✓   │      [ CHENNAI HEATMAP ]      │ │
│  Map     │ │ Carpenter  | ₹450 | ₹400 ✓   │      🔴 High (T. Nagar)       │ │
│          │ │ AC Repair  | ₹550 | ₹480 ✓   │      🟡 Med (Mylapore)        │ │
│  Worker  │ │                              │      🟢 Low (Adyar)           │ │
│  KYC     │ │ Commission Ceiling: Fixed ₹25│                               │ │
│          │ │ Surge Pricing: LOCKED (0.0x) │                               │ │
│  Orders  │ ├──────────────────────────────┴───────────────────────────────┤ │
│          │ │ 📊 PLATFORM HISTORICAL DATA INFERENCE                        │ │
│  Price & │ │ "Platform Data Analytics: High electrician booking density   │ │
│  Demand  │ │ in T. Nagar cluster (34 req/day). Suggests target zone for   │ │
│  [•]     │ │ municipal vocational training cohort."                       │ │
│          │ │ [ DOWNLOAD MUNICIPAL AUDIT (PDF) ]  [ EXPORT AUDIT CSV ]     │ │
└──────────┴─┴──────────────────────────────────────────────────────────────┴─┘
```

---

## 6. Generated Stitch Screens & Project Artifacts (Gate A-05)

* **Stitch Project ID:** `projects/6260803450485502354`
* **Title:** `MakkalSevai - Admin & Civic Authority Dashboard`
* **Design System ID:** `assets/089b37594a944a298ec1d1527d999756` ("Civic Command")
* **Canvas Dimensions:** 1440×900 Desktop Viewport

| Screen ID | Title | Screen Name & Role | Stitch Screen ID | Status |
|:---|:---|:---|:---|:---:|
| **A-01** | `MakkalSevai Command Center` | `admin_command_center` (Executive Municipal Overview & 6 KPIs) | `e97525664e604e9981fe884f701baf7b` | ✅ Generated |
| **A-02** | `Live Spatial Fleet Map` | `admin_spatial_fleet_map` (OpenStreetMap Telemetry & Live Drawer) | `88007c5e6e59486582c84e84334ad43b` | ✅ Generated |
| **A-03** | `Worker KYC Verification Queue` | `admin_worker_kyc_queue` (Sandboxed DigiLocker/e-Shram Audit) | `db52bfdc65a24c3eb74cd47163295b95` | ✅ Generated |
| **A-04** | `Orders Registry & Dispute Arbitration` | `admin_orders_and_disputes` (60/40 Split Dispute Drawer & Test Mode Actions) | `ee95cb04c1134af996eb902544e841ab` | ✅ Generated |
| **A-05** | `Price Caps & Demand Intelligence Heatmap` | `admin_price_and_demand_heatmap` (Price Caps & Historical Geo Clustering) | `47f0f6fee6b949488cb1271d694f3635` | ✅ Generated |

---

## 7. Next Steps: Frontend & Backend Implementation
1. **Frontend Scaffolding (`admin-dashboard/`):** React 19, TypeScript, Vite, Tailwind CSS, Lucide icons, Leaflet, and React-Leaflet.
2. **Backend Admin Router (`backend/app/api/v1/admin.py`):** Add endpoints for `/kpis`, `/workers/telemetry`, `/kyc/queue`, `/disputes`, and `/analytics/heatmap`.
3. **End-to-End Rehearsal:** Run simultaneous 3-window validation (Customer APK $\leftrightarrow$ Worker APK $\leftrightarrow$ Admin Dashboard).

