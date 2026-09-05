# MakkalSevai — Admin & Civic Authority Dashboard Design Specification
### SIH 2026 · PS26089 · Civic Oversight & Operations Platform

---

## 1. Executive Summary & Civic Purpose

The **MakkalSevai Admin & Civic Authority Dashboard** is the command center and regulatory governance platform for municipal authorities, smart city administrators, and platform operations directors.

While the **Customer App** prioritizes effortless booking and transparent trust, and the **Worker App** prioritizes sunlight legibility and rapid one-thumb task execution, the **Admin Dashboard** operates with a distinct mandate:
1. **Public Sector Accountability:** Enforce fair civic price ceilings, monitor platform commissions (fixed ₹25), and ensure no exploitation of informal gig workers.
2. **Real-Time Spatial Governance:** Maintain an unblinking, live operational overview of city-wide trade supply, ongoing dispatches, and emergency escalations across Chennai zones (starting with T. Nagar).
3. **Institutional Worker Onboarding:** Provide human-in-the-loop verification for unorganized trade workers submitting Aadhaar, e-Shram, and Skill India credentials before they enter the algorithmic dispatch pool.
4. **Dispute Arbitration:** Offer evidence-grounded grievance redressal with one-click financial resolution (holding escrows, worker payout release, or customer refund).
5. **Civic Demand Intelligence:** Aggregated historical heatmaps to inform municipal skill development programs, trade training centers, and ward-level economic interventions.

---

## 2. Decision Log (Phase 3)

| ID | Decision Item | Selected Option | Alternatives Considered | Rationale |
|---|---|---|---|---|
| **A-D01** | Stack & Architecture | Web Single Page App (React 19 + TypeScript + Vite + Tailwind CSS + Lucide Icons) | Flutter Web, Python Streamlit, Retool | React + Vite offers instantaneous loading, pixel-perfect Stitch design fidelity, and native Leaflet/OpenStreetMap performance without heavy runtime bloat. |
| **A-D02** | Visual Theme & Identity | **Civic Command Center** (`#091E42` Deep Navy, `#F8FAFC` Clean Canvas, `#047857` Institutional Emerald) | Generic Dark Mode hacker console, Material UI default | Conveys authoritative municipal governance, modern smart-city polish, and accessible high-density data legibility for administrative staff. |
| **A-D03** | Viewport & Ergonomics | Desktop First (1440×900 baseline, responsive down to 1024px) | Mobile responsive first | Civic operators operate on widescreen dual-monitor control desks requiring dense split-screen map & tabular layouts. |
| **A-D04** | Core Screen Architecture | 5 Specialized Civic Portals (A-01 to A-05) | Monolithic multi-tab single page | Matches the modular operational workflows of city officers (Command, Dispatch Map, KYC Approval, Disputes, Price & Demand Governance). |
| **A-D05** | Live Telemetry & Dispatch | Supabase Realtime WebSocket events + 5s Polling Fallback | Socket.IO, Polling only | Shares the exact Supabase backend subscription channels utilized by Customer and Worker apps for zero-latency synchronization. |
| **A-D06** | Verification Workflow | Split-Pane KYC Audit (Original document preview + extracted OCR + Face match confidence) | Automated blind approval | Smart India Hackathon civic integrity requires verifiable oversight before activating workers on public portals. |
| **A-D07** | Demand Heatmap Engine | Leaflet.js + PostGIS GeoJSON Aggregation | Heavy ML raster layers, Google Maps proprietary API | 100% open-source, reproducible in offline hackathon environments, free from API billing rate limits. |
| **A-D08** | Dispute Redressal Power | Two-Party Audit Trail with Direct Razorpay/Escrow Trigger | Read-only ticket system | Gives municipal arbiters executive actionability to resolve real-world conflicts between citizens and tradespeople. |

---

## 3. Design Tokens & Visual Hierarchy

### 3.1 Color Roles (Civic Command Palette)
* **Command Navy (Dominant Authority & Header/Nav):**
  * Primary Header: `#0F172A` (Slate 900)
  * Deep Accent / Brand: `#1E3A8A` (Blue 900 — Government Portal Seal)
  * Secondary Border: `#E2E8F0` (Slate 200)
