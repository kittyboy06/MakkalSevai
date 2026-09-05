# MakkalSevai — Worker Mobile App Design Specification
### SIH 2026 · PS26089 · Core Demo Experience

---

## 1. Executive Summary & Worker Purpose
The **MakkalSevai Worker App** is the supply-side engine of the marketplace. It equips local tradespeople (electricians, plumbers, carpenters, painters, masons, and technicians) with an authoritative, frictionless tool to manage their daily gig workflow:
1. Authenticate and demonstrate verified trade credentials via simulated DigiLocker and e-Shram integrations.
2. Control availability with a single, high-contrast **Online / Offline** toggle.
3. Receive and evaluate incoming nearby job offers with a transparent 30-second decision timer.
4. Execute jobs through real-time state machine progression (`accepted` $\rightarrow$ `worker_enroute` $\rightarrow$ `in_progress` $\rightarrow$ `completed`).
5. Track immediate wallet earnings and continuously build a tamper-evident **Digital Skill Passport**.

---

## 2. Decision Log

| ID | Decision Item | Selected Option | Alternatives Considered | Rationale |
|---|---|---|---|---|
| **W-D01** | Scope of Phase 2 | Dedicated Worker Android APK (`worker-app`) | Unified single hybrid APK, Web app | Native APK allows clean dual-phone demonstration (Customer Phone 1 $\leftrightarrow$ Worker Phone 2). |
| **W-D02** | Visual Theme Family | Modern Civic Trust (Worker Edition) | High-vis yellow utility, Harsh dark mode | Preserves product family coherence with Customer App while adapting for outdoor contrast and sunlight. |
| **W-D03** | Ergonomic Architecture | One-Thumb Bottom-Weighted Layout (Min 56px Targets) | Standard 44px touch targets, Multi-level menus | Workers frequently operate one-handed beside vehicles or worksites with gloves or dust. |
| **W-D04** | Core Demo Screens | 5 Coordinated Screen States (W-01 to W-05) | 12-screen comprehensive app | Exactly maps the Section 19 SIH end-to-end demo lifecycle matching Rajesh Kumar's journey. |
| **W-D05** | Credential Transparency | Explicit "Demo Verification Flow" Badges | Official government seals, Unmarked mocks | Clear academic and hackathon compliance: explicitly simulated sandbox without misrepresentation. |
| **W-D06** | Data Authority | Direct API & DB State Binding | Hardcoded static mocks | Ensures live updates: Customer order creation triggers Worker incoming alert; completion increments live DB passport. |

---

## 3. Design Tokens & Visual Hierarchy (Worker Adaptations)

### 3.1 Color Roles (Calibrated for Direct Sunlight)
* **Canvas & Surfaces:**
  * Base Background: `#F8FAFC` (Slate 50 — reduces high-glare reflection)
  * Elevated Cards: `#FFFFFF` (Pure White with 1.5px high-contrast `#CBD5E1` border)
  * Tactical Container: `#0F172A` (Slate Navy 900 — used for dominant state buttons and night mode)
* **Status & Work Availability:**
  * **Online / Active Emerald:** `#10B981` (Background: `#ECFDF5`, Border: `#059669`, Text: `#065F46`)
  * **Offline / Inactive Slate:** `#64748B` (Background: `#F1F5F9`, Border: `#CBD5E1`)
* **Urgency & Dispatch Action:**
  * **Warm Saffron:** `#F59E0B` (Timer ring, incoming offer badge, warning cues)
* **Earnings & Metrics:**
  * **Positive Cashflow:** `#059669` (Wallet credits, job payouts)
* **Alert & Decline:**
  * **Restrained Crimson:** `#EF4444` (Job decline, cancellations)

### 3.2 Outdoor Ergonomics & Typography Scale (`Plus Jakarta Sans`)
All font sizes are scaled up by +1 to +2px relative to consumer apps for instant legibility at arm’s length:
* **Display / Big Currency:** 32px / 38px Bold (`letter-spacing: -0.02em`)
* **Headline-Large (Status / Customer):** 22px / 28px Bold
* **Headline-Medium (Service / Address):** 17px / 24px SemiBold
* **Body-Primary (Instructions / Details):** 15px / 22px Medium
* **Body-Secondary (Tamil Subtitles):** 13px / 18px Regular
* **Meta / Label-Caps (Badges / UAN):** 12px / 16px Bold (`letter-spacing: 0.05em`)

### 3.3 Touch Target & Thumb-Zone Rules
* **Minimum Primary Touch Height:** `56px` (e.g. "ACCEPT JOB", "START WORK", "GO ONLINE").
* **Thumb Zone Rule:** All critical action triggers reside within the lower 40% of the viewport.
* **Border Radius:**
  * Primary Action Buttons: `14px` (`rounded-xl`)
  * Data Metric Cards: `16px` (`rounded-2xl`)
  * Availability Toggle Pill: `9999px` (`rounded-full`)

---

## 4. Component System & Semantic Rules

### 4.1 Master Availability Switch (Hero Component)
* **Online State:** Full-width emerald bar with pulsing radar dot: `🟢 ONLINE • Receiving nearby jobs in T. Nagar`.
* **Offline State:** Muted slate bar: `⚪ OFFLINE • Slide to receive service requests`.

