#!/usr/bin/env python3
"""
Validates Google Play Store listing assets in fastlane/metadata/android/en-US
against Google Play Console specifications.
"""

import os
import sys
from PIL import Image

METADATA_DIR = os.path.join(os.path.dirname(__file__), '..', 'fastlane', 'metadata', 'android', 'en-US')

def fail(msg):
    print(f"❌ ERROR: {msg}")
    sys.exit(1)

def warn(msg):
    print(f"⚠️  WARNING: {msg}")

def check_file_exists(rel_path):
    full_path = os.path.join(METADATA_DIR, rel_path)
    if not os.path.isfile(full_path):
        fail(f"Missing required file: {rel_path}")
    return full_path

def main():
    print("Checking Google Play Store assets in fastlane metadata...")
    errors = 0

    # 1. Title
    title_path = check_file_exists('title.txt')
    with open(title_path, 'r', encoding='utf-8') as f:
        title = f.read().strip()
    if len(title) == 0:
        print("❌ title.txt is empty")
        errors += 1
    elif len(title) > 30:
        print(f"❌ title.txt exceeds 30 characters (length: {len(title)}): '{title}'")
        errors += 1
    else:
        print(f"✅ Title ({len(title)}/30 chars): '{title}'")

    # 2. Short Description
    short_desc_path = check_file_exists('short_description.txt')
    with open(short_desc_path, 'r', encoding='utf-8') as f:
        short_desc = f.read().strip()
    if len(short_desc) == 0:
        print("❌ short_description.txt is empty")
        errors += 1
    elif len(short_desc) > 80:
        print(f"❌ short_description.txt exceeds 80 characters (length: {len(short_desc)})")
        errors += 1
    else:
        print(f"✅ Short Description ({len(short_desc)}/80 chars): '{short_desc}'")

    # 3. Full Description
    full_desc_path = check_file_exists('full_description.txt')
    with open(full_desc_path, 'r', encoding='utf-8') as f:
        full_desc = f.read().strip()
    if len(full_desc) == 0:
        print("❌ full_description.txt is empty")
        errors += 1
    elif len(full_desc) > 4000:
        print(f"❌ full_description.txt exceeds 4000 characters (length: {len(full_desc)})")
        errors += 1
    else:
        print(f"✅ Full Description ({len(full_desc)}/4000 chars)")

    # 4. App Icon
    icon_path = check_file_exists('images/icon.png')
    size_mb = os.path.getsize(icon_path) / (1024 * 1024)
    if size_mb > 1.0:
        print(f"❌ icon.png file size exceeds 1 MB ({size_mb:.2f} MB)")
        errors += 1
    with Image.open(icon_path) as im:
        if im.size != (512, 512):
            print(f"❌ icon.png must be exactly 512x512 px (got {im.size[0]}x{im.size[1]})")
            errors += 1
        else:
            print(f"✅ App Icon: 512x512 px, {im.mode}, {size_mb*1024:.1f} KB")

    # 5. Feature Graphic
    feature_path = check_file_exists('images/featureGraphic.png')
    f_size_mb = os.path.getsize(feature_path) / (1024 * 1024)
    if f_size_mb > 1.0:
        print(f"❌ featureGraphic.png file size exceeds 1 MB ({f_size_mb:.2f} MB)")
        errors += 1
    with Image.open(feature_path) as im:
        if im.size != (1024, 500):
            print(f"❌ featureGraphic.png must be 1024x500 px (got {im.size[0]}x{im.size[1]})")
            errors += 1
        if im.mode not in ('RGB', 'L'):
            print(f"❌ featureGraphic.png must NOT have an alpha channel (got mode '{im.mode}')")
            errors += 1
        if im.size == (1024, 500) and im.mode in ('RGB', 'L'):
            print(f"✅ Feature Graphic: 1024x500 px, {im.mode} (no alpha), {f_size_mb*1024:.1f} KB")

    # 6. Phone Screenshots
    screenshots_dir = os.path.join(METADATA_DIR, 'images', 'phoneScreenshots')
    if not os.path.isdir(screenshots_dir):
        print(f"❌ Screenshots directory missing: {screenshots_dir}")
        errors += 1
    else:
        screenshots = [f for f in os.listdir(screenshots_dir) if f.lower().endswith(('.png', '.jpg', '.jpeg'))]
        if len(screenshots) < 2:
            print(f"❌ At least 2 phone screenshots required (found {len(screenshots)})")
            errors += 1
        elif len(screenshots) > 8:
            warn(f"Play Console accepts up to 8 screenshots per device type (found {len(screenshots)})")
        
        valid_shots = 0
        for s in screenshots:
            spath = os.path.join(screenshots_dir, s)
            with Image.open(spath) as sim:
                min_dim = min(sim.size)
                max_dim = max(sim.size)
                if min_dim < 320 or max_dim > 3840:
                    print(f"❌ Screenshot {s} dimensions {sim.size} outside allowed range [320px, 3840px]")
                    errors += 1
                else:
                    valid_shots += 1
        print(f"✅ Phone Screenshots: {valid_shots} valid screenshots verified")

    if errors > 0:
        print(f"\n❌ FAILED: {errors} issue(s) found.")
        sys.exit(1)
    else:
        print("\n🎉 ALL STORE ASSETS PASSED GOOGLE PLAY SPECIFICATIONS!")

if __name__ == '__main__':
    main()
