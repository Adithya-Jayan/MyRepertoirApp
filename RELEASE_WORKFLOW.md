# Release Workflow Documentation

## Overview

This repository uses a multi-project, split-flavor structure for the application. Releases are automated using two primary GitHub Actions workflows:

1.  **Create Release:** A manually triggered workflow for creating official (stable) and pre-release versions.
2.  **Nightly Build:** An automated daily workflow that creates rolling builds of the latest code.

---

## 1. Create Release Workflow

-   **File:** `.github/workflows/release.yml`
-   **Name:** "Create Release"

This workflow updates version identifiers across the workspace, compiles the split F-Droid and Google Play builds, writes release notes, and creates a tagged GitHub release.

### How to Use

1.  Navigate to the **Actions** tab in the GitHub repository.
2.  Select the **"Create Release"** workflow.
3.  Click the **"Run workflow"** button.
4.  Configure the inputs:
    -   **`release_type`**: Choose the version bump type (`patch`, `minor`, `major`, or `stabilize`).
    -   **`prerelease`**: Check this box to generate a pre-release suffix (e.g., `-prerelease.1`).
    -   **`release_notes`**: Optional custom notes (newlines supported via `\n`).
    -   **`use_release_file`**: Check this box to read the release description from `RELEASE_NOTES.md` at the project root.
5.  Click **"Run workflow"**.

### Versioning Scheme

The version is defined as `VERSION_NAME+BUILD_NUMBER` (e.g., `5.0.2+39`). The workflow keeps the root `pubspec.yaml`, `app_fdroid/pubspec.yaml`, and `app_playstore/pubspec.yaml` fully synchronized.

-   **Official (Stable) Release:** The version name is incremented based on the chosen bump type, and the build number is incremented by 1.
-   **Pre-release:** Generates an incremental pre-release tag for the next version (e.g., `5.0.3-prerelease.1+40`).
-   **Stabilize:** Transitions a pre-release version name (e.g., `5.0.2-prerelease.1`) into its stable counterpart (e.g., `5.0.2`) without performing a minor/major/patch bump.

### Version Bumping Examples

| Current Version | Release Type | Prerelease | New Version             | Notes |
| --------------- | ------------ | ---------- | ----------------------- | ----- |
| `5.0.1+37`      | `patch`      | `false`    | `5.0.2+38`              | Standard patch bump |
| `5.0.1+37`      | `minor`      | `true`     | `5.1.0-prerelease.1+38` | Pre-release minor bump |
| `5.0.2-prerelease.1+38` | `stabilize` | `false` | `5.0.2+39`            | Convert pre-release to stable |

### What the Workflow Does

1.  **Calculates the next version name and build number** from the root `pubspec.yaml`.
2.  **Bumps and updates version files** across all three `pubspec.yaml` files.
3.  **Builds the application** for both flavors:
    -   **F-Droid (`app_fdroid`):** Builds a single, universal Android APK, an Android App Bundle (AAB), and a zipped Web build.
    -   **Play Store (`app_playstore`):** Builds an Android App Bundle (AAB).
4.  **Generates checksums** (SHA-256) for all compiled assets.
5.  **Creates a Git tag** named `vVERSION_NAME+BUILD_NUMBER` on the commit.
6.  **Formats & Clears Release Notes:** Reads manual inputs and the optional `RELEASE_NOTES.md` file. It then wipes the contents of `RELEASE_NOTES.md` to prevent carrying old notes to the next run.
7.  **Publishes F-Droid Changelog:** Creates/updates a Fastlane changelog file at `fastlane/metadata/android/en-US/changelogs/<BUILD_NUMBER>.txt`.
8.  **Commits and pushes changes** (including pubspec updates and changelogs) back to the repository.
9.  **Publishes a GitHub Release** containing the build outputs, checksums, and release notes.

---

## 2. Nightly Build Workflow

-   **File:** `.github/workflows/nightly.yml`
-   **Name:** "Nightly Build"

This workflow compiles a daily development build from the latest commits.

### How it Works

-   **Trigger:** Automatically runs daily at 16:30 UTC or can be manually triggered.
-   **Versioning:** Generates a version string formatted as `0.0.0-nightly-YYYYMMDD-SHORT_SHA-rRUN_NUMBER`.
-   **Synchronization:** Updates and synchronizes all three `pubspec.yaml` files with the nightly version.
-   **Rolling Release:** Replaces the files in the single "Nightly Build" release under the `nightly` tag.
-   **Immutable Tag:** Creates a unique tracking tag (e.g., `nightly-20260705-fadb3b8-r300`) for historical traceability.
-   **Change Detection:** Skips execution if no commits were made since the last run.

---

## Assets Generated

Both release and nightly workflows publish:

1.  **F-Droid Universal APK** (`app-fdroid-release.apk`)
2.  **F-Droid App Bundle** (`app-fdroid-release.aab`)
3.  **Play Store App Bundle** (`app-playstore-release.aab` - Official Release only)
4.  **Zipped Web build** (`web-build.zip`)
5.  **Checksums** (`sha256sums.txt`)
