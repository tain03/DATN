#!/usr/bin/env python3
"""
Helper script to update seed SQL files with YouTube video durations from mapping.
This script reads youtube_durations.json and updates seed files with accurate durations.
"""
import os
import sys
import json
import re
from typing import Dict

def load_durations_mapping() -> Dict[str, int]:
    """Load durations from JSON mapping file"""
    script_dir = os.path.dirname(__file__)
    json_file = os.path.join(script_dir, 'youtube_durations.json')
    
    if not os.path.exists(json_file):
        print(f"⚠️  Mapping file not found: {json_file}")
        print("   Run fetch_youtube_durations.py first to generate mapping")
        return {}
    
    with open(json_file, 'r', encoding='utf-8') as f:
        return json.load(f)

def update_seed_file(file_path: str, durations: Dict[str, int]) -> bool:
    """Update seed file with durations from mapping"""
    if not os.path.exists(file_path):
        print(f"⚠️  File not found: {file_path}")
        return False
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Generate VALUES clause from JSON durations
    values_lines = []
    for video_id, duration in sorted(durations.items()):
        values_lines.append(f"                        ('{video_id}', {duration})")
    
    values_clause = ',\n'.join(values_lines)
    
    # Pattern to match VALUES clause in lesson_videos INSERT
    # Match: SELECT video_id, duration_seconds FROM (VALUES ... ) AS duration_map
    pattern = r"(SELECT duration_seconds FROM \(\s+SELECT video_id, duration_seconds FROM \(VALUES\s+)(.*?)(\s+\) AS duration_map)"
    
    def replace_values(match):
        return match.group(1) + values_clause + match.group(3)
    
    new_content = re.sub(pattern, replace_values, content, flags=re.DOTALL)
    
    if new_content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"   Updated VALUES clause with {len(durations)} durations")
        return True
    
    return False

def main():
    print("🔄 Loading YouTube durations mapping...")
    durations = load_durations_mapping()
    
    if not durations:
        print("❌ No durations found. Run fetch_youtube_durations.py first.")
        sys.exit(1)
    
    print(f"✓ Loaded {len(durations)} video durations")
    
    script_dir = os.path.dirname(__file__)
    
    # Update seed files
    seed_files = [
        '03_courses.sql',
        '03_exercises.sql'
    ]
    
    updated_count = 0
    for seed_file in seed_files:
        file_path = os.path.join(script_dir, seed_file)
        print(f"\n📝 Updating {seed_file}...")
        
        if update_seed_file(file_path, durations):
            print(f"✓ Updated {seed_file}")
            updated_count += 1
        else:
            print(f"⚠ No changes needed for {seed_file}")
    
    print(f"\n✅ Updated {updated_count} seed file(s)")
    print("   You can now run clean-and-seed.sh with accurate durations")

if __name__ == '__main__':
    main()