### 4.2 30-Second Incoming Offer Modal (Urgency Component)
* Floating modal anchored to bottom with animated circular countdown ring.
* Clear visual hierarchy:
  1. Service Name + Tamil: **Electrician** / **மின்சார பணியாளர்**
  2. Customer Info: **Senthil Nathan** (4.9⭐ Citizen)
  3. Spatial Context: **1.8 km** away (T. Nagar)
  4. Problem snippet: *"Switchboard sparking in living room"*
  5. Transparent Financials: **Your Payout: ₹250.00** (Job Total: ₹275.00, Platform: ₹25.00)
  6. Two-Button Action: Large Emerald **ACCEPT (₹250)** vs Muted Outline **DECLINE**.

### 4.3 Active Job Progression Action Bar
* Authoritative state transition button replacing standard map navigation:
  * If status = `accepted` $\rightarrow$ Button: **"Mark Enroute to Customer"**
  * If status = `worker_enroute` $\rightarrow$ Button: **"Arrived at Location"**
  * If status = `arrived` $\rightarrow$ Button: **"Start Job Inspection"**
  * If status = `in_progress` $\rightarrow$ Button: **"Complete Job & Generate Invoice"**

### 4.4 Digital Skill Passport Snippet
* Micro-card displaying the 4 core credentials:
  * ⭐ **4.9** Rating
  * 🛡️ **98%** Reliability
  * ⚡ **142** Completed Jobs
  * ⏳ **3.2 Yrs** Experience
  * Shield: **e-Shram UAN-TN-2026-88392**

---

## 5. Screen Layout Specifications (W-01 to W-05)

### Screen W-01: Worker Home & Online Dashboard
* **Header:** Worker avatar ("RK"), Name: Rajesh Kumar, Rating: 4.9⭐, Skill: Senior Electrician.
* **Hero Toggle:** Master Availability Switch (Online / Offline).
* **Today's Earnings Summary Card:**
  * Large display: **₹1,250.00**
  * Sub-metrics: **4 Jobs Completed** • **5.2 hrs online**
* **Digital Skill Passport Quick Access:** Compact credential card with verified UAN badge.
* **Recent Activity Feed:** Mini-list of today's completed jobs.
* **Bottom Nav:** Dashboard, My Jobs, Wallet, Profile.

### Screen W-02: Demo Verification Flow (KYC & Trust)
* **Header:** "Tradesperson Identity Verification", labeled with banner: `DEMO VERIFICATION FLOW (SIMULATED)`.
* **Verification Cards:**
  * **DigiLocker Aadhaar Verification:** Status: `✓ SIMULATED MATCH` (Masked Aadhaar: `XXXX-XXXX-8839`).
  * **e-Shram National Worker Database:** Status: `✓ REGISTERED` (UAN: `UAN-TN-2026-88392`, Category: Electrical & Maintenance).
  * **Face Liveness & Photo Match:** Status: `✓ PASSED (99.4% Match)`.
* **Verified Benefits Card:** "Eligible for 5km auto-dispatch + Instant UPI direct wallet deposits".
* **Primary Action:** `Verified & Ready to Work (56px Button)`.

### Screen W-03: Incoming Job Offer Alert (Dispatch Radar)
* **Full-screen Dispatch Alert:** Radial pulse animation with vibrating alert cue.
* **Top Urgency Bar:** Circular 30s countdown timer (`28s remaining`).
* **Service Details:** Electrician (மின்சார பணியாளர்) • Flat diagnostic visit.
* **Customer Card:** Senthil Nathan • Flat 4B, Shanti Nilayam, 12th Cross St, T. Nagar.
* **Issue Description:** *"Switchboard sparking in living room when ceiling fan is turned on"*.
* **Earnings Breakdown Card:**
  * **Your Net Payout:** **₹250.00**
  * Customer Total: ₹275.00 (includes ₹25 civic platform fee).
* **Action Buttons:**
  * Emerald Button (Height 56px): **ACCEPT JOB (₹250.00)**
  * Outline Button: **Decline Offer**

### Screen W-04: Active Job & Navigation
* **Top Header:** Customer Name (Senthil Nathan), Address preview, One-tap Call button.
* **Interactive Map:** Route from worker location (`13.0450, 80.2380`) to customer location (`13.0418, 80.2341`).
* **Turn-by-turn Instruction Bar:** `Turn left on 12th Cross St • 400m`.
* **Bottom Sliding Sheet:**
  * Problem notes & customer phone (`+919876543210`).
  * Big Dominant State CTA (56px): **"I Have Arrived at Location"** $\rightarrow$ **"Start Electrical Work"**.

### Screen W-05: Job Completion & Earnings Payout
* **Success Banner:** Emerald checkmark with "Job Completed Successfully".
* **Payout Credit Card:**
  * Large display: **+₹250.00**
  * Status: `Transferred to Worker Wallet • Instant Settlement`
  * Razorpay Test Order: `order_test_992138` (Paid by customer via UPI).
* **Customer Review Snippet:**
  * ⭐⭐⭐⭐⭐ (5.0)
  * *"Rajesh did a very neat job fixing the sparking switchboard safely. Highly recommended!"*
* **Updated Digital Skill Passport:**
  * Completed Jobs: **142 $\rightarrow$ 143**
  * Rating: **4.9⭐ (143 reviews)**
  * Reliability: **98%**
* **Primary CTA:** **"Back to Online Radar (Ready for Next Job)"**.