* **Canvas & Surface System:**
  * Application Canvas: `#F8FAFC` (Slate 50 — clean, low fatigue)
  * Card Surfaces: `#FFFFFF` (Pure White, 1px border `#E2E8F0`, subtle shadow `0 1px 3px rgba(0,0,0,0.05)`)
  * Table Zebra / Hover: `#F1F5F9` (Slate 100)
* **Institutional Status System:**
  * **Verified / Operational Emerald:** `#059669` (Emerald 600, badge `#ECFDF5`)
  * **Urgent / In-Flight Saffron:** `#D97706` (Amber 600, badge `#FEF3C7`)
  * **Disputed / Critical Crimson:** `#DC2626` (Red 600, badge `#FEE2E2`)
  * **Offline / Neutral Slate:** `#64748B` (Slate 500, badge `#F1F5F9`)

### 3.2 Typography Scale (`Plus Jakarta Sans` / `Inter`)
* **Page Title / Hero Metrics:** 28px / 36px Bold (`font-weight: 700`, `letter-spacing: -0.02em`)
* **KPI Large Numbers:** 24px / 32px Bold (`font-variant-numeric: tabular-nums`)
* **Section Headers:** 18px / 24px SemiBold (`font-weight: 600`)
* **Table Headers:** 11px / 16px Bold Uppercase (`letter-spacing: 0.05em`, `#64748B`)
* **Body / Cell Data:** 13px / 20px Regular (`#1E293B`)
* **Micro-Data / Timestamp / IDs:** 11px / 14px Mono (`font-family: ui-monospace, monospace`, `#64748B`)

---

## 4. Component System & Semantic Rules

### 4.1 Master Civic Navigation Bar
* Sticky left sidebar (width: `256px`) with government crest, Tamil Nadu Smart City emblem, active operator avatar, and 5 primary navigation routes.
* Quick-action status pills showing live system health: `🟢 Core API: Operational (24ms)` | `⚡ Realtime: Connected`.

### 4.2 High-Density KPI Stat Cards
* Grid of 6 authoritative metrics:
  1. **Active Jobs:** In-flight services right now in Chennai
  2. **Online Tradespeople:** Workers active & transmitting GPS
  3. **Verified Workforce:** Approved DigiLocker / e-Shram professionals
  4. **Today's Civic GMV:** Total transactions processed (with transparent ₹25 fee breakdown)
  5. **Completed Today:** Successfully resolved citizen requests
  6. **Open Grievances:** Pending municipal arbitration tickets

### 4.3 Interactive Leaflet Spatial Operations Map
* Embedded 100% vector OpenStreetMap viewport centered at Chennai (13.0418° N, 80.2341° E).
* Color-coded dynamic markers:
  * 🟢 **Available Worker** (Pulsing green ring, trade icon)
  * 🟡 **Enroute Worker** (Yellow dashed route line to customer location)
  * 🔵 **In-Progress Work** (Blue work gear icon at premises)
  * 🔴 **Pending Dispatch Order** (Amber radar beacon awaiting acceptance)
* Filter drawer to isolate trades: Electricians, Plumbers, Carpenters, Painters, Masons.

### 4.4 Split-Screen KYC Verification Inspector
* **Left Pane (50%):** Submitted document viewer (Aadhaar Card, e-Shram UAN Certificate, Live Selfie capture).
* **Right Pane (50%):** Algorithmic verification metrics:
  * OCR extracted Name, DOB, Address vs DigiLocker record.
  * Biometric Face Match Confidence: `96.4% Match` (Green progress bar).
  * Skill Self-Declaration vs Trade Certification.
  * Two decisive primary actions: **"Approve & Issue Skill Passport"** (Emerald) vs **"Reject / Request Re-upload"** (Crimson with reason dropdown).

### 4.5 Civic Price Ceiling & Fare Governance Matrix
* Dynamic regulation table showing:
  * Trade Category (e.g., Electrician - General Wiring)
  * **Municipal Price Ceiling:** Regulated maximum base fee (e.g., ₹350/hr)
  * **Current Market Average:** Live algorithmic rate (e.g., ₹275)
  * **Civic Margin Protection:** Ensuring worker takes home 90.9% (₹250) and platform commission never exceeds fixed ₹25.
  * Price Cap Edit & Enforcement trigger.

---

## 5. Screen Layout Specifications (A-01 to A-05)

