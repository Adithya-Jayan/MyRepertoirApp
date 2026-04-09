# Project Context

To maintain clean and functional code, always perform a build and static analysis after making changes.

- **Build APK:** `flutter build apk --debug --flavor fdroid`
- **Build Web:** `flutter build web --base-href /`
- **Analyze:** `flutter analyze`

These steps must be completed to verify structural integrity and identify potential regressions before concluding a task. Always use the `fdroid` flavor for builds.
