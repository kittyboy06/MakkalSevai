# MakkalSevai — Customer Mobile App Design Specification
### SIH 2026 · PS26089 · Core Demo Experience

---

## 1. Executive Summary & Design Purpose
MakkalSevai is a trusted digital marketplace connecting verified local blue-collar workers with nearby citizens through skill/location matching, real-time tracking, digital payments, and a lifelong Digital Skill Passport.

This design specification defines the foundational 5-screen core flow for the **Customer Mobile App** designed in Google Stitch and architected for Flutter Android/iOS implementation.

---

## 2. Decision Log

| ID | Decision Item | Selected Option | Alternatives Considered | Rationale |
|---|---|---|---|---|
| **D-01** | Scope of Initial Batch | 5-Screen Customer Core Flow | Worker App first, Admin Dashboard first, All 12 screens | Directly proves the Section 19 SIH demo script end-to-end. |
| **D-02** | Visual Theme | Modern Civic & Trustworthy | Clean Consumer, Digital India Tricolor, Warm Community | Balances government credibility/trust with modern consumer app usability. |
| **D-03** | Interaction Pattern | Contextual Sheet & Map-Centric Flow | Full-Page Step Wizard, Super-App Tabbed Navigation | Delivers the best live demo experience and matches modern on-demand gig expectations. |
| **D-04** | Foundation Tokens | Slate/Navy Palette + Plus Jakarta Sans + Subtle Elevation | High-saturation themes, heavy drop shadows | Conveys civic trust, high contrast, and accessibility without bureaucratic heaviness. |
| **D-05** | Component System & Semantic Rules | Standardized civic component kit + 4-stage matching stepper & Skill Passport card | Fragmented per-screen styling | Ensures screens 1–5 look like an integrated product rather than disjointed mockups. |
| **D-06** | Screen Layout Specifications | 5 Coordinated Mobile Screen States (390×844) | Static multi-page wizard | Models continuous on-demand lifecycle matching backend order state machine. |

---

## 3. Design Tokens & Visual Hierarchy

### 3.1 Color Roles
* **Canvas / Surface:**
  * Base Background: `#F8FAFC` (Slate 50 — clean, neutral, reduces glare)
  * Surface Cards / Sheets: `#FFFFFF` (Pure White)
  * Sub-surface Containers: `#F1F5F9` (Slate 100 — inputs, chips, subtle backgrounds)
* **Authority & Content (Primary):**
  * Primary Text & Hero Buttons: `#0F172A` (Slate 900)
  * Secondary / Meta Text: `#475569` (Slate 600)
  * Structural Border: `#E2E8F0` (Slate 200 — 1px crisp borders)
* **Action & Urgency (Accent):**
  * Saffron Accent: `#F59E0B` / `#D97706` (Rating stars, active indicators, ETA chips)
* **Trust & Verification (Success):**
  * Emerald Trust Green: `#10B981` / `#059669` (Identity verification badge, online pills, payment complete)
* **Alert & Destructive (Error):**
  * Restrained Crimson: `#EF4444` / `#DC2626` (Cancellations, payment retries, dispute tags)

### 3.2 Typography Scale (`Plus Jakarta Sans`)
* **Display / Hero:** 28px / 34px Bold (`letter-spacing: -0.02em`)
* **Headline-Large:** 20px / 26px SemiBold
* **Headline-Medium:** 16px / 22px SemiBold
* **Body-Regular:** 14px / 20px Regular (`line-height: 1.5`)
* **Meta / Label-Caps:** 11px / 14px SemiBold (`letter-spacing: 0.04em`, uppercase)

### 3.3 Shapes & Elevation
* **Border Radius:**
  * Cards / Bottom Sheets: `16px` (`rounded-2xl`)
  * Buttons / Form Controls: `12px` (`rounded-xl`)
  * Pills / Status Badges: `9999px` (`rounded-full`)