### Screen A-01: Operations Command Center
* **Role:** Executive landing page giving municipal commissioners an instant 360° overview of urban service delivery.
* **Layout Structure:**
  * Top bar with Chennai Corporation branding, date/time, and emergency alert banner.
  * 6 Key Performance Metric cards with today vs yesterday deltas.
  * Main split grid:
    * Left (60%): Recent Live Transactions & Dispatches (realtime stream).
    * Right (40%): Civic Health Gauge, Zone Capacity Breakdown (T. Nagar, Mylapore, Anna Nagar, Adyar), and Active Category Distribution chart.

### Screen A-02: Live Spatial Operations & Fleet Map
* **Role:** Tactical control room map showing real-time distribution of tradespeople and service demands.
* **Layout Structure:**
  * Full-bleed interactive Leaflet / OpenStreetMap container with custom dark/light civic tiles.
  * Floating Left Control Card: Quick category toggles (Electrician, Plumber, etc.), Availability status filters (Online, Busy, Offline).
  * Floating Right Inspector Drawer: Clicking any worker or order marker slides open full real-time telemetry (Worker name, rating, phone, current speed, battery, assigned order, customer address, ETA).

### Screen A-03: Worker KYC & Credential Verification Queue
* **Role:** Regulatory gatekeeper dashboard where government verification officers audit and onboard informal workers.
* **Layout Structure:**
  * Top metrics: Pending Audits (e.g., 8), Approved Today (19), Average Audit Time (1.4m).
  * Worker queue list with risk badges (`Low Risk / Verified DigiLocker`, `Needs Review`).
  * Dedicated inspection card for **Rajesh Kumar** (Electrician):
    * Side-by-side comparison of Aadhaar ID photo vs Live Onboarding Selfie (`96.4% Facial Match`).
    * e-Shram UAN database lookup status (`Verified Active`).
    * Skill Certification (`National Skill Development Corporation - Level 4 Electrician`).
    * One-click "Approve & Activate Worker" button.

### Screen A-04: Order Registry & Dispute Arbitration Console
* **Role:** Transparent judicial & operational registry of every order created on MakkalSevai.
* **Layout Structure:**
  * Tabbed status filter: `All Orders`, `Matching`, `In Progress`, `Completed`, `Disputed (2)`.
  * Comprehensive table: Order ID, Timestamp, Customer Name, Assigned Worker, Trade, Total Amount (₹), Status Pill, Actions.
  * Dispute Detail Modal:
    * Customer claim: *"Work took 15 minutes, charged standard rate"* vs Worker note: *"Replaced burned out MCB switchboard"*.
    * Timestamped photo evidence uploaded by worker upon completion.
    * Arbitration actions: **Release ₹250 to Worker** | **Refund ₹275 to Customer** | **50/50 Compromise Settlement**.

### Screen A-05: Civic Price Ceilings & Demand Heatmap
* **Role:** Policy and economic planning portal preventing algorithmic surge gouging and planning vocational training centers.
* **Layout Structure:**
  * Top Half: **Civic Fair Price Cap Matrix**:
    * Regulated ceiling rules by trade category.
    * Transparent platform fee cap tracker (Strict ₹25 ceiling, 0% surge pricing).
  * Bottom Half: **Urban Trade Density Heatmap**:
    * Spatial concentration of unmet electrician and plumbing requests across Chennai wards.
    * Policy recommendation box: *"Ward 114 (T. Nagar West) shows 34% unfilled carpentry demand between 10 AM – 2 PM. Recommend establishing local vocational upskilling drive."*
    * Exportable official report buttons (`Download Municipal Audit PDF`, `Export CSV`).

---

## 6. Verification & Implementation Roadmap
1. **Gate A-01 Approval:** Review and lock the architectural decisions, design tokens, and 5 screen compositions.
2. **Stitch Generation:** Generate the 5 desktop screens using Google Stitch MCP (`GEMINI_3_FLASH` model, 1440×900 desktop viewport).
3. **Frontend Implementation:** Scaffold `admin-dashboard/` with React 19, Vite, Tailwind CSS, Lucide icons, and Leaflet map integration.
4. **Backend Admin API:** Wire `/api/v1/admin/` endpoints in FastAPI connecting to PostGIS and Supabase tables.
5. **End-to-End Integration:** Validate simultaneous tripartite demo (Customer creates order $\rightarrow$ Admin map blinks $\rightarrow$ Worker accepts $\rightarrow$ Admin verifies $\rightarrow$ Job completes $\rightarrow$ Admin audits payout).
