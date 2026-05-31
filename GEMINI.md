# Project Context

To maintain clean and functional code, always perform a build and static analysis after making changes.

- **Build APK:** `flutter build apk --debug --flavor fdroid`
- **Build Web:** `flutter build web --base-href /`
- **Analyze:** `flutter analyze`

These steps must be completed to verify structural integrity and identify potential regressions before concluding a task, Make sure all warnings and errors are always cleaned up after all tasks. Always use the `fdroid` flavor for builds.

Always confirm with the user before merging changes or Pushing updates (For each push/merge).

- **Backward Compatibility:** Always ensure that backup and restore, app upgrades, and general backward compatibility are checked and handled properly for any update.
- **Settings & Backup:** Whenever a new `SharedPreferences` key is added to the application, ensure it is also included in the backup (`BackupManager._collectAppSettings`) and restore (`RestoreManager._restoreAppSettings`) logic to maintain user data consistency.