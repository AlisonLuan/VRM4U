# Version Script Fix - Change Summary

## Issue
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
