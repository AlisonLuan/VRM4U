# Build Version Configuration Guide

## Overview

The VRM4U multi-version build system (`build_5.bat` and `build_all.bat`) supports configurable version lists with resilient handling of missing UE installations.

## Key Features

- **Configurable version list** via environment variable or config file
- **Skip missing versions** by default (with clear warnings)
- **Strict mode** for CI/automated builds (fail if any version missing)
- **Build summary** showing which versions were built vs skipped

## Configuration Methods

### Method 1: Environment Variable (Recommended for CI)

Set `BUILD_UE_VERSIONS` with comma-separated version list:

```batch
set BUILD_UE_VERSIONS=5.7,5.6,5.5
call build_all.bat
```

**Pros:**
- Easy to set in CI/CD pipelines
- No file management needed
- Can be set per-session

**Cons:**
- Must be set each time
- Not persisted across sessions

### Method 2: versions.txt File (Recommended for Local Development)

1. Copy the example file:
   ```batch
   copy versions.txt.example versions.txt
   ```

2. Edit `versions.txt` and uncomment/add your desired versions:
   ```
   # My installed versions
   5.7
   5.6
   # 5.5 is not installed, so commented out
   ```

3. Run the build script normally:
   ```batch
   call build_all.bat
   ```

**Pros:**
- Persistent configuration
- Easy to share among team members (by example file)
- Supports comments for documentation

**Cons:**
- Requires file management
- Gitignored (intentional - local config)

### Method 3: Default Hard-Coded List

If neither environment variable nor `versions.txt` exists, the script uses:
- 5.7, 5.6, 5.5, 5.4, 5.3, 5.2

**Pros:**
- No configuration needed
- Works out-of-box

**Cons:**
- May try to build versions you don't have installed
- Requires updating the script to change

## Configuration Precedence

1. **BUILD_UE_VERSIONS** environment variable (highest priority)
2. **versions.txt** file
3. **Default hard-coded list** (lowest priority)

## Skip vs Strict Mode

### Default: Skip Missing Versions

By default, if a UE version is not installed:

1. The script prints a detailed warning with:
   - Which version is missing
   - Expected installation path
   - How to fix (install, remove from list, or set UE_ROOT)

2. The version is **skipped** and the build continues

3. Final summary shows:
   ```
   Versions built: 2
     > 5.7, 5.6
   Versions skipped: 1
     > 5.5
   ```

**Example output:**
```
[build_5] ========================================
[build_5] WARNING: UE 5.5 not installed
[build_5] ========================================
[ERROR] Version directory not found: C:\Program Files\Epic Games\UE_5.5

[build_5] How to fix:
[build_5]   Option 1: Install UE 5.5 via Epic Games Launcher
[build_5]   Option 2: Remove 5.5 from your version list:
[build_5]            - Edit C:\...\Source\ReleaseScript\versions.txt
[build_5]   Option 3: Set environment variable to specify UE path:
[build_5]            - set UE_ROOT=C:\Path\To\Epic Games

[build_5] Skipping UE 5.5 and continuing...
```

### Strict Mode: Fail on Missing Versions

For CI/CD or when you want to ensure all versions are built:

```batch
set STRICT_VERSIONS=1
call build_all.bat
```

In strict mode, if ANY version is missing:
1. The same detailed warning is printed
2. The script **exits immediately** with error code 1
3. No subsequent versions are attempted

**Use strict mode when:**
- Running in CI/CD (ensure complete builds)
- Creating official releases
- You want to catch missing versions early

## Platform Configurations

Each UE version has specific platform configurations:

| Version | Platforms |
|---------|-----------|
| 5.7 | Win64 (Shipping), Android (Development), Linux (Shipping) |
| 5.6 | Win64 (Shipping), Android (Development) |
| 5.5 | Win64 (Shipping), Win64 (Debug) |
| 5.4-5.2 | Win64 (Shipping) |

Platform configurations are hard-coded in `build_5.bat`. To customize:
- Edit the `:build_version` subroutine
- Add/remove `call :build_platform` lines

## Integration with UE Path Resolution

The version checking uses `resolve_ue_path.bat` to:
1. Resolve UE installation path (env var, config file, or auto-detect)
2. Validate that required files exist (RunUAT.bat, UnrealEditor.exe)

If resolution fails, the version is considered "not installed."

## Examples

### Example 1: Local Development (Only UE 5.7 Installed)

