## What's New in v5.0.2

### Major PDF Viewer Upgrades
* pdfrx Migration: Migrated the core PDF rendering engine to pdfrx.
* Interactivity & Interruption: Supports PDF touch interruption, hyperlinked navigate-to-page, and lazy rendering.
* Navigation Tools: Implemented a new scrollbar, page count overlay, and visual thumbnails.
* Fixes: Fixed PDF scrolling and autoscrolling bugs under various aspect ratios.

### Settings, Backup & Restore Audit
* Settings Coverage: Resolved issues where settings (such as the dot background pattern) did not immediately update or restore correctly.
* Restored Preferences: Added missing settings keys to the backup/restore manager, including useOledBlack (OLED dark mode), dismissed/last run versions, and legacy stage transition durations.
* Piece-Specific settings: The backup/restore system now dynamically backs up and restores piece-specific audio/video speed and pitch settings, MIDI track mute configurations, PDF scroll speeds, and UI section expansion states.
* Instant UI Refresh: Restoring settings now automatically invalidates the Practice Config cache and forces a theme reload on the active context, updating the app theme and layout immediately without needing a restart.

### UI, Navigation & Quality of Life
* Multi-Selection Deselect: Pressing the device back button will now deselect all active pieces in the gallery view.
* Bug Fixes:
  * Fixed a bug where a new piece would occasionally disappear or miss its group on creation.
  * Resolved a bug causing duplicate pieces to be created under certain input conditions.
  * Improved gallery navigation performance.

### Audio & Integration Fixes
* Continuous Playback: Fixed a bug where collapse/expand transitions of widget sections would interrupt or stop active audio playback.
* Share to App: Fixed the Android system share handling to reliably import files shared from external file managers.

### Developer & CI/CD Updates
* Flutter Upgrade: Upgraded all build environments and GitHub Actions workflows to Flutter 3.38.4 to resolve version solving conflicts.
* Streamlined Builds: Release workflow now builds a single universal APK for F-Droid, simplifies testing runs, and compiles Play Store bundles.
* Git Ignore: Excluded Kotlin local caches (**/.kotlin/) from tracking.

### Architecture & Flavor Split (F-Droid / Google Play)
* Flavor Isolation: The project has been refactored into a split app architecture with separate F-Droid (app_fdroid) and Google Play Store (app_playstore) sub-projects. This guarantees absolute compliance with both stores' guidelines.
* F-Droid Build: Fully open-source and free of all proprietary dependencies (e.g., Google Play Services, Firebase).
* Google Play Build: Prepared the project for future Play Store support by introducing a separate configuration with scoped storage compliance, disabled manual update notifications, and automated backups setup.
