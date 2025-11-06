#!/bin/bash
# Quick verification script for official_test_results data

echo "============================================"
echo "VERIFYING OFFICIAL_TEST_RESULTS DATA"
echo "============================================"

# 1. Basic counts
echo -e "\n1. BASIC COUNTS:"
docker exec ielts_postgres psql -U ielts_admin -d user_db -t -c "
SELECT 
    'Total rows: ' || COUNT(*) || ', Users: ' || COUNT(DISTINCT user_id) ||
    ', L:' || COUNT(CASE WHEN skill_type = 'listening' THEN 1 END) ||
    ', R:' || COUNT(CASE WHEN skill_type = 'reading' THEN 1 END) ||
    ', W:' || COUNT(CASE WHEN skill_type = 'writing' THEN 1 END) ||
    ', S:' || COUNT(CASE WHEN skill_type = 'speaking' THEN 1 END)
FROM official_test_results;
"

# 2. IELTS Variant check
echo -e "\n2. IELTS_VARIANT CONSTRAINT:"
docker exec ielts_postgres psql -U ielts_admin -d user_db -t -c "
SELECT 
    skill_type || ': ' ||
    CASE 
        WHEN skill_type = 'reading' AND COUNT(CASE WHEN ielts_variant IS NOT NULL THEN 1 END) = COUNT(*) 
        THEN '✅ ALL have variant'
        WHEN skill_type != 'reading' AND COUNT(CASE WHEN ielts_variant IS NULL THEN 1 END) = COUNT(*) 
        THEN '✅ NONE have variant'
        ELSE '❌ FAIL!'
    END
FROM official_test_results
GROUP BY skill_type
ORDER BY skill_type;
"

# 3. Source service
echo -e "\n3. SOURCE SERVICE:"
docker exec ielts_postgres psql -U ielts_admin -d user_db -t -c "
SELECT 
    skill_type || ': ' || source_service || ' (' || COUNT(*) || ')'
FROM official_test_results
GROUP BY skill_type, source_service
ORDER BY skill_type;
"

# 4. Raw score
echo -e "\n4. RAW SCORE:"
docker exec ielts_postgres psql -U ielts_admin -d user_db -t -c "
SELECT 
    skill_type || ': ' ||
    CASE 
        WHEN skill_type IN ('listening', 'reading') 
        THEN 'has=' || COUNT(raw_score) || ' [' || MIN(raw_score) || '-' || MAX(raw_score) || ']'
        ELSE 'NULL=' || COUNT(*) - COUNT(raw_score)
    END
FROM official_test_results
GROUP BY skill_type
ORDER BY skill_type;
"

# 5. Band scores
echo -e "\n5. BAND SCORES:"
docker exec ielts_postgres psql -U ielts_admin -d user_db -t -c "
SELECT 
    skill_type || ': [' || MIN(band_score) || '-' || MAX(band_score) || '] avg=' || ROUND(AVG(band_score), 2)
FROM official_test_results
GROUP BY skill_type
ORDER BY skill_type;
"

# 6. Foreign keys
echo -e "\n6. FOREIGN KEY INTEGRITY:"
docker exec ielts_postgres psql -U ielts_admin -d user_db -t -c "
SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ All user_id exist in user_profiles'
        ELSE '❌ Found ' || COUNT(*) || ' orphaned records'
    END
FROM official_test_results otr
LEFT JOIN user_profiles up ON otr.user_id = up.user_id
WHERE up.user_id IS NULL;
"

# 7. Academic vs General
echo -e "\n7. READING VARIANT DISTRIBUTION:"
docker exec ielts_postgres psql -U ielts_admin -d user_db -t -c "
SELECT 
    ielts_variant || ': ' || COUNT(*) || ' (' || ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) || '%)'
FROM official_test_results
WHERE skill_type = 'reading'
GROUP BY ielts_variant;
"

# 8. Test types
echo -e "\n8. TEST TYPE DISTRIBUTION:"
docker exec ielts_postgres psql -U ielts_admin -d user_db -t -c "
SELECT 
    test_type || ': ' || COUNT(*) || ' rows, ' || COUNT(DISTINCT user_id) || ' users'
FROM official_test_results
GROUP BY test_type
ORDER BY test_type;
"

echo -e "\n============================================"
echo "✅ VERIFICATION COMPLETE"
echo "============================================"
