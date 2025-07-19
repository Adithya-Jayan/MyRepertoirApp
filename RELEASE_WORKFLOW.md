# Release Workflow Documentation

## Overview

This repository uses a **single consolidated release workflow** that handles both alpha builds and official releases through a unified interface.

## Workflow File

- **File:** `.github/workflows/release.yml`
- **Name:** "Consolidated Release"

## How to Use

### 1. Manual Trigger

1. Go to the **Actions** tab in your GitHub repository
2. Select **"Consolidated Release"** from the workflows list
3. Click **"Run workflow"**
4. Choose your release type from the dropdown:
   - **`alpha`** - Alpha build (increments build number only)
   - **`patch`** - Patch release (increments patch version)
   - **`minor`** - Minor release (increments minor version)
   - **`major`** - Major release (increments major version)
5. Add optional release notes
6. Click **"Run workflow"**

### 2. Release Types Explained

#### Alpha Builds (`alpha`)
- **Purpose:** Development/testing builds
- **Version Format:** `x.y.z+b` (keeps build metadata)
- **Example:** `1.1.0+3` → `1.1.0+4`
- **Git Tag:** `v1.1.0+4-alpha`
- **GitHub Release:** Marked as pre-release
- **Use Case:** Regular development builds, testing releases

#### Official Releases (`patch`, `minor`, `major`)
- **Purpose:** Production releases
- **Version Format:** `x.y.z` (drops build metadata)
- **Examples:**
  - `patch`: `1.1.0+3` → `1.1.1`
  - `minor`: `1.1.0+3` → `1.2.0`
  - `major`: `1.1.0+3` → `2.0.0`
- **Git Tag:** `v1.1.1` (clean version)
- **GitHub Release:** Official release (not pre-release)
- **Use Case:** Production releases, app store releases

## Versioning Scheme

### Current Version Format
The app uses semantic versioning with build metadata: `x.y.z+b`
- `x.y.z` = Semantic version (major.minor.patch)
- `+b` = Build number (optional)

### Version Increment Rules

| Release Type | Current Version | New Version | Build Number |
|--------------|----------------|-------------|--------------|
| `alpha` | `1.1.0+3` | `1.1.0+4` | Incremented |
| `patch` | `1.1.0+3` | `1.1.1` | Reset to 1 |
| `minor` | `1.1.0+3` | `1.2.0` | Reset to 1 |
| `major` | `1.1.0+3` | `2.0.0` | Reset to 1 |

## What the Workflow Does

### For All Release Types:
1. **Checks out code** with full history
2. **Sets up Flutter** environment
3. **Calculates new version** based on release type
4. **Updates pubspec.yaml** with new version
5. **Builds all platforms:**
   - Android APK
   - Android App Bundle
   - Web build
6. **Creates Git tag** and pushes changes
7. **Creates GitHub release** with assets
8. **Uploads build artifacts**

### Alpha-Specific Behavior:
- Keeps build metadata (`+b`)
- Creates pre-release GitHub release
- Uses `-alpha` suffix in Git tags
- Increments build number only

### Official Release Behavior:
- Drops build metadata (clean `x.y.z`)
- Creates official GitHub release
- Uses clean version in Git tags
- Resets build number to 1

## Assets Generated

Each release includes:
- **Android APK** (`app-release.apk`)
- **Android App Bundle** (`app-release.aab`)
- **Web Build** (`web_build.zip`)

## Example Workflow

### Development Cycle:
1. **Alpha Build:** `1.1.0+1` → `1.1.0+2` → `1.1.0+3`
2. **Patch Release:** `1.1.0+3` → `1.1.1`
3. **Alpha Build:** `1.1.1+1` → `1.1.1+2`
4. **Minor Release:** `1.1.1+2` → `1.2.0`

### Git Tags Created:
- `v1.1.0+1-alpha`
- `v1.1.0+2-alpha`
- `v1.1.0+3-alpha`
- `v1.1.1`
- `v1.1.1+1-alpha`
- `v1.1.1+2-alpha`
- `v1.2.0`

## Benefits of Consolidated Workflow

1. **Single Interface:** One workflow for all release types
2. **Consistent Process:** Same build and upload process
3. **Clear Distinction:** Alpha vs official releases clearly marked
4. **Version Management:** Automatic version calculation and updates
5. **Asset Generation:** All platforms built automatically
6. **Git Integration:** Automatic tagging and release creation

## Troubleshooting

### Common Issues:
- **Permission Errors:** Ensure workflow has `contents: write` permission
- **Version Conflicts:** Check that current version in `pubspec.yaml` is valid
- **Build Failures:** Verify Flutter dependencies are up to date

### Debug Information:
The workflow provides detailed logging for:
- Current and new version calculations
- Build number increments
- Git operations
- Asset uploads

## Migration from Separate Workflows

If you previously used separate workflows:
- **Old:** `build_and_release.yml` + `release.yml`
- **New:** Single `release.yml` with dropdown selection
- **Benefit:** Simplified management and consistent process 