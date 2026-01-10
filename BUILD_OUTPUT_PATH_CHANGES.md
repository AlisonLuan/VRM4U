# Build Output Path Changes

## Summary

The build scripts have been updated to fix the hardcoded `D:\tmp\_out` directory issue. The scripts now use a safe, configurable output directory that works on all Windows machines.

## What Changed

### 1. Smart Output Directory Resolution (`build_ver2.bat`)

The script now uses a precedence-based approach for determining the output directory:

1. **`VRM4U_OUTPATH` environment variable** (highest priority) - NEW
2. **`OUTPATH` environment variable** (legacy support)
3. **`%TEMP%\VRM4U_BuildOut`** (safe default - always works)

### 2. Directory Validation

Before running UAT, the script now:
- Creates the output directory automatically (with parent directories)
- Validates write access by creating a test file
- Fails early with clear instructions if the directory is invalid or unwritable

### 3. Improved Error Messages

When the output directory cannot be created or is not writable, the script provides:
- Clear error messages explaining what went wrong
- Specific instructions on how to fix it
- Examples of setting `VRM4U_OUTPATH`

### 4. Noise Reduction

- `version.ps1` now gracefully handles missing `MyProjectBuildScript.uproject` file
- `set /a` errors for decimal version numbers (e.g., "5.7") are suppressed

## How to Use

### Default Behavior (No Configuration)

Just run the build scripts - they will automatically use `%TEMP%\VRM4U_BuildOut`:

```batch
cd Source\ReleaseScript
build_5.bat
```

### Custom Output Directory

Set the `VRM4U_OUTPATH` environment variable:

```batch
REM Temporary override for this session
set VRM4U_OUTPATH=C:\MyBuilds
cd Source\ReleaseScript
build_5.bat

REM Or use a repo-relative path
set VRM4U_OUTPATH=%CD%\_out
build_ver2.bat 5.7 Win64 Shipping VRM4U_5_7_test.zip
```

### Persistent Configuration

Set `VRM4U_OUTPATH` as a system/user environment variable:

1. Open **System Properties** → **Environment Variables**
2. Add new variable:
   - Name: `VRM4U_OUTPATH`
   - Value: `C:\MyBuildOutput`
3. Restart Command Prompt
4. Run build scripts normally

## Benefits

✅ **Works on all Windows machines** - No D: drive required
✅ **No script edits needed** - Configure via environment variable
✅ **Safe defaults** - Uses `%TEMP%` which always exists and is writable
✅ **Clear error messages** - Know exactly what to do if something goes wrong
✅ **CI/CD friendly** - Easy to configure in automated pipelines
✅ **Backward compatible** - Legacy `OUTPATH` variable still works

## Migration Guide

### If you were editing `build_ver2.bat` to change OUTPATH:

**Before:**
```batch
REM In build_ver2.bat line 17
set OUTPATH=d:/tmp/_out   REM Changed to my path
```

**After:**
```batch
REM No need to edit the script! Just set environment variable:
set VRM4U_OUTPATH=C:\MyPath
```

### If you had D:\tmp\_out working:

The scripts will now use `%TEMP%\VRM4U_BuildOut` by default. If you want to keep using `D:\tmp\_out`:

```batch
set VRM4U_OUTPATH=D:\tmp\_out
```

## Technical Details

### Directory Creation

The script uses `mkdir` which automatically creates parent directories on Windows.

### Path Normalization

- Input paths with forward slashes are converted to backslashes for Windows
- The final path passed to UAT uses forward slashes (UAT prefers Unix-style paths)

### Write Access Validation

A temporary file (`test_write_access.tmp`) is created and deleted to verify the directory is writable before invoking UAT. This prevents UAT from failing late in the build process.

### Scope

These changes only affect `build_ver2.bat` (used for UE5 builds). The older `build_ver.bat` script (used for UE4/early UE5) uses a different build approach and doesn't have the same OUTPATH issue.

## Testing Checklist

- [ ] Build succeeds on machine with only C: drive
- [ ] Build succeeds with default output path (no env vars)
- [ ] Build succeeds with `VRM4U_OUTPATH` set to custom location
- [ ] Build fails gracefully with clear message when output path is unwritable
- [ ] `VRM4U_OUTPATH` takes precedence over `OUTPATH`
- [ ] Legacy `OUTPATH` variable still works when `VRM4U_OUTPATH` is not set

## See Also

- [BUILDING.md](BUILDING.md) - Complete build documentation
- [Source/ReleaseScript/build_ver2.bat](Source/ReleaseScript/build_ver2.bat) - Updated build script
- [Source/ReleaseScript/version.ps1](Source/ReleaseScript/version.ps1) - Updated version script