```batch
REM Create versions.txt
echo 5.7 > Source\ReleaseScript\versions.txt

REM Run build
call Source\ReleaseScript\build_all.bat

REM Output:
REM [build_5] Using versions.txt
REM [build_5] Versions to build: 5.7
REM [build_5] Processing UE 5.7
REM [build_5] UE 5.7 found - proceeding with builds
REM [build_5] Building: UE 5.7 / Win64 / Shipping
REM [build_5] Building: UE 5.7 / Android / Development
REM [build_5] Building: UE 5.7 / Linux / Shipping
REM [build_5] Build Summary
REM [build_5] Versions built: 1
REM [build_5]   > 5.7
REM [build_5] Versions skipped: 0
```

### Example 2: CI Build with Multiple Versions (Strict Mode)

```batch
REM Set versions and strict mode
set BUILD_UE_VERSIONS=5.7,5.6,5.5
set STRICT_VERSIONS=1

REM Set UE base path (if not using default location)
set UE_ROOT=D:\UnrealEngines

REM Run build
call Source\ReleaseScript\build_all.bat

REM If any version is missing:
REM [build_5] WARNING: UE 5.5 not installed
REM [build_5] [ERROR] STRICT_VERSIONS=1 - Failing build due to missing version
REM Exit code: 1
```

### Example 3: Build Specific Versions Only

```batch
REM Override to build only 5.7 and 5.4
set BUILD_UE_VERSIONS=5.7,5.4
call Source\ReleaseScript\build_5.bat

REM Skips 5.6, 5.5, 5.3, 5.2 entirely
```

### Example 4: Check What Would Be Built

To see which versions would be built without actually building:

```batch
REM Set versions
set BUILD_UE_VERSIONS=5.7,5.6,5.5

REM Run resolve_ue_path for each to check
call Source\ReleaseScript\resolve_ue_path.bat 5.7
call Source\ReleaseScript\resolve_ue_path.bat 5.6
call Source\ReleaseScript\resolve_ue_path.bat 5.5
```

## Troubleshooting

### "No versions were successfully built"

**Cause:** All configured versions are missing or failed validation

**Fix:**
1. Check which versions you have installed
2. Update `versions.txt` or `BUILD_UE_VERSIONS` to match
3. Or install missing versions via Epic Games Launcher

### "Build failed for UE X.Y"

**Cause:** Build process failed (not a missing version issue)

**Fix:**
1. Check the error output from UAT BuildPlugin
2. Ensure required dependencies are installed
3. Check output path is writable (`VRM4U_OUTPATH`)

### Versions file not being read

**Cause:** File doesn't exist or has wrong name

**Fix:**
1. Ensure file is named `versions.txt` (not `versions.txt.txt`)
2. Place in `Source/ReleaseScript/` directory
3. Check that `BUILD_UE_VERSIONS` env var is not set (takes precedence)

### All versions skipped in CI

**Cause:** UE installations not found by auto-detection

**Fix:**
1. Set `UE_ROOT` environment variable:
   ```batch
   set UE_ROOT=C:\Program Files\Epic Games
   ```
2. Or create `ue_path.config` with your UE base path

## Best Practices

### For Local Development
1. Create `versions.txt` with only your installed versions
2. Keep `STRICT_VERSIONS` unset (default skip behavior)
3. Review build summary to ensure expected versions were built

### For CI/CD
1. Use `BUILD_UE_VERSIONS` environment variable
2. Set `STRICT_VERSIONS=1` to catch missing versions
3. Set `UE_ROOT` to point to CI engine installations
4. Log the configuration at build start:
   ```batch
   echo UE_ROOT=%UE_ROOT%
   echo BUILD_UE_VERSIONS=%BUILD_UE_VERSIONS%
   echo STRICT_VERSIONS=%STRICT_VERSIONS%
   ```

### For Release Builds
1. Use strict mode to ensure all target versions are built
2. Review build summary before publishing
3. Keep `versions.txt.example` updated with current release targets

## Related Documentation

- [resolve_ue_path.bat Guide](./QUICK_REFERENCE.md) - UE path resolution
- [TEST_PLAN.md](./TEST_PLAN.md) - Testing UE path resolution
- [VERSION_SCRIPT_GUIDE.md](./VERSION_SCRIPT_GUIDE.md) - version.ps1 usage
- [ue_path.config.example](./ue_path.config.example) - UE path config

## Changelog

### 2026-01-10 - Initial Implementation
- Added configurable version list via `BUILD_UE_VERSIONS` and `versions.txt`
- Implemented skip-on-missing default behavior
- Added `STRICT_VERSIONS` strict mode
- Added build summary reporting
- Created `versions.txt.example` configuration template
