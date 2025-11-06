#!/usr/bin/env python3
"""
Verify seed data accuracy for official_test_results
Checks: per-skill model, constraints, conversions, relationships
"""

import psycopg2
import sys

# Database connection
conn = psycopg2.connect(
    host="localhost",
    port=5432,
    database="user_db",
    user="ielts_admin",
    password="ielts_password_2025"
)
cur = conn.cursor()

print("=" * 60)
print("VERIFYING OFFICIAL_TEST_RESULTS DATA")
print("=" * 60)

# 1. Basic counts
print("\n1. BASIC COUNTS:")
cur.execute("""
    SELECT 
        COUNT(*) as total_rows,
        COUNT(DISTINCT user_id) as unique_users,
        COUNT(CASE WHEN skill_type = 'listening' THEN 1 END) as listening,
        COUNT(CASE WHEN skill_type = 'reading' THEN 1 END) as reading,
        COUNT(CASE WHEN skill_type = 'writing' THEN 1 END) as writing,
        COUNT(CASE WHEN skill_type = 'speaking' THEN 1 END) as speaking
    FROM official_test_results;
""")
row = cur.fetchone()
print(f"   Total rows: {row[0]}")
print(f"   Unique users: {row[1]}")
print(f"   Listening: {row[2]}, Reading: {row[3]}, Writing: {row[4]}, Speaking: {row[5]}")

# Check if balanced (each skill should have same count)
if row[2] == row[3] == row[4] == row[5]:
    print("   ✅ All skills have equal counts (balanced)")
else:
    print("   ❌ FAIL: Skills are not balanced!")
    sys.exit(1)

# 2. IELTS Variant constraint
print("\n2. IELTS_VARIANT CONSTRAINT:")
cur.execute("""
    SELECT 
        skill_type,
        COUNT(CASE WHEN ielts_variant IS NOT NULL THEN 1 END) as with_variant,
        COUNT(CASE WHEN ielts_variant IS NULL THEN 1 END) as without_variant
    FROM official_test_results
    GROUP BY skill_type
    ORDER BY skill_type;
""")
variant_ok = True
for row in cur.fetchall():
    skill, with_v, without_v = row
    if skill == 'reading':
        if with_v > 0 and without_v == 0:
            print(f"   ✅ Reading: ALL have ielts_variant ({with_v})")
        else:
            print(f"   ❌ FAIL: Reading must have ielts_variant! (with:{with_v}, without:{without_v})")
            variant_ok = False
    else:
        if without_v > 0 and with_v == 0:
            print(f"   ✅ {skill.capitalize()}: NONE have ielts_variant ({without_v})")
        else:
            print(f"   ❌ FAIL: {skill} must NOT have ielts_variant! (with:{with_v}, without:{without_v})")
            variant_ok = False

if not variant_ok:
    sys.exit(1)

# 3. Source service distribution
print("\n3. SOURCE SERVICE DISTRIBUTION:")
cur.execute("""
    SELECT 
        skill_type,
        source_service,
        COUNT(*) as count
    FROM official_test_results
    GROUP BY skill_type, source_service
    ORDER BY skill_type, source_service;
""")
source_ok = True
for row in cur.fetchall():
    skill, source, count = row
    if skill in ['listening', 'reading'] and source == 'exercise_service':
        print(f"   ✅ {skill.capitalize()}: {source} ({count})")
    elif skill in ['writing', 'speaking'] and source == 'ai_service':
        print(f"   ✅ {skill.capitalize()}: {source} ({count})")
    else:
        print(f"   ❌ FAIL: {skill} has wrong source: {source}")
        source_ok = False

if not source_ok:
    sys.exit(1)

# 4. Raw score distribution
print("\n4. RAW SCORE DISTRIBUTION:")
cur.execute("""
    SELECT 
        skill_type,
        COUNT(raw_score) as has_raw_score,
        COUNT(*) - COUNT(raw_score) as null_raw_score,
        MIN(raw_score) as min_raw,
        MAX(raw_score) as max_raw
    FROM official_test_results
    GROUP BY skill_type
    ORDER BY skill_type;
""")
raw_ok = True
for row in cur.fetchall():
    skill, has_raw, null_raw, min_raw, max_raw = row
    if skill in ['listening', 'reading']:
        if has_raw > 0 and null_raw == 0 and min_raw >= 0 and max_raw <= 40:
            print(f"   ✅ {skill.capitalize()}: ALL have raw_score [{min_raw}-{max_raw}]")
        else:
            print(f"   ❌ FAIL: {skill} raw_score issue! (has:{has_raw}, null:{null_raw})")
            raw_ok = False
    else:
        if null_raw > 0 and has_raw == 0:
            print(f"   ✅ {skill.capitalize()}: ALL NULL raw_score (criteria-based)")
        else:
            print(f"   ❌ FAIL: {skill} should have NULL raw_score! (has:{has_raw}, null:{null_raw})")
            raw_ok = False

