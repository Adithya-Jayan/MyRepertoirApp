# Release Workflow Documentation

## Overview

This repository uses a **single consolidated release workflow** that handles both prereleases and official releases through a unified interface.

## Workflow File

- **File:** `.github/workflows/release.yml`
- **Name:** "Create Release"

## How to Use

### 1. Manual Trigger

1.  Go to the **Actions** tab in your GitHub repository
2.  Select **"Create Release"** from the workflows list
3.  Click **"Run workflow"**
4.  Choose your release type from the dropdown:
    -   **`patch`** - Patch release (increments patch version)
    -   **`minor`** - Minor release (increments minor version)
    -   **`major`** - Major release (increments major version)
5.  Optionally, check the **`prerelease`** box to create a prerelease.
6.  Add optional release notes
7.  Click **"Run workflow"**

### 2. Release Types Explained

#### Prerelease Builds

-   **Purpose:** Development/testing builds
-   **Version Format:** `x.y.z-prerelease.N`
-   **Example:** `1.1.0` → `1.1.1-prerelease.1`
-   **Git Tag:** `v1.1.1-prerelease.1`
-   **GitHub Release:** Marked as pre-release
-   **Use Case:** Regular development builds, testing releases

#### Official Releases (`patch`, `minor`, `major`)

-   **Purpose:** Production releases
-   **Version Format:** `x.y.z`
-   **Examples:**
    -   `patch`: `1.1.0` → `1.1.1`
    -   `minor`: `1.1.0` → `1.2.0`
    -   `major`: `1.1.0` → `2.0.0`
-   **Git Tag:** `v1.1.1` (clean version)
-   **GitHub Release:** Official release (not pre-release)
-   **Use Case:** Production releases, app store releases

## Versioning Scheme

### Current Version Format

The app uses semantic versioning: `x.y.z`

### Version Increment Rules

| Release Type | Current Version | New Version         |
| ------------ | --------------- | ------------------- |
| `patch`      | `1.1.0`         | `1.1.1`             |
| `minor`      | `1.1.0`         | `1.2.0`             |
| `major`      | `1.1.0`         | `2.0.0`             |
| `prerelease` | `1.1.0`         | `1.1.1-prerelease.1` |

## What the Workflow Does

### For All Release Types:

1.  **Checks out code** with full history
2.  **Sets up Flutter** environment
3.  **Calculates new version** based on release type
4.  **Updates pubspec.yaml** with new version
5.  **Builds all platforms:**
    -   Android APK
    -   Android App Bundle
    -   Web build
6.  **Creates Git tag** and pushes changes
7.  **Creates GitHub release** with assets
8.  **Uploads build artifacts**

### Prerelease-Specific Behavior:

-   Creates a pre-release GitHub release
-   Uses `-prerelease.N` suffix in Git tags

### Official Release Behavior:

-   Creates an official GitHub release
-   Uses a clean version in Git tags

## Assets Generated

Each release includes:

-   **Android APK** (`app-release.apk`)
-   **Android App Bundle** (`app-release.aab`)
-   **Web Build** (`web_build.zip`)

## Example Workflow

### Development Cycle:

1.  **Prerelease Build:** `1.1.0` → `1.1.1-prerelease.1` → `1.1.1-prerelease.2`
2.  **Patch Release:** `1.1.1-prerelease.2` → `1.1.1`
3.  **Prerelease Build:** `1.1.1` → `1.1.2-prerelease.1`
4.  **Minor Release:** `1.1.2-prerelease.1` → `1.2.0`

### Git Tags Created:

-   `v1.1.1-prerelease.1`
-   `v1.1.1-prerelease.2`
-   `v1.1.1`
-   `v1.1.2-prerelease.1`
-   `v1.2.0`

## Benefits of Consolidated Workflow

1.  **Single Interface:** One workflow for all release types
2.  **Consistent Process:** Same build and upload process
3.  **Clear Distinction:** Prerelease vs official releases clearly marked
4.  **Version Management:** Automatic version calculation and updates
5.  **Asset Generation:** All platforms built automatically
6.  **Git Integration:** Automatic tagging and release creation

## Troubleshooting

### Common Issues:

-   **Permission Errors:** Ensure workflow has `contents: write` permission
-   **Version Conflicts:** Check that current version in `pubspec.yaml` is valid
-   **Build Failures:** Verify Flutter dependencies are up to date

### Debug Information:

The workflow provides detailed logging for:

-   Current and new version calculations
-   Git operations
-   Asset uploads

## Migration from Separate Workflows

If you previously used separate workflows:

-   **Old:** `build_and_release.yml` + `release.yml`
-   **New:** Single `release.yml` with dropdown selection
-   **Benefit:** Simplified management and consistent process