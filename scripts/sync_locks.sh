#!/usr/bin/env bash
# Synchronizes Flutter dependencies and lockfiles across root and flavor packages.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."

cd "$ROOT_DIR"

echo "==> [1/3] Running flutter pub get in root..."
flutter pub get

echo "==> [2/3] Running double pub get in app_fdroid..."
(cd app_fdroid && flutter pub get && flutter pub get)

echo "==> [3/3] Running double pub get in app_playstore..."
(cd app_playstore && flutter pub get && flutter pub get)

echo "✅ All lockfiles synchronized successfully!"
