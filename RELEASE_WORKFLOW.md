# Release Workflow Documentation

## Overview

This repository uses two primary release workflows to automate the build and release process:

1.  **Create Release:** A manually triggered workflow for creating official and pre-release versions.
2.  **Nightly Build:** An automated workflow that creates a new build every day with the latest changes.

---

## 1. Create Release Workflow

-   **File:** `.github/workflows/release.yml`
-   **Name:** "Create Release"

This workflow is used to create new official and pre-release versions of the application. It automates version bumping, building for multiple platforms, and creating a GitHub release.

### How to Use

1.  Navigate to the **Actions** tab in the GitHub repository.
2.  Select the **"Create Release"** workflow.
3.  Click the **"Run workflow"** button.
4.  Fill in the required inputs:
    -   **`release_type`**: Choose the type of release (`patch`, `minor`, or `major`).
    -   **`prerelease`**: Check this box to create a pre-release version.
    -   **`release_notes`**: Add any custom notes to be included in the release description.
5.  Click **"Run workflow"** to start the release process.

**Note:** It is recommended to run this workflow on a commit that has an official release version (e.g., `1.2.3+4`) and not a pre-release version.

### Versioning Scheme

The versioning is managed by two files:

-   `pubspec.yaml`: Contains the version name (e.g., `3.1.4`).
-   `version.json`: Contains the `build_number` (e.g., `1`).

The final version string for all releases is in the format `VERSION_NAME+BUILD_NUMBER` (e.g., `3.1.4+1`).

-   **Official Release:** The `VERSION_NAME` is bumped based on the selected `release_type`, and the `build_number` is incremented.
-   **Pre-release:** A pre-release is created for the *next* version.

### Version Change Examples

| Current Version | Release Type | Prerelease | New Version             |
| --------------- | ------------ | ---------- | ----------------------- |
| `1.1.0+2`       | `patch`      | `false`    | `1.1.1+3`               |
| `1.1.0+2`       | `patch`      | `true`     | `1.1.1-prerelease.1+3`  |
| `1.1.0+2`       | `minor`      | `false`    | `1.2.0+3`               |
| `1.1.0+2`       | `minor`      | `true`     | `1.2.0-prerelease.1+3`  |
| `1.1.0+2`       | `major`      | `false`    | `2.0.0+3`               |
| `1.1.0+2`       | `major`      | `true`     | `2.0.0-prerelease.1+3`  |

### F-Droid Versioning

The workflow generates F-Droid compatible version codes for each CPU architecture (ABI) to ensure that F-Droid can correctly handle the updates.

### What the Workflow Does

1.  **Calculates the next version** and build number.
2.  **Updates `pubspec.yaml` and `version.json`**.
3.  **Builds the application** for the `fdroid` flavor:
    -   Android APKs for `armeabi-v7a`, `arm64-v8a`, and `x86_64`.
    -   Android App Bundle.
    -   Web build.
4.  **Generates checksums** for all release assets.
5.  **Creates a Git tag** in the format `vVERSION_NAME+BUILD_NUMBER`.
6.  **Commits and pushes** the version file changes to the repository.
7.  **Generates automated release notes** based on the commits since the last release.
8.  **Creates an F-Droid changelog** file.
9.  **Publishes a GitHub release** with the generated assets and release notes.

---

## 2. Nightly Build Workflow

-   **File:** `.github/workflows/nightly.yml`
-   **Name:** "Nightly Build"

This workflow automatically creates a new build every day, providing the latest version of the app for testing.

### How it Works

-   **Trigger:** Runs on a schedule (daily at 16:30 UTC) and can also be triggered manually.
-   **Versioning:** Creates a version with the format `0.0.0-nightly-YYYYMMDD-SHORT_SHA-rRUN_NUMBER`.
-   **Rolling Release:** A single, "rolling" pre-release named "Nightly Build" is updated with the latest build. This release is associated with the `nightly` tag.
-   **Immutable Tag:** A unique, immutable tag (e.g., `nightly-20231025-abcdef-r123`) is created for each nightly build to ensure that every build is traceable.
-   **No Changes:** If no new commits have been pushed since the last successful nightly build, the workflow will skip the build process to save resources.

### What the Workflow Does

1.  **Checks for new commits**.
2.  **Calculates the nightly version**.
3.  **Updates `pubspec.yaml`** with the new version.
4.  **Builds the application** for the `nightly` flavor.
5.  **Generates checksums** for the build assets.
6.  **Updates the "Nightly Build" release** on GitHub with the new assets.
7.  **Creates and pushes an immutable Git tag** for the new nightly build.

## Assets Generated

Both workflows generate the following assets:

-   **Android APK**
-   **Android App Bundle**
-   **Web Build (zipped)**
-   **Checksums** for the assets