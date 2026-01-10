# Test Plan for Resilient Version Handling

## Overview
This document describes manual tests for the new resilient version handling in `build_5.bat` and `build_all.bat`.

## Prerequisites
- Windows machine with batch script support
- At least one UE version installed (e.g., 5.7)
- Access to `Source/ReleaseScript/` directory

## Test Scenarios

### Test 1: Default Behavior - All Versions Installed
**Setup:**
- Have UE 5.7, 5.6, and 5.5 installed in standard Epic Games location
- No `versions.txt` file
- No `BUILD_UE_VERSIONS` environment variable

**Steps:**
```batch
cd Source\ReleaseScript
call build_5.bat
```

**Expected Result:**
- Script uses default hard-coded list (5.7, 5.6, 5.5, 5.4, 5.3, 5.2)
- Prints: "Using default version list"
- Builds all installed versions successfully
- Skips missing versions (5.4, 5.3, 5.2) with warnings
- Final summary shows:
  ```
  Versions built: 3
    > 5.7, 5.6, 5.5
  Versions skipped: 3
    > 5.4, 5.3, 5.2
  ```
- Exit code 0 (success)

### Test 2: Skip Missing Version (Default Mode)
**Setup:**
- Only UE 5.7 installed
- No `versions.txt` file
- No `BUILD_UE_VERSIONS` environment variable

**Steps:**
```batch
cd Source\ReleaseScript
call build_5.bat
```

**Expected Result:**
- Script tries to build versions: 5.7, 5.6, 5.5, 5.4, 5.3, 5.2
- UE 5.7 builds successfully
- For each missing version (5.6, 5.5, etc.):
  - Prints warning: "WARNING: UE X.Y not installed"
  - Shows expected path
  - Shows 3 options to fix
  - Prints: "Skipping UE X.Y and continuing..."
- Final summary:
  ```
  Versions built: 1
    > 5.7
  Versions skipped: 5
    > 5.6, 5.5, 5.4, 5.3, 5.2
  ```
- Exit code 0 (success)

### Test 3: Strict Mode - Fail on Missing Version
**Setup:**
- Only UE 5.7 installed
- No `versions.txt` file

**Steps:**
```batch
cd Source\ReleaseScript
set STRICT_VERSIONS=1
call build_5.bat
```

**Expected Result:**
- UE 5.7 builds successfully
- When reaching UE 5.6 (not installed):
  - Prints warning: "WARNING: UE 5.6 not installed"
  - Shows expected path and fix options
  - Prints: "[ERROR] STRICT_VERSIONS=1 - Failing build due to missing version"
  - Script exits immediately
- No final summary (early exit)
- Exit code 1 (failure)

### Test 4: Environment Variable Configuration
**Setup:**
- UE 5.7 and 5.6 installed
- No `versions.txt` file

**Steps:**
```batch
cd Source\ReleaseScript
set BUILD_UE_VERSIONS=5.7,5.6
call build_5.bat
```

**Expected Result:**
- Prints: "Using BUILD_UE_VERSIONS environment variable"
- Prints: "Version source: BUILD_UE_VERSIONS environment variable"
- Prints: "Versions to build: 5.7,5.6"
- Builds only 5.7 and 5.6 (skips all others)
- Final summary:
  ```
  Versions built: 2
    > 5.7, 5.6
  Versions skipped: 0
  ```
- Exit code 0

### Test 5: versions.txt Configuration
**Setup:**
- UE 5.7 and 5.5 installed
- Create `versions.txt` with content:
  ```
  # Only build these versions
  5.7
  5.5
  ```

**Steps:**
```batch
cd Source\ReleaseScript
call build_5.bat
```

**Expected Result:**
- Prints: "Found versions.txt file"
- Prints: "Version source: versions.txt"
- Prints: "Versions to build: 5.7,5.5"
- Builds 5.7 and 5.5 only
- Final summary:
  ```
  Versions built: 2
    > 5.7, 5.5
  Versions skipped: 0
  ```
- Exit code 0

### Test 6: versions.txt with Comments and Blank Lines
**Setup:**
- Create `versions.txt` with content:
  ```
  # Build configuration
  
  # Latest version
  5.7
  
  # Skip 5.6 - not installed
  # 5.6
  
  5.5
  
  # End of list
  ```

**Steps:**
```batch
cd Source\ReleaseScript
call build_5.bat
```

**Expected Result:**
- Correctly parses only uncommented versions: 5.7, 5.5
- Ignores comment lines and blank lines
- Builds requested versions

### Test 7: Configuration Precedence
**Setup:**
- Create `versions.txt` with: `5.5`
- Set environment variable

**Steps:**
```batch
cd Source\ReleaseScript
set BUILD_UE_VERSIONS=5.7
call build_5.bat
```

**Expected Result:**
- Uses `BUILD_UE_VERSIONS` (precedence over versions.txt)
- Prints: "Using BUILD_UE_VERSIONS environment variable"
- Builds only 5.7
- Exit code 0

### Test 8: No Versions Built
**Setup:**
- Only UE 5.7 installed

