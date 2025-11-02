#!/bin/bash

# Script để kiểm tra tất cả đường dẫn ảnh trong DEMO_SCENARIO.md

echo "🔍 Kiểm tra các file ảnh trong DEMO_SCENARIO.md..."
echo ""

# Danh sách các file ảnh được tham chiếu trong DEMO_SCENARIO.md
declare -a screenshots=(
    "screenshots/01-public/01_homepage_logged_out.png"
    "screenshots/01-public/04_homepage_logged_in.png"
    "screenshots/01-public/02_register_form.png"
    "screenshots/01-public/03_login_form.png"
    "screenshots/02-dashboard/01_dashboard_overview_tab.png"
    "screenshots/02-dashboard/02_dashboard_analytics_tab.png"
    "screenshots/02-dashboard/03_dashboard_skills_tab.png"
    "screenshots/03-courses/01_my_courses_all_tab.png"
    "screenshots/03-courses/04_my_courses_in_progress_tab.png"
    "screenshots/03-courses/02_browse_courses.png"
    "screenshots/03-courses/03_course_detail_curriculum_tab.png"
    "screenshots/03-courses/08_course_detail_about_tab.png"
    "screenshots/03-courses/08_course_detail_reviews_tab.png"
    "screenshots/03-courses/05_my_courses_completed_tab.png"
    "screenshots/03-courses/05_lesson_detail.png"
    "screenshots/04-exercises/01_exercises_list.png"
    "screenshots/04-exercises/04_exercise_detail.png"
    "screenshots/04-exercises/05_take_exercise.png"
    "screenshots/04-exercises/03_my_exercises_completed_tab.png"
    "screenshots/04-exercises/07_exercise_result.png"
    "screenshots/04-exercises/01_my_exercises_all_tab.png"
    "screenshots/04-exercises/02_my_exercises_in_progress_tab.png"
    "screenshots/04-exercises/03_exercise_history.png"
    "screenshots/05-progress/01_progress_analytics_study_time_tab.png"
    "screenshots/05-progress/02_progress_analytics_completion_tab.png"
    "screenshots/05-progress/03_progress_analytics_exercises_tab.png"
    "screenshots/05-progress/02_study_history.png"
    "screenshots/06-tools/01_goals.png"
    "screenshots/06-tools/02_reminders.png"
    "screenshots/06-tools/03_achievements_earned_tab.png"
    "screenshots/06-tools/03_achievements_available_tab.png"
    "screenshots/07-social/01_notifications.png"
    "screenshots/07-social/02_leaderboard_today_tab.png"
    "screenshots/07-social/03_leaderboard_weekly_tab.png"
    "screenshots/07-social/04_leaderboard_monthly_tab.png"
    "screenshots/08-profile/01_profile.png"
    "screenshots/08-profile/02_settings.png"
    "screenshots/08-profile/03_user_profile_public.png"
)

total=0
found=0
missing=0

for file in "${screenshots[@]}"; do
    total=$((total + 1))
    if [ -f "$file" ]; then
        echo "✅ $file"
        found=$((found + 1))
    else
        echo "❌ $file - KHÔNG TỒN TẠI"
        missing=$((missing + 1))
    fi
done

echo ""
echo "📊 Tổng kết:"
echo "  - Tổng số file: $total"
echo "  - Tìm thấy: $found"
echo "  - Thiếu: $missing"

if [ $missing -eq 0 ]; then
    echo ""
    echo "✅ Tất cả các file ảnh đều tồn tại!"
    exit 0
else
    echo ""
    echo "⚠️  Có $missing file ảnh bị thiếu!"
    exit 1
fi

