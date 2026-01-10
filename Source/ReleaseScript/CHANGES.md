# Release Script Changes - Changelog

## 2026-01-10: Resilient Version Handling

### Issue
The multi-version build scripts (`build_5.bat`, `build_all.bat`) would fail completely if any configured UE version was not installed, preventing builds of installed versions. This created barriers for contributors who don't have all engine versions installed.

### Changes Made

#### 1. Configurable Version List

**Before**: Hard-coded version list in build_5.bat (lines 6-73)
```batch
::5_7
call %BUILD_SCRIPT% 5.7 Win64 Shipping VRM4U_5_7_%V_DATE%.zip
...
::5_6
call %BUILD_SCRIPT% 5.6 Win64 Shipping VRM4U_5_6_%V_DATE%.zip
...
```

**After**: Three configuration methods with precedence:

1. **BUILD_UE_VERSIONS** environment variable (highest priority)
```batch
set BUILD_UE_VERSIONS=5.7,5.6
build_5.bat
```

2. **versions.txt** file
```
# My installed versions
5.7
5.6
```

3. **Default list** (lowest priority): 5.7,5.6,5.5,5.4,5.3,5.2

#### 2. Skip-on-Missing Behavior (Default)

**Before**: Script failed immediately when a version was not found
```batch
if not %errorlevel% == 0 (
    echo [ERROR] :P
    goto err
)
```

**After**: Script skips missing versions by default with detailed warnings
```batch
if !RESOLVE_EXIT_CODE! == 0 (
    REM Version found - build it
) else (
    echo [build_5] WARNING: UE !CURRENT_VERSION! not installed
    REM Show detailed error and how to fix
    if "%STRICT_VERSIONS%"=="1" (
        goto err  REM Fail in strict mode
    ) else (
        REM Skip and continue
    )
)
```

**Output example**:
```
[build_5] Processing UE 5.6
[build_5] WARNING: UE 5.6 not installed
[build_5] How to fix:
[build_5]   Option 1: Install UE 5.6 via Epic Games Launcher
[build_5]   Option 2: Remove 5.6 from your version list
[build_5]   Option 3: Set UE_ROOT environment variable
[build_5] Skipping UE 5.6 and continuing...
```

#### 3. Strict Mode for CI

**Usage**:
```batch
set STRICT_VERSIONS=1
build_5.bat
```

**Behavior**: Fails immediately if any configured version is missing
- Prints detailed error with expected path
- Shows how to fix the issue
- Exit code 1 (failure)

#### 4. Build Summary Reporting

**After each build run**:
```
[build_5] Build Summary
[build_5] Versions built: 2
[build_5]   > 5.7, 5.6
[build_5] Versions skipped: 4
[build_5]   > 5.5, 5.4, 5.3, 5.2
[build_5] SUCCESS - Build completed
```

#### 5. Refactored Build Logic

- Separated version iteration from platform builds
- Created `:build_version` subroutine for version-specific platform configs
- Created `:build_platform` subroutine for individual builds
- Improved error messages and logging
- Added build tracking (BUILD_COUNT, SKIP_COUNT, etc.)

### Files Modified

```
.gitignore                                       (added versions.txt)
Source/ReleaseScript/build_5.bat                 (major refactor)
BUILDING.md                                      (added section 3)
Source/ReleaseScript/QUICK_REFERENCE.md          (added version config section)
```

### Files Created

```
Source/ReleaseScript/versions.txt.example        (2.1 KB)
Source/ReleaseScript/BUILD_VERSION_CONFIG.md     (8.4 KB)
Source/ReleaseScript/TEST_PLAN_VERSIONS.md       (8.5 KB)
```

### Backward Compatibility

✅ **Fully backward compatible**

- If no configuration provided, uses same default list as before
- Default behavior is more permissive (skip vs fail) - safer
- All existing environment variables still work
- No changes to build_ver2.bat or other scripts
- No breaking changes to command-line usage

### Testing Performed

#### Logic Verification (Bash Simulation)
```
✓ Default skip mode with mixed installed/missing versions
✓ Strict mode fails on first missing version
✓ versions.txt parsing (comments, blank lines, trimming)
✓ Configuration precedence (env var > file > default)
✓ Build counting and summary reporting
```

#### Manual Testing Required
⚠️ Windows batch scripts cannot be executed on Linux CI
📋 Comprehensive test plan provided: TEST_PLAN_VERSIONS.md (13 scenarios)