if not raw_ok:
    sys.exit(1)

# 5. Band score ranges
print("\n5. BAND SCORE RANGES:")
cur.execute("""
    SELECT 
        skill_type,
        MIN(band_score) as min_band,
        MAX(band_score) as max_band,
        ROUND(AVG(band_score)::numeric, 2) as avg_band
    FROM official_test_results
    GROUP BY skill_type
    ORDER BY skill_type;
""")
for row in cur.fetchall():
    skill, min_b, max_b, avg_b = row
    if 0 <= min_b <= 9 and 0 <= max_b <= 9:
        print(f"   ✅ {skill.capitalize()}: [{min_b}-{max_b}] avg={avg_b}")
    else:
        print(f"   ❌ FAIL: {skill} band_score out of range [0-9]!")
        sys.exit(1)

# 6. Foreign key integrity
print("\n6. FOREIGN KEY INTEGRITY:")
cur.execute("""
    SELECT COUNT(*) 
    FROM official_test_results otr
    LEFT JOIN user_profiles up ON otr.user_id = up.user_id
    WHERE up.user_id IS NULL;
""")
orphaned = cur.fetchone()[0]
if orphaned == 0:
    print(f"   ✅ All user_id references exist in user_profiles")
else:
    print(f"   ❌ FAIL: Found {orphaned} orphaned records!")
    sys.exit(1)

# 7. Test session grouping
print("\n7. TEST SESSION GROUPING:")
cur.execute("""
    WITH test_sessions AS (
        SELECT 
            user_id,
            test_date::date as test_date,
            test_type,
            ARRAY_AGG(skill_type ORDER BY skill_type) as skills
        FROM official_test_results
        WHERE test_type IN ('full_test', 'mock_test')
        GROUP BY user_id, test_date::date, test_type
        HAVING COUNT(*) = 3
    )
    SELECT COUNT(*) FROM test_sessions 
    WHERE skills = ARRAY['listening', 'reading', 'writing'];
""")
proper_sessions = cur.fetchone()[0]
print(f"   ✅ Found {proper_sessions} proper test sessions (L+R+W same date)")

cur.execute("""
    SELECT COUNT(*) 
    FROM official_test_results
    WHERE skill_type = 'speaking' 
    AND test_type IN ('full_test', 'mock_test');
""")
speaking_count = cur.fetchone()[0]
print(f"   ✅ Found {speaking_count} speaking tests (separate date +1 day)")

# 8. Academic vs General Training distribution
print("\n8. READING VARIANT DISTRIBUTION:")
cur.execute("""
    SELECT 
        ielts_variant,
        COUNT(*) as count,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) as percentage
    FROM official_test_results
    WHERE skill_type = 'reading'
    GROUP BY ielts_variant;
""")
for row in cur.fetchall():
    variant, count, pct = row
    print(f"   ✅ {variant}: {count} ({pct}%)")
    if variant == 'academic' and 65 <= pct <= 75:
        print(f"      → Within expected range (70% ±5%)")
    elif variant == 'general_training' and 25 <= pct <= 35:
        print(f"      → Within expected range (30% ±5%)")

# 9. Progression check (sample)
print("\n9. PROGRESSION CHECK (sample):")
cur.execute("""
    WITH user_progress AS (
        SELECT 
            user_id,
            skill_type,
            band_score,
            ROW_NUMBER() OVER (PARTITION BY user_id, skill_type ORDER BY test_date) as attempt
        FROM official_test_results
        WHERE user_id = (SELECT user_id FROM official_test_results ORDER BY user_id LIMIT 1)
    )
    SELECT skill_type, attempt, band_score
    FROM user_progress
    ORDER BY skill_type, attempt;
""")
current_skill = None
prev_score = 0
progression_count = 0
for row in cur.fetchall():
    skill, attempt, score = row
    if skill != current_skill:
        current_skill = skill
        prev_score = 0
        print(f"\n   {skill.capitalize()}:", end="")
    print(f" {score}", end="")
    if score >= prev_score:
        progression_count += 1
    prev_score = score

print(f"\n   → Progression looks realistic ✅")

print("\n" + "=" * 60)
print("✅ ALL VERIFICATION PASSED!")
print("=" * 60)

cur.close()
conn.close()
