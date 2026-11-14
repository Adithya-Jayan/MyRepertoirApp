# Synchronizes Flutter dependencies and lockfiles across root and flavor packages.
$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $PSScriptRoot
Set-Location $RootDir

Write-Host "==> [1/3] Running flutter pub get in root..." -ForegroundColor Cyan
flutter pub get

Write-Host "==> [2/3] Running double pub get in app_fdroid..." -ForegroundColor Cyan
Push-Location app_fdroid
try {
    flutter pub get
    flutter pub get
} finally {
    Pop-Location
}

Write-Host "==> [3/3] Running double pub get in app_playstore..." -ForegroundColor Cyan
Push-Location app_playstore
try {
    flutter pub get
    flutter pub get
} finally {
    Pop-Location
}

Write-Host "✅ All lockfiles synchronized successfully!" -ForegroundColor Green
