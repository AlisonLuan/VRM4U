# version.ps1 - Usage Guide

## Overview

`version.ps1` is a PowerShell script that updates UE engine associations and modifies `VRM4U.uplugin` based on the target Unreal Engine version. This script is called by the build scripts (`build_ver2.bat` and `build_ver.bat`) during the release packaging process.

## Usage

```powershell
.\version.ps1 <EngineVersion> [TargetFilePath]
```

### Parameters

- **EngineVersion** (Required): The Unreal Engine version string (e.g., `"5.7"`, `"4.27"`)
- **TargetFilePath** (Optional): Full path to a `.uproject` or `.uplugin` file to update with `EngineAssociation`

### Modes

#### Plugin-Only Mode
When `TargetFilePath` is not provided, the script operates in plugin-only mode:
- Modifies `VRM4U.uplugin` only
- Does NOT update any `.uproject` file
- Used by `build_ver2.bat` (UAT BuildPlugin workflow)

```powershell
.\version.ps1 "5.7"
```

#### Project Mode
When `TargetFilePath` is provided, the script:
- Updates `EngineAssociation` in the specified `.uproject` file
- Also modifies `VRM4U.uplugin` based on engine version
- Used by `build_ver.bat` (full project build workflow)

```powershell
.\version.ps1 "5.7" "C:\MyProject\MyProject.uproject"
```

## Version-Specific Modifications

The script automatically modifies `VRM4U.uplugin` based on the target engine version:

### UE 4.20-4.23
- Changes `Modules[5].Type` to `'Developer'` (instead of `'UncookedOnly'`)

### UE 4.20-4.27
- Removes plugin dependencies at array indices 3, 2, 1 (IKRig, OSC plugins not available)

### UE 4.20-4.27, 5.0-5.1
- Removes module entries at array indices 4, 3, 2 (VRM4URender, VRM4UCaptureEditor, VRM4UCapture not supported)

## Error Handling

The script includes robust error handling:

### File Not Found
```
[version.ps1] ERROR: File not found: C:\path\to\file.uproject
[version.ps1] ERROR: Failed to read target file, cannot update EngineAssociation
```
**Exit Code**: 1

### Malformed JSON
```
[version.ps1] ERROR: Failed to read/parse JSON file: C:\path\to\file.uproject
[version.ps1] Error details: Conversion from JSON failed with error: ...
[version.ps1] File excerpt (first 200 chars):
{ "FileVersion": 3, ...
```
**Exit Code**: 1

### Module/Plugin Count Mismatch
```
[version.ps1] WARNING: Expected at least 6 modules but found 5
```
**Exit Code**: 0 (continues execution with warning)

## Features

### UTF-8 Encoding with BOM Handling
- Reads files with `Get-Content -Raw -Encoding UTF8`
- Handles files with or without UTF-8 BOM
- Writes output files without BOM for compatibility

### JSON Depth Preservation
- Uses `ConvertTo-Json -Depth 10` to prevent nested object truncation
- Preserves all plugin and module metadata

### Absolute Path Resolution
- Uses `$MyInvocation.MyCommand.Path` to determine script location
- Resolves `VRM4U.uplugin` path relative to script directory
- No longer relies on fragile relative paths like `../../../VRM4U/VRM4U.uplugin`

## Integration with Build Scripts

### build_ver2.bat (Plugin-Only Builds)
```batch
echo [build_ver2] Running version.ps1 to update plugin for UE %UE5VER%...
powershell -ExecutionPolicy RemoteSigned .\version.ps1 "%UE5VER%"
if not %errorlevel% == 0 (
    echo [ERROR] version.ps1 failed
    goto err
)
```

### build_ver.bat (Project Builds)
```batch
set PROJECTNAME="../../../../MyProjectBuildScript.uproject"
echo [build_ver] Running version.ps1 to update project file for UE %UE4VER%...
powershell -ExecutionPolicy RemoteSigned .\version.ps1 "%UE4VER%" %PROJECTNAME%
if not %errorlevel% == 0 (
    echo [ERROR] version.ps1 failed
    goto err
)
```

## Testing

### Basic Plugin-Only Test
```powershell
# Should succeed for modern UE versions
.\version.ps1 "5.7"

# Should modify plugin for older versions
.\version.ps1 "5.0"
.\version.ps1 "4.27"
```

### Project Mode Test
```powershell
# Create a test .uproject
echo '{"FileVersion": 3, "EngineAssociation": "5.0"}' > test.uproject

# Update it to UE 5.7
.\version.ps1 "5.7" "test.uproject"

# Verify EngineAssociation is now "5.7"
cat test.uproject
```

### Error Handling Test
```powershell
# Test with non-existent file (should exit with error code 1)
.\version.ps1 "5.7" "C:\nonexistent.uproject"

# Test with malformed JSON (should exit with error code 1)
echo 'INVALID JSON' > malformed.uproject
.\version.ps1 "5.7" "malformed.uproject"
```

## Troubleshooting

### "Failed to parse project file as JSON"
- Check that the target file contains valid JSON
- Ensure the file is readable and not locked by another process
- Verify file encoding is UTF-8 or ASCII

### "Expected at least X modules/plugins but found Y"
- This warning indicates the `.uplugin` file structure has changed
- The script will skip the problematic modification but continue
- Review `VRM4U.uplugin` to ensure it matches the expected structure

### Script exits with no error but no changes
- Check script output for warnings
- Ensure you're running from the correct directory (`Source/ReleaseScript/`)
- Verify PowerShell execution policy allows script execution:
  ```powershell
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
  ```

## Maintenance Notes

When adding support for new engine versions:
1. Update the conditional logic in Step 2 of `version.ps1`
2. Add version-specific module/plugin removal rules if needed
3. Test with a clean copy of `VRM4U.uplugin`
4. Update this documentation with new version-specific behaviors