**Steps:**
```batch
cd Source\ReleaseScript
set BUILD_UE_VERSIONS=5.6,5.5
call build_5.bat
```

**Expected Result:**
- Tries to build 5.6 and 5.5 (both missing)
- Skips both with warnings
- Final summary:
  ```
  Versions built: 0
  Versions skipped: 2
    > 5.6, 5.5
  ```
- Prints: "[ERROR] No versions were successfully built!"
- Exit code 1 (failure)

### Test 9: Integration with build_all.bat
**Setup:**
- UE 5.7 installed

**Steps:**
```batch
cd Source\ReleaseScript
set BUILD_UE_VERSIONS=5.7
call build_all.bat
```

**Expected Result:**
- `build_all.bat` calls `build_5.bat`
- `build_5.bat` builds UE 5.7 successfully
- `build_all.bat` then calls `build_old.bat`
- Overall exit code depends on both scripts

### Test 10: Platform Configuration
**Setup:**
- UE 5.7 installed
- Set to build only 5.7

**Steps:**
```batch
cd Source\ReleaseScript
set BUILD_UE_VERSIONS=5.7
call build_5.bat
```

**Expected Result:**
- Builds 3 packages for UE 5.7:
  1. VRM4U_5_7_YYYYMMDD.zip (Win64 Shipping)
  2. VRM4U_5_7_YYYYMMDD_android.zip (Android Development)
  3. VRM4U_5_7_YYYYMMDD_linux.zip (Linux Shipping)
- Each build prints: "Building: UE 5.7 / Platform / Config -> ZipName"

### Test 11: Build Failure Handling
**Setup:**
- UE 5.7 installed but UAT build fails (simulate by setting bad OUTPATH)

**Steps:**
```batch
cd Source\ReleaseScript
set BUILD_UE_VERSIONS=5.7
set VRM4U_OUTPATH=Z:\NonExistent\Path
call build_5.bat
```

**Expected Result:**
- Starts building UE 5.7
- `build_ver2.bat` fails with error about output path
- Script prints: "[ERROR] Build failed for UE 5.7 Win64 Shipping"
- Script exits immediately
- Exit code 1 (failure)

### Test 12: Custom UE Path with Skip Behavior
**Setup:**
- UE installations in non-standard location: `D:\MyEngines`
- Only `D:\MyEngines\UE_5.7` exists

**Steps:**
```batch
cd Source\ReleaseScript
set UE_ROOT=D:\MyEngines
call build_5.bat
```

**Expected Result:**
- Uses custom UE path
- Finds UE 5.7 at D:\MyEngines\UE_5.7
- Builds UE 5.7 successfully
- Skips other versions (not found at custom path)
- Exit code 0

### Test 13: Strict Mode with Custom Versions
**Setup:**
- UE 5.7 and 5.6 installed

**Steps:**
```batch
cd Source\ReleaseScript
set BUILD_UE_VERSIONS=5.7,5.6,5.5
set STRICT_VERSIONS=1
call build_5.bat
```

**Expected Result:**
- Builds UE 5.7 successfully
- Builds UE 5.6 successfully
- Fails on UE 5.5 (not installed)
- Prints error and exits
- Exit code 1

## Validation Checklist

After running tests:

- [ ] Skip mode works (missing versions skipped, build continues)
- [ ] Strict mode works (missing versions cause immediate failure)
- [ ] Environment variable configuration works
- [ ] versions.txt configuration works
- [ ] Configuration precedence is correct (env > file > default)
- [ ] Comments and blank lines in versions.txt are handled
- [ ] Build summary is accurate (counts and lists correct)
- [ ] Error messages are clear and actionable
- [ ] Platform configurations are preserved for each version
- [ ] Integration with build_all.bat works
- [ ] Exit codes are correct (0 for success, 1 for failure)
- [ ] No regression in existing functionality

## Success Criteria

All tests should:
1. Execute without syntax errors
2. Produce expected output messages
3. Return correct exit codes
4. Build correct versions
5. Generate expected .zip files

## Notes

- These tests require Windows with batch script support
- Tests 1-3 validate core functionality (highest priority)
- Tests 4-7 validate configuration methods
- Tests 8-13 validate edge cases and integrations
- Manual testing is required (no automated test framework)
- Consider testing on multiple machines with different UE installations

## Troubleshooting During Testing

### Script doesn't detect versions.txt
- Check file name (not `versions.txt.txt`)
- Ensure file is in `Source/ReleaseScript/` directory
- Check that `BUILD_UE_VERSIONS` is not set

### All versions are skipped
- Check UE installation paths with `resolve_ue_path.bat`
- Set `UE_ROOT` environment variable
- Create `ue_path.config` file

### Syntax errors in batch script
- Ensure Windows line endings (CRLF)
- Check for special characters in paths
- Run from correct directory

## Post-Test Actions

After successful testing:
1. Document any issues found
2. Update this test plan if needed
3. Create `versions.txt` with your preferred configuration
4. Consider adding test results to documentation
