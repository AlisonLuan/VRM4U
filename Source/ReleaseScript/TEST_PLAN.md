# Test Plan for resolve_ue_path.bat

## Overview
This document describes manual validation tests for the UE path resolution system.

## Test Scenarios

### Test 1: Environment Variable Override (UE_ROOT)
**Setup:**
```batch
set UE_ROOT=C:\CustomPath\Epic Games
call resolve_ue_path.bat 5.7
```

**Expected Result:**
- Should use `C:\CustomPath\Epic Games` as base path
- Should validate `C:\CustomPath\Epic Games\UE_5.7\Engine\...`
- Should print: "Found UE_ROOT environment variable: C:\CustomPath\Epic Games"
- Exit code 0 if path exists, 1 if validation fails

### Test 2: Environment Variable Override (UE5BASE, legacy)
**Setup:**
```batch
set UE5BASE=D:\UnrealEngine
call resolve_ue_path.bat 5.6
```

**Expected Result:**
- Should use `D:\UnrealEngine` as base path
- Should print: "Found UE5BASE environment variable: D:\UnrealEngine"
- Should validate against `D:\UnrealEngine\UE_5.6\Engine\...`

### Test 3: Local Config File
**Setup:**
Create `ue_path.config` with content:
```
D:\Program Files\Epic Games
```

Then run:
```batch
call resolve_ue_path.bat 5.7
```

**Expected Result:**
- Should read from config file
- Should print: "Found local config file" and "Using path from config"
- Should use the path from the config file

### Test 4: Config File with Comments
**Setup:**
Create `ue_path.config` with content:
```
# This is my UE installation
# Multiple comment lines
D:\Epic Games
```

Then run:
```batch
call resolve_ue_path.bat 5.6
```

**Expected Result:**
- Should skip comment lines (starting with #)
- Should use `D:\Epic Games`

### Test 5: Auto-detection (Epic Games Launcher)
**Setup:**
```batch
REM No environment variables set
REM No config file
REM UE installed via Epic Games Launcher at standard location
call resolve_ue_path.bat 5.7
```

**Expected Result:**
- Should attempt to read `%ProgramData%\Epic\UnrealEngineLauncher\LauncherInstalled.dat`
- Should scan common paths (C:\Program Files\Epic Games, D:\Program Files\Epic Games, etc.)
- Should find and validate the installation
- Should print: "Attempting auto-detection..."

### Test 6: Multiple Detection Methods
**Setup:**
```batch
REM UE installed at D:\Program Files\Epic Games\UE_5.7
call resolve_ue_path.bat 5.7
```

**Expected Result:**
- Should find via auto-detection
- Should validate that required files exist:
  - RunUAT.bat
  - UnrealEditor.exe or UnrealEditor-Cmd.exe

### Test 7: Version Not Found
**Setup:**
```batch
set UE_ROOT=C:\Program Files\Epic Games
call resolve_ue_path.bat 99.99
```

**Expected Result:**
- Should print error: "Version directory not found: C:\Program Files\Epic Games\UE_99.99"
- Should show help with 3 options to fix
- Exit code 1

### Test 8: Path Validation Failure
**Setup:**
```batch
set UE_ROOT=C:\InvalidPath
call resolve_ue_path.bat 5.7
```

**Expected Result:**
- Should fail validation (files not found)
- Should print: "Path validation failed - required UE files not found"
- Should show detailed help message
- Exit code 1

### Test 9: Integration with build_ver2.bat
**Setup:**
```batch
set UE_ROOT=D:\MyEngines
call build_ver2.bat 5.7 Win64 Shipping test.zip
```

**Expected Result:**
- build_ver2.bat should call resolve_ue_path.bat
- Should set UE5BASE to the resolved path
- Should construct correct BUILD path: "D:\MyEngines\UE_5.7\Engine\Build\BatchFiles\RunUAT.bat"
- If resolution fails, build_ver2.bat should exit with error

### Test 10: Integration with build_ver.bat
**Setup:**
```batch
set UE_ROOT=C:\EngineBuilds
call build_ver.bat 4.27 Win64 Development MyProjectBuildScriptEditor test.zip
```

**Expected Result:**
- build_ver.bat should call resolve_ue_path.bat
- Should set UE4BASE to the resolved path
- Should construct correct paths for CLEAN, BUILD, REBUILD
- If resolution fails, build_ver.bat should exit with error

### Test 11: Custom Output Variable
**Setup:**
```batch
set UE_ROOT=C:\Custom
call resolve_ue_path.bat 5.7 MY_CUSTOM_VAR
echo %MY_CUSTOM_VAR%
```

**Expected Result:**
- Should set MY_CUSTOM_VAR instead of RESOLVED_UE_BASE
- Should print the custom variable value

### Test 12: Precedence Order
**Setup:**
```batch
set UE_ROOT=C:\FromEnv
REM Also have config file with D:\FromConfig
call resolve_ue_path.bat 5.7
```

**Expected Result:**
- Should use C:\FromEnv (environment variable takes precedence)
- Should NOT read config file
- Should print: "Found UE_ROOT environment variable"

## Validation Checklist

- [ ] Script handles missing version argument gracefully
- [ ] Script validates all required files exist
- [ ] Script provides clear error messages with actionable steps
- [ ] Script supports all precedence levels (env > config > auto-detect)
- [ ] Script properly returns base path (not version-specific path)
- [ ] Script works with both UE4 and UE5 versions
- [ ] Config file parsing skips comments and empty lines
- [ ] Auto-detection checks multiple common locations
- [ ] Error messages list what was tried and how to fix
- [ ] Integration with build_ver2.bat works correctly
- [ ] Integration with build_ver.bat works correctly
- [ ] Backward compatibility with UE5BASE/UE4BASE maintained

## Success Criteria

All tests should:
1. Execute without syntax errors
2. Produce expected output messages
3. Return correct exit codes (0 for success, 1 for failure)
4. Set the correct output variable
5. Work when integrated with build scripts

## Notes

- These tests should be run on a Windows machine with batch script support
- Some tests require actual UE installations to fully validate
- The Linux/CI environment cannot execute batch scripts, so validation is manual
- Consider adding PowerShell equivalents for cross-platform CI in the future
