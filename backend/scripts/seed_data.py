import sys
import os
import uuid
from datetime import datetime, timezone, timedelta

# Add parent directory to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import text
from app.core.database import sync_engine

def run_seed():
    print("[START] Starting MakkalSevai Database Seeding...")

    with sync_engine.connect() as conn:
        trans = conn.begin()
        try:
            # 1. Matching Config
            conn.execute(text("""
                INSERT INTO matching_config (param_key, param_value, description)
                VALUES 
                    ('weight_distance', 0.45, 'Alpha weight for inverse distance'),
                    ('weight_rating', 0.30, 'Beta weight for normalized worker rating'),
                    ('weight_reliability', 0.15, 'Gamma weight for reliability score'),
                    ('weight_fairness', 0.10, 'Delta weight boosting new workers (<5 jobs)'),
                    ('default_radius_meters', 5000, 'Initial search radius in meters'),
                    ('max_radius_meters', 15000, 'Progressive expansion maximum radius')
                ON CONFLICT (param_key) DO UPDATE SET param_value = EXCLUDED.param_value;
            """))
            print("  [OK] Matching config weights seeded.")

            # 2. Service Categories
            categories = [
                ("Core Trades", "முதன்மை தொழில்கள்", "tool", "core-trades"),
                ("Cleaning & Upkeep", "தூய்மை & பராமரிப்பு", "sparkles", "cleaning-upkeep"),
                ("Construction & Renovation", "கட்டுமானம் & புதுப்பித்தல்", "hammer", "construction-renovation"),
                ("Personal Care at Home", "தனிநபர் பராமரிப்பு", "scissors", "personal-care"),
                ("Vehicle Maintenance", "வாகன பராமரிப்பு", "car", "vehicle-maintenance"),
                ("Other Add-ons", "கூடுதல் சேவைகள்", "plus-circle", "other-addons")
            ]

            category_ids = {}
            for name, name_ta, icon, slug in categories:
                res = conn.execute(text("""
                    INSERT INTO service_categories (name, name_ta, icon, slug)
                    VALUES (:name, :name_ta, :icon, :slug)
                    ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name, name_ta = EXCLUDED.name_ta
                    RETURNING id;
                """), {"name": name, "name_ta": name_ta, "icon": icon, "slug": slug}).fetchone()
                category_ids[slug] = res[0]
            print(f"  [OK] Seeded {len(categories)} service categories.")

            # 3. Services Ontology
            services_data = [
                # Core Trades
                ("Electrician", "மின்சார பணியாளர்", "electrician", "zap", 250.00, 25.00, "core-trades"),
                ("Plumber", "குழாய் பழுதுபார்ப்பவர்", "plumber", "droplet", 250.00, 25.00, "core-trades"),
                ("Carpenter", "தச்சர்", "carpenter", "hammer", 300.00, 30.00, "core-trades"),
                ("Painter", "ஓவியர்", "painter", "paint-roller", 350.00, 35.00, "core-trades"),
                ("Mason", "கொத்தனார்", "mason", "brick-wall", 400.00, 40.00, "core-trades"),
                ("Welder", "வெல்டர்", "welder", "flame", 300.00, 30.00, "core-trades"),
                ("AC & Appliance Repair", "ஏசி பழுது", "ac-repair", "air-conditioner", 350.00, 35.00, "core-trades"),
                
                # Cleaning & Upkeep
                ("House/Deep Cleaning", "வீடு முழு தூய்மை", "deep-cleaning", "sparkles", 500.00, 50.00, "cleaning-upkeep"),
                ("Pest Control", "பூச்சி கட்டுப்பாடு", "pest-control", "shield-alert", 600.00, 60.00, "cleaning-upkeep"),
                ("Water Tank Cleaning", "தண்ணீர் தொட்டி சுத்தம்", "tank-cleaning", "container", 450.00, 45.00, "cleaning-upkeep"),
                ("RO Water Purifier Service", "RO சுத்திகரிப்பான் சேவை", "ro-service", "filter", 300.00, 30.00, "cleaning-upkeep"),

                # Construction & Renovation
                ("Tiling/Flooring", "தரை தளம் அமைத்தல்", "tiling", "grid", 500.00, 50.00, "construction-renovation"),
                ("False Ceiling", "ஃபால்ஸ் சீலிங்", "false-ceiling", "layers", 650.00, 65.00, "construction-renovation"),
                ("Waterproofing", "நீர்ப்புகாப்பு", "waterproofing", "umbrella", 700.00, 70.00, "construction-renovation"),
                ("Roofing", "கூரை வேலை", "roofing", "home", 800.00, 80.00, "construction-renovation"),

                # Personal Care
                ("Salon/Grooming", "முடி திருத்துதல் & சீரமைப்பு", "grooming", "scissors", 300.00, 30.00, "personal-care"),
                ("Massage Therapist", "மசாஜ் சிகிச்சை", "massage", "heart-pulse", 700.00, 70.00, "personal-care"),

                # Vehicle Maintenance
                ("Two-Wheeler/Car Mechanic", "வாகன மெக்கானிக்", "vehicle-mechanic", "wrench", 350.00, 35.00, "vehicle-maintenance"),
                ("Car Wash & Detailing", "கார் கழுவுதல்", "car-wash", "car", 400.00, 40.00, "vehicle-maintenance"),

                # Other Add-ons
                ("CCTV Installation", "CCTV பொருத்துதல்", "cctv-install", "camera", 500.00, 50.00, "other-addons"),
                ("Solar Panel Service", "சூரிய ஒளி மின் பலகை", "solar-service", "sun", 600.00, 60.00, "other-addons"),
                ("Gardening", "தோட்ட பராமரிப்பு", "gardening", "flower", 300.00, 30.00, "other-addons"),
                ("Packers & Movers", "பொருட்கள் மாற்றுபவர்", "packers-movers", "truck", 1200.00, 100.00, "other-addons"),
                ("Laundry & Ironing", "சலவை & இஸ்திரி", "laundry", "shirt", 200.00, 20.00, "other-addons")
            ]

            service_ids = {}
            for name, name_ta, slug, icon, base_fee, plat_fee, cat_slug in services_data:
                cat_id = category_ids[cat_slug]
                res = conn.execute(text("""
                    INSERT INTO services (category_id, name, name_ta, slug, icon, base_diagnostic_fee, platform_fee, is_active)
                    VALUES (:cat_id, :name, :name_ta, :slug, :icon, :base_fee, :plat_fee, true)
                    ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name, name_ta = EXCLUDED.name_ta, base_diagnostic_fee = EXCLUDED.base_diagnostic_fee
                    RETURNING id;
                """), {
                    "cat_id": cat_id, "name": name, "name_ta": name_ta, "slug": slug,
                    "icon": icon, "base_fee": base_fee, "plat_fee": plat_fee
                }).fetchone()
                service_ids[slug] = res[0]
            print(f"  [OK] Seeded {len(services_data)} services across categories.")

            # 4. Demo Customer (Senthil Nathan at T. Nagar)
            cust_res = conn.execute(text("""
                INSERT INTO users (phone, email, role, full_name)
                VALUES ('+919876543210', 'senthil.nathan@example.com', 'customer', 'Senthil Nathan')
                ON CONFLICT (phone) DO UPDATE SET full_name = EXCLUDED.full_name
                RETURNING id;
            """)).fetchone()
            cust_id = cust_res[0]

            conn.execute(text("""
                INSERT INTO customer_profiles (user_id, saved_addresses, default_location)
                VALUES (
                    :uid,
                    '[{"label": "Home", "address": "Flat 4B, Shanti Nilayam, 12th Cross St, T. Nagar, Chennai - 600017", "lat": 13.0418, "lng": 80.2341}]'::jsonb,
                    ST_SetSRID(ST_MakePoint(80.2341, 13.0418), 4326)
                )
                ON CONFLICT (user_id) DO UPDATE SET default_location = EXCLUDED.default_location;
            """), {"uid": cust_id})
            print(f"  [OK] Demo customer created (ID: {cust_id}).")

            # 5. Seed 15 Demo Workers across Chennai
            # Rajesh Kumar (The Primary Star Electrician for SIH Demo Flow)
            workers = [
                {
                    "name": "Rajesh Kumar",
                    "phone": "+919876543211",
                    "skill": "electrician",
                    "secondary": ["ac-repair"],
                    "lat": 13.0450, "lng": 80.2380,  # ~1.8 km from customer in T. Nagar
                    "kyc": "verified",
                    "uan": "UAN-TN-2026-88392",
                    "available": True,
                    "active_job": False,
                    "rating_avg": 4.9,
                    "rating_count": 142,
                    "reliability": 0.980,
                    "jobs": 142,
                    "earnings": 54200.0,
                    "joined_days_ago": 1168  # 3.2 years
                },
                {
                    "name": "Murugan Vel",
                    "phone": "+919876543212",
                    "skill": "electrician",
                    "secondary": [],
                    "lat": 13.0510, "lng": 80.2220,  # Kodambakkam ~2.5 km
                    "kyc": "verified",
                    "uan": "UAN-TN-2026-19283",
                    "available": True,
                    "active_job": False,
                    "rating_avg": 4.7,
                    "rating_count": 89,
                    "reliability": 0.950,
                    "jobs": 89,
                    "earnings": 32000.0,
                    "joined_days_ago": 500
                },
                {
                    "name": "Karthik Subramanian (New Worker)",
                    "phone": "+919876543213",
                    "skill": "electrician",
                    "secondary": ["cctv-install"],
                    "lat": 13.0430, "lng": 80.2310,  # T. Nagar ~0.5 km (Very close! Tests Fairness Boost)
                    "kyc": "verified",
                    "uan": "UAN-TN-2026-99124",
                    "available": True,
                    "active_job": False,
                    "rating_avg": 5.0,
                    "rating_count": 3,  # <5 jobs -> Fairness Score = 1.0!
                    "reliability": 1.000,
                    "jobs": 3,
                    "earnings": 900.0,
                    "joined_days_ago": 15
                },
                {
                    "name": "Dinesh Pandian (Busy)",
                    "phone": "+919876543214",
                    "skill": "electrician",
                    "secondary": [],
                    "lat": 13.0420, "lng": 80.2350,
                    "kyc": "verified",
                    "uan": "UAN-TN-2026-33912",
                    "available": True,
                    "active_job": True,  # ON ACTIVE JOB -> Must be filtered out!
                    "rating_avg": 4.8,
                    "rating_count": 60,
                    "reliability": 0.960,
                    "jobs": 60,
                    "earnings": 21000.0,
                    "joined_days_ago": 300
                },
                {
                    "name": "Suresh Babu (Unverified)",
                    "phone": "+919876543215",
                    "skill": "electrician",
                    "secondary": [],
                    "lat": 13.0410, "lng": 80.2330,
                    "kyc": "pending",  # PENDING KYC -> Must be filtered out!
                    "uan": None,
                    "available": True,
                    "active_job": False,
                    "rating_avg": 0.0,
                    "rating_count": 0,
                    "reliability": 1.000,
                    "jobs": 0,
                    "earnings": 0.0,
                    "joined_days_ago": 2
                },
                {
                    "name": "Ravi Chandran",
                    "phone": "+919876543216",
                    "skill": "plumber",
                    "secondary": [],
                    "lat": 13.0330, "lng": 80.2500,  # Alwarpet ~2.8 km
                    "kyc": "verified",
                    "uan": "UAN-TN-2026-44128",
                    "available": True,
                    "active_job": False,
                    "rating_avg": 4.85,
                    "rating_count": 110,
                    "reliability": 0.970,
                    "jobs": 110,
                    "earnings": 41500.0,
                    "joined_days_ago": 720
                },
                {
                    "name": "Mani Sekar",
                    "phone": "+919876543217",
                    "skill": "plumber",
                    "secondary": ["water-tank-cleaning"],
                    "lat": 13.0580, "lng": 80.2350,  # Nungambakkam ~2.2 km
                    "kyc": "verified",
                    "uan": "UAN-TN-2026-55192",
                    "available": True,
                    "active_job": False,
                    "rating_avg": 4.6,
                    "rating_count": 45,
                    "reliability": 0.920,
                    "jobs": 45,
                    "earnings": 15000.0,
                    "joined_days_ago": 400
                },
                {
                    "name": "Selvam Muthu",
                    "phone": "+919876543218",
                    "skill": "carpenter",
                    "secondary": [],
                    "lat": 13.0425, "lng": 80.2360,  # T. Nagar ~0.3 km
                    "kyc": "verified",
                    "uan": "UAN-TN-2026-66120",
                    "available": True,
                    "active_job": False,
                    "rating_avg": 4.9,
                    "rating_count": 130,
                    "reliability": 0.990,
                    "jobs": 130,
                    "earnings": 52000.0,
                    "joined_days_ago": 800
                },
                {
                    "name": "Anand Natarajan",
                    "phone": "+919876543219",
                    "skill": "painter",
                    "secondary": [],
                    "lat": 13.0210, "lng": 80.2230,  # Saidapet ~2.6 km
                    "kyc": "verified",
                    "uan": "UAN-TN-2026-77142",
                    "available": True,
                    "active_job": False,
                    "rating_avg": 4.75,
                    "rating_count": 78,
                    "reliability": 0.940,
                    "jobs": 78,
                    "earnings": 38000.0,
                    "joined_days_ago": 600
                },
                {
                    "name": "Gopalakrishnan",
                    "phone": "+919876543220",
                    "skill": "ac-repair",
                    "secondary": ["electrician"],  # Secondary skill electrician!
                    "lat": 13.0360, "lng": 80.2450,  # Teynampet ~1.5 km
                    "kyc": "verified",
                    "uan": "UAN-TN-2026-88190",
                    "available": True,
                    "active_job": False,
                    "rating_avg": 4.8,
                    "rating_count": 92,
                    "reliability": 0.960,
                    "jobs": 92,
                    "earnings": 45000.0,
                    "joined_days_ago": 550
                },
                {
                    "name": "Velmurugan (Deep Cleaning)",
                    "phone": "+919876543221",
                    "skill": "deep-cleaning",
                    "secondary": ["pest-control"],
                    "lat": 13.0480, "lng": 80.2310,  # T. Nagar
                    "kyc": "verified",
                    "uan": "UAN-TN-2026-99201",
                    "available": True,
                    "active_job": False,
                    "rating_avg": 4.7,
                    "rating_count": 55,
                    "reliability": 0.950,
                    "jobs": 55,
                    "earnings": 31000.0,
                    "joined_days_ago": 350
                },
                {
                    "name": "Balamurugan (Mason)",
                    "phone": "+919876543222",
                    "skill": "mason",
                    "secondary": ["tiling"],
                    "lat": 13.0650, "lng": 80.2150,  # Vadapalani ~3.5 km
                    "kyc": "verified",
                    "uan": "UAN-TN-2026-11202",
                    "available": True,
                    "active_job": False,
                    "rating_avg": 4.65,
                    "rating_count": 40,
                    "reliability": 0.930,
                    "jobs": 40,
                    "earnings": 24000.0,
                    "joined_days_ago": 420
                },
                {
                    "name": "Shankar (Far away 12 km)",
                    "phone": "+919876543223",
                    "skill": "electrician",
                    "secondary": [],
                    "lat": 13.1200, "lng": 80.2100,  # Kolathur ~11 km (Tests progressive expansion to 15km)
                    "kyc": "verified",
                    "uan": "UAN-TN-2026-22303",
                    "available": True,
                    "active_job": False,
                    "rating_avg": 4.9,
                    "rating_count": 120,
                    "reliability": 0.980,
                    "jobs": 120,
                    "earnings": 48000.0,
                    "joined_days_ago": 700
                },
                {
                    "name": "Praveen Kumar (Offline)",
                    "phone": "+919876543224",
                    "skill": "electrician",
                    "secondary": [],
                    "lat": 13.0440, "lng": 80.2330,  # In T. Nagar
                    "kyc": "verified",
                    "uan": "UAN-TN-2026-33404",
                    "available": False,  # OFFLINE -> Filtered out!
                    "active_job": False,
                    "rating_avg": 4.8,
                    "rating_count": 75,
                    "reliability": 0.960,
                    "jobs": 75,
                    "earnings": 28000.0,
                    "joined_days_ago": 450
                },
                {
                    "name": "Venkatesh (Mechanic)",
                    "phone": "+919876543225",
                    "skill": "vehicle-mechanic",
                    "secondary": [],
                    "lat": 13.0435, "lng": 80.2345,
                    "kyc": "verified",
                    "uan": "UAN-TN-2026-44505",
                    "available": True,
                    "active_job": False,
                    "rating_avg": 4.85,
                    "rating_count": 105,
                    "reliability": 0.970,
                    "jobs": 105,
                    "earnings": 42000.0,
                    "joined_days_ago": 650
                }
            ]

            for w in workers:
                # Insert User
                u_res = conn.execute(text("""
                    INSERT INTO users (phone, role, full_name)
                    VALUES (:phone, 'worker', :name)
                    ON CONFLICT (phone) DO UPDATE SET full_name = EXCLUDED.full_name
                    RETURNING id;
                """), {"phone": w["phone"], "name": w["name"]}).fetchone()
                w_uid = u_res[0]

                # Secondary IDs
                sec_ids = [service_ids[s] for s in w["secondary"] if s in service_ids]
                primary_id = service_ids[w["skill"]]
                joined_dt = datetime.now(timezone.utc) - timedelta(days=w["joined_days_ago"])

                conn.execute(text("""
                    INSERT INTO worker_profiles (
                        user_id, kyc_status, uan, primary_skill_id, secondary_skill_ids,
                        current_location, is_available, is_on_active_job, rating_avg, rating_count,
                        reliability_score, jobs_completed, earnings_total, joined_at, last_location_update
                    ) VALUES (
                        :uid, :kyc, :uan, :prim_skill, :sec_skills,
                        ST_SetSRID(ST_MakePoint(:lng, :lat), 4326),
                        :available, :active_job, :rating_avg, :rating_count,
                        :reliability, :jobs, :earnings, :joined_at, now()
                    )
                    ON CONFLICT (user_id) DO UPDATE SET
                        kyc_status = EXCLUDED.kyc_status,
                        is_available = EXCLUDED.is_available,
                        is_on_active_job = EXCLUDED.is_on_active_job,
                        rating_avg = EXCLUDED.rating_avg,
                        rating_count = EXCLUDED.rating_count,
                        reliability_score = EXCLUDED.reliability_score,
                        jobs_completed = EXCLUDED.jobs_completed,
                        earnings_total = EXCLUDED.earnings_total,
                        current_location = EXCLUDED.current_location;
                """), {
                    "uid": w_uid,
                    "kyc": w["kyc"],
                    "uan": w["uan"],
                    "prim_skill": primary_id,
                    "sec_skills": sec_ids,
                    "lat": w["lat"],
                    "lng": w["lng"],
                    "available": w["available"],
                    "active_job": w["active_job"],
                    "rating_avg": w["rating_avg"],
                    "rating_count": w["rating_count"],
                    "reliability": w["reliability"],
                    "jobs": w["jobs"],
                    "earnings": w["earnings"],
                    "joined_at": joined_dt
                })

            print(f"  [OK] Seeded {len(workers)} realistic Chennai tradespeople (including Rajesh Kumar with 3.2 yrs experience & 4.9 rating).")

            trans.commit()
            print("[SUCCESS] MakkalSevai Seed Data completed successfully!")
        except Exception as e:
            trans.rollback()
            print(f"[ERROR] Error during seed: {e}")
            raise e

if __name__ == "__main__":
    run_seed()