### Usage Examples

#### Example 1: Local Dev (Only UE 5.7)
```batch
cd Source\ReleaseScript
build_5.bat
```
**Result**: ✅ Builds 5.7, skips 5.6-5.2, succeeds

#### Example 2: CI (Strict Mode)
```batch
set BUILD_UE_VERSIONS=5.7,5.6
set STRICT_VERSIONS=1
set UE_ROOT=D:\UE
build_5.bat
```
**Result**: ❌ Fails if either 5.7 or 5.6 missing

#### Example 3: Custom Config
```batch
copy versions.txt.example versions.txt
notepad versions.txt  # Edit to: 5.7, 5.6 only
build_5.bat
```
**Result**: ✅ Builds only 5.7 and 5.6

### Benefits

**For Contributors**:
- ✅ Build with only one UE version installed
- ✅ Clear warnings show what's missing and how to fix
- ✅ No need to install all engine versions

**For CI/CD**:
- ✅ Strict mode ensures complete builds
- ✅ Environment variable configuration
- ✅ Clear exit codes (0=success, 1=failure)

**For Maintainers**:
- ✅ Reduces "build fails for me" support requests
- ✅ Easier contributor onboarding
- ✅ Centralized version configuration

### Documentation Added

1. **BUILD_VERSION_CONFIG.md** (8.4 KB)
   - Detailed configuration guide
   - All configuration methods
   - Skip vs strict mode explained
   - Examples for common scenarios
   - Troubleshooting section
   - Best practices for local dev and CI

2. **TEST_PLAN_VERSIONS.md** (8.5 KB)
   - 13 manual test scenarios
   - Covers all features and edge cases
   - Validation checklist
   - Troubleshooting during testing
   - Success criteria

3. **versions.txt.example** (2.1 KB)
   - Template configuration
   - Commented version list
   - Usage instructions
   - Platform configuration notes

4. **BUILDING.md** - Added Section 3
   - "Configure Which Versions to Build (Optional)"
   - Documents all configuration methods
   - Examples and best practices

5. **QUICK_REFERENCE.md** - Updated
   - Renamed to "VRM4U Build Scripts"
   - Added version configuration section
   - Added skip vs strict mode section

### Security Considerations

✅ **No new security concerns**

- No network operations
- No credential handling
- Only reads local config files
- Validates UE paths before use
- Same file permissions as before

### Future Enhancements (Not Implemented)

Potential improvements for future work:
- PowerShell version for cross-platform support
- Per-version platform configuration in versions.txt
- CI status integration (GitHub Actions, etc.)
- Automated testing on Windows CI

---

## 2024-XX-XX: Version Script Fix

### Issue
The release scripts had two main problems:
1. **version.ps1 reliability**: Failed to parse JSON files, looked for non-existent project files, and had poor error handling
2. **Git behavior**: Concerns about scripts unexpectedly changing repository state

## Changes Made

### 1. version.ps1 Refactoring

#### Before
- Hard-coded path to `MyProjectBuildScript.uproject` that doesn't exist
- Silently exited when file not found (could mask errors)
- Used fragile relative paths (`../../../VRM4U/VRM4U.uplugin`)
- Poor error handling with generic warnings
- JSON output could be truncated (no depth parameter)

#### After
- **Explicit parameter**: Takes `<EngineVersion>` and optional `[TargetFilePath]`
- **Two modes**:
  - Plugin-only mode (no target file): Used by build_ver2.bat
  - Project mode (with target file): Used by build_ver.bat
- **Absolute paths**: Uses `$MyInvocation.MyCommand.Path` and `Resolve-Path`
- **Robust error handling**:
  - File existence check before reading
  - JSON parse errors with excerpts
  - Module/Plugin count validation
- **UTF-8 BOM handling**: Properly reads files with or without BOM
- **JSON depth preservation**: Uses `-Depth 10` to prevent truncation
- **Actionable errors**: Exit code 1 with clear error messages

### 2. build_ver2.bat Updates

#### Before
```batch
powershell -ExecutionPolicy RemoteSigned .\version.ps1 \"%UE5VER%\"
```

#### After
```batch
echo [build_ver2] Running version.ps1 to update plugin for UE %UE5VER%...
powershell -ExecutionPolicy RemoteSigned .\version.ps1 "%UE5VER%"
if not %errorlevel% == 0 (
    echo [ERROR] version.ps1 failed
    goto err
)
```