* **Elevation:**
  * Minimal 1px border (`#E2E8F0`) paired with subtle ambient diffusion (`0 4px 20px -2px rgba(15, 23, 42, 0.05)`).

---

## 4. Screen-by-Screen Architecture

```
[Screen 1: Home / Catalog]
       ↓ (Select Service, e.g., Electrician)
[Screen 2: Service Booking & Customization]
       ↓ (Confirm & Request)
[Screen 3: 4-Stage Matching Pipeline Radar]
       ↓ (Worker Match Found & Accepted)
[Screen 4: Live Map Tracking & Worker Skill Passport]
       ↓ (Work Completed)
[Screen 5: Bill Breakdown, Test Payment & Skill Rating]
```

### Screen 1: Home & Service Catalog
* **Header:** Logo ("MakkalSevai"), location selector pill (`📍 T. Nagar, Chennai ▼`), notification bell.
* **Search & Assurance:** Search bar with mic icon; subtle civic trust banner: *"Government-backed, verified local skills at fair pricing."*
* **Categorized Service Grid:** 2-column card layout for Core Trades (Electrician / மின்சார பணியாளர், Plumber, Carpenter, Painter, AC Repair) + horizontal chips for Cleaning & Upkeep.

### Screen 2: Service Booking & Customization
* **Header:** Back action + "Book Electrician / முன்பதிவு".
* **Timing Pill Switcher:** `[⚡ Immediate (15–30 min)]` vs `[📅 Schedule for later]`.
* **Problem Description:** Input field with quick issue tags (`Switchboard sparking`, `Wiring fault`, `Power tripping`).
* **Address & Fair Fare:** Selected address card + "Estimated Base: ₹250" with transparent breakdown notice.
* **Sticky CTA:** Full-width Navy `#0F172A` button: `[Find Nearby Electrician →]`.

### Screen 3: 4-Stage Matching Pipeline Radar
* **Background:** Clean map canvas with expanding concentric pulse rings.
* **Floating Pipeline Card:** "Finding Best Verified Worker..." with 4-stage live stepper:
  1. `[✓] 5 km Radius Scanned`
  2. `[✓] Skill Match Confirmed (Electrician)`
  3. `[⚡] Checking Verified & Available Workers`
  4. `[...] Optimizing for Distance, Rating & Fairness`
* **Footer:** Secondary ghost button: `[Cancel Request]`.

### Screen 4: Live Tracking & Worker Skill Passport Sheet
* **Top 55% Canvas:** OpenStreetMap route preview with live worker marker progressing toward citizen pin.
* **Bottom 45% Floating Sheet:**
  * **Trust Header:** `✓ Identity Verified` shield + `e-Shram Registered` badge.
  * **Worker Identity:** Rajesh Kumar, Master Electrician.
  * **Digital Skill Passport Snippet:** ⭐ 4.9 (142 reviews) | 🛡️ 98% Reliability | 💼 3.2 Yrs on Platform.
  * **Live ETA:** Saffron pill (`Arriving in 12 mins`).
  * **Actions:** Navy CTA button `[📞 Call Worker (In-App)]` + secondary `[Cancel Order]`.

### Screen 5: Completion, Payment & Rating
* **Celebration Banner:** "Job Completed Successfully" + service timestamp.
* **Transparent Billing Card:** Base Labor (₹250) + Platform Fee (₹25) = **Total: ₹275**.
* **Payment Box:** `🧪 Razorpay Test Mode` pill + Navy CTA button `[Pay ₹275 via UPI / Card]`.
* **Feedback Section:** Interactive 5-star rating selector + feedback chips (`On-time`, `Clean work`, `Polite behavior`).

---

## 5. Non-Functional & Technical Alignment
* **State Continuity:** Screen 3 (Matching) automatically transitions to Screen 4 (Tracking) upon backend order status transition (`matching` → `accepted`).
* **Localization:** All text containers account for English and Tamil bilingual strings without clipping.
* **Demo Ready:** Follows the Smart India Hackathon Section 19 walkthrough script directly.