**Changes**:
- Removed unnecessary backslash escaping in parameter
- Added informative log message
- Added error checking and proper failure handling

### 3. build_ver.bat Updates

#### Before
```batch
powershell -ExecutionPolicy RemoteSigned .\version.ps1 \"%UE4VER%\"
```

#### After
```batch
set PROJECTNAME="../../../../MyProjectBuildScript.uproject"
echo [build_ver] Running version.ps1 to update project file for UE %UE4VER%...
powershell -ExecutionPolicy RemoteSigned .\version.ps1 "%UE4VER%" %PROJECTNAME%
if not %errorlevel% == 0 (
    echo [ERROR] version.ps1 failed
    goto err
)
```

**Changes**:
- Passes PROJECTNAME as second parameter to version.ps1
- Added informative log message
- Added error checking and proper failure handling
- Removed duplicate PROJECTNAME definition later in the script

### 4. Git Behavior Improvements

Both `build_ver.bat` and `build_ver2.bat` already had git reset protection via `RELEASESCRIPT_GIT_RESET` environment variable (this was added in a previous fix).

**Enhanced comments**:
```batch
REM Resetting to current HEAD...
```

This clarifies that the script only resets to the **current** HEAD, not a specific branch or remote state.

### 5. Documentation Added

Three new documentation files:

1. **VERSION_SCRIPT_GUIDE.md** (178 lines)
   - Complete usage guide for version.ps1
   - Parameter documentation
   - Version-specific modifications explained
   - Error handling examples
   - Testing instructions
   - Troubleshooting guide

2. **GIT_BEHAVIOR_GUIDE.md** (214 lines)
   - Explanation of default safe behavior
   - How to opt-in to git reset
   - Safety features (no branch switching, no pull)
   - Use cases (good and bad)
   - Best practices
   - Troubleshooting

3. **QUICK_REFERENCE.md** (updated)
   - Added links to new guides

## Testing Performed

### Test 1: Plugin-only mode (modern UE)
```
✓ UE 5.7 - No modifications needed
```

### Test 2: Plugin-only mode (legacy UE)
```
✓ UE 4.27 - Correctly removed plugins and modules
```

### Test 3: Project mode
```
✓ Updated .uproject EngineAssociation from 5.0 to 5.7
```

### Test 4: Error handling
```
✓ Non-existent file - Exit code 1 with clear error message
✓ Malformed JSON - Exit code 1 with error details and excerpt
```

## Backward Compatibility

✅ **Fully backward compatible**

- Existing build scripts continue to work
- Git behavior unchanged (already had RELEASESCRIPT_GIT_RESET check)
- version.ps1 maintains same functionality when called with one parameter
- New features are additive (optional second parameter)

## Migration Guide

**No action needed!** The changes are transparent to users.

For CI/CD pipelines:
- Scripts already use `RELEASESCRIPT_GIT_RESET=1` (if needed)
- No changes required to existing automation

## Security Considerations

✅ **No new security concerns**

- Scripts still modify the same files (VRM4U.uplugin, .uproject)
- Git reset is still opt-in only
- No network operations added
- No credential handling

## Future Improvements (Not Implemented)

Potential enhancements for future work:
- JSON schema validation for .uplugin files
- Dry-run mode to preview changes
- Backup/restore functionality for modified files
- Support for multiple .uplugin modifications in one invocation

## Files Modified

```
Source/ReleaseScript/version.ps1            (rewritten)
Source/ReleaseScript/build_ver2.bat         (minor changes)
Source/ReleaseScript/build_ver.bat          (minor changes)
Source/ReleaseScript/QUICK_REFERENCE.md     (updated links)
Source/ReleaseScript/VERSION_SCRIPT_GUIDE.md (new)
Source/ReleaseScript/GIT_BEHAVIOR_GUIDE.md  (new)
```

## Issue Resolution

### Problem A - version.ps1 breaks / does nothing
✅ **FIXED**
- Robust JSON parsing with clear error messages
- File existence validation
- Proper encoding handling (UTF-8 with BOM support)
- Actionable error diagnostics

### Problem B - script changes repository state
✅ **VERIFIED SAFE**
- Git reset is opt-in via RELEASESCRIPT_GIT_RESET=1
- Resets only to current HEAD (no branch switching)
- Well documented with warnings
- Safe default for local development
