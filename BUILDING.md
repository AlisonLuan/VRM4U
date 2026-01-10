# Building VRM4U

This document describes how to build VRM4U plugin packages for distribution.

## Overview

VRM4U uses automated build scripts located in `Source/ReleaseScript/` to create release packages for multiple Unreal Engine versions. The scripts handle:

- Building the plugin for different UE versions (4.20 through 5.7+)
- Platform-specific builds (Windows, Linux, Android)
- Packaging built plugins into zip files for distribution

## Prerequisites

### Windows

- **Unreal Engine**: One or more versions of UE installed via Epic Games Launcher or from source
- **Visual Studio**: Version compatible with your target UE versions
- **Git**: For version control
- **Windows Subsystem for Linux (WSL)**: Required by build scripts for some math operations
- **PowerShell**: For build automation scripts

### macOS / Linux

- Custom assimp build is required (see main README.md)
- Appropriate UE installation for your platform

## Quick Start

### 1. Configure Output Directory (Optional)

The build scripts will automatically use a safe default output directory (`%TEMP%\VRM4U_BuildOut`), but you can override this if needed:

#### Option A: Environment Variable (Recommended)

Set `VRM4U_OUTPATH` before running build scripts:

```batch
REM Use a custom output directory
set VRM4U_OUTPATH=C:\MyBuildOutput

REM Or use a directory relative to the repository
set VRM4U_OUTPATH=%CD%\_out

REM Then run build
cd Source\ReleaseScript
build_5.bat
```

#### Option B: Use Default (No Configuration Needed)

If you don't set `VRM4U_OUTPATH`, the scripts will automatically use:
- `%TEMP%\VRM4U_BuildOut` (typically `C:\Users\<YourName>\AppData\Local\Temp\VRM4U_BuildOut`)

This default location:
- Exists on all Windows machines
- Is always writable
- Requires no manual configuration

### 2. Configure Unreal Engine Path

The build scripts need to locate your Unreal Engine installation(s). There are three ways to configure this:

#### Option A: Auto-detection (Easiest)

If you installed UE via Epic Games Launcher in a standard location, the scripts will auto-detect it:

```batch
cd Source\ReleaseScript
build_5.bat
```

The auto-detection scans these common locations:
- `C:\Program Files\Epic Games`
- `D:\Program Files\Epic Games`
- `E:\Program Files\Epic Games`
- `C:\Epic Games`
- `D:\Epic Games`

#### Option B: Environment Variable (Recommended for CI)

Set an environment variable before running build scripts:

```batch
REM Option 1: Use UE_ROOT (highest priority)
set UE_ROOT=C:\MyCustomPath\Epic Games

REM Option 2: Use UE5BASE or UE4BASE (legacy, still supported)
set UE5BASE=D:\UnrealEngine
set UE4BASE=D:\UnrealEngine

REM Then run build
cd Source\ReleaseScript
build_5.bat
```

#### Option C: Local Config File (Recommended for Development)

Create a local configuration file that won't be committed to Git:

```batch
cd Source\ReleaseScript

REM Copy the example config
copy ue_path.config.example ue_path.config

REM Edit ue_path.config with your path (use any text editor)
notepad ue_path.config
```

Edit `ue_path.config` to contain your UE base path (one line):
```
C:\Program Files\Epic Games
```

**Note**: Do NOT include the version folder (like `UE_5.7`) in the path. The scripts will append the appropriate version automatically.

### 3. Run Build Scripts

#### Build All UE5 Versions

```batch
cd Source\ReleaseScript
build_5.bat
```

This builds packages for UE 5.7, 5.6, 5.5, 5.4, 5.3, and 5.2.

#### Build All Versions (UE4 + UE5)

```batch
cd Source\ReleaseScript
build_all.bat
```

This runs `build_5.bat` followed by `build_old.bat` (which builds UE 4.20-5.1).

#### Build Specific Version

```batch
cd Source\ReleaseScript

REM Build for UE 5.7 (Windows, Shipping)
build_ver2.bat 5.7 Win64 Shipping VRM4U_5_7_20250110.zip

REM Build for UE 5.6 (Android, Development)
build_ver2.bat 5.6 Android Development VRM4U_5_6_android.zip

REM Build for UE 4.27 (Windows, Development, with project)
build_ver.bat 4.27 Win64 Development MyProjectBuildScriptEditor VRM4U_4_27.zip
```

## Build Script Reference

### resolve_ue_path.bat

Central script for locating Unreal Engine installations.

**Usage:**
```batch
call resolve_ue_path.bat <version> [output_var_name]
```

**Arguments:**
- `<version>`: UE version (e.g., `5.7`, `5.6`, `4.27`)
- `[output_var_name]`: Optional variable name to store result (default: `RESOLVED_UE_BASE`)

**Resolution Order:**
1. Environment variable `UE_ROOT`
2. Environment variable `UE_ENGINE_DIR`
3. Environment variable `UE5BASE` or `UE4BASE` (legacy)
4. Local config file `ue_path.config`
5. Auto-detection (Epic Games Launcher metadata + common paths)

**Example:**
```batch
call resolve_ue_path.bat 5.7 MY_UE_PATH
echo Resolved path: %MY_UE_PATH%
```

### build_ver2.bat

Builds UE5 plugin using Epic's BuildPlugin automation tool (RunUAT).

**Usage:**
```batch
build_ver2.bat <UE_VERSION> <PLATFORM> <CONFIG> <ZIP_NAME>
```

**Arguments:**
- `<UE_VERSION>`: UE version without 'UE_' prefix (e.g., `5.7`)
- `<PLATFORM>`: Target platform (`Win64`, `Linux`, `Android`)
- `<CONFIG>`: Build configuration (`Shipping`, `Development`, `Debug`)
- `<ZIP_NAME>`: Output zip file name (e.g., `VRM4U_5_7_20250110.zip`)

**Output Directory Configuration:**

The script uses the following precedence for determining output directory:
1. `VRM4U_OUTPATH` environment variable (highest priority)
2. `OUTPATH` environment variable (legacy support)
3. `%TEMP%\VRM4U_BuildOut` (safe default - always works)

**Example:**
```batch
build_ver2.bat 5.7 Win64 Shipping VRM4U_5_7_test.zip

REM With custom output directory
set VRM4U_OUTPATH=C:\BuildOutput
build_ver2.bat 5.7 Win64 Shipping VRM4U_5_7_test.zip
```

### build_ver.bat

Builds UE4/early-UE5 plugin using a full project build approach.

**Usage:**
```batch
build_ver.bat <UE_VERSION> <PLATFORM> <CONFIG> <PROJECT_TARGET> <ZIP_NAME>
```

**Arguments:**
- `<UE_VERSION>`: UE version (e.g., `4.27`, `5.1`)
- `<PLATFORM>`: Target platform (`Win64`, `Android`)
- `<CONFIG>`: Build configuration (`Development`, `Debug`, `Shipping`)
- `<PROJECT_TARGET>`: UE project target (e.g., `MyProjectBuildScriptEditor`)
- `<ZIP_NAME>`: Output zip file name

**Example:**
```batch
build_ver.bat 4.27 Win64 Development MyProjectBuildScriptEditor VRM4U_4_27.zip
```

### build_5.bat

Convenience script that builds packages for all supported UE5 versions.

**Usage:**
```batch
build_5.bat
```

### build_all.bat

Convenience script that builds packages for all supported UE versions (both UE4 and UE5).

**Usage:**
```batch
build_all.bat
```

## Output

### Build Artifacts Location

Built plugin packages (zip files) are created in `../../../../_zip/` relative to the ReleaseScript directory (typically at repository root).

### Intermediate Build Output

During the build process, UAT creates intermediate files in the configured output directory:
- **Default:** `%TEMP%\VRM4U_BuildOut` 
- **Custom:** Set via `VRM4U_OUTPATH` environment variable

This intermediate output is used by the packaging process and can be safely deleted after builds complete.

### Package Contents

Each package contains:
- Plugin binaries for the target platform
- Plugin descriptor (VRM4U.uplugin)
- Content assets
- Source code (if applicable)

## Troubleshooting

### "Could not find a part of the path" Error

**Problem:** Build fails with `DirectoryNotFoundException` for the output path.

**Solution:** 
- **Recommended:** Don't set `VRM4U_OUTPATH` - the default `%TEMP%\VRM4U_BuildOut` always works
- **Custom path:** If you need a specific location, ensure:
  1. The path exists or can be created
  2. You have write permissions
  3. The path uses backslashes on Windows (e.g., `C:\Output` not `C:/Output`)

**Example of setting a custom output path:**
```batch
REM Using a directory on C: drive
set VRM4U_OUTPATH=C:\VRM4U_Builds

REM Using a directory relative to repository root
cd Source\ReleaseScript
set VRM4U_OUTPATH=%CD%\..\..\BuildOutput

REM Run the build
build_5.bat
```

### "Unreal Engine not found" Error

**Problem:** Build script cannot locate your UE installation.

**Solution:** Follow one of the configuration methods above. The error message will show:
- What paths were checked
- How to set environment variables
- How to create a config file

### "Path validation failed" Error

**Problem:** UE installation was found but required files are missing.

**Solution:** 
- Ensure the version is fully installed via Epic Games Launcher
- Check that these files exist:
  - `<base>\UE_<version>\Engine\Build\BatchFiles\RunUAT.bat`
  - `<base>\UE_<version>\Engine\Binaries\Win64\UnrealEditor.exe`

### Build Fails with "errorlevel not 0"

**Problem:** UE build tools returned an error.

**Solution:**
- Check the build output for specific errors
- Ensure Visual Studio and UE toolchain are properly installed
- For UE4 builds, verify the project file path in `build_ver.bat`
- Try building the plugin manually in the UE Editor to see detailed errors

### WSL Errors

**Problem:** Scripts fail at WSL commands (used for version math).

**Solution:**
- Install Windows Subsystem for Linux: `wsl --install`
- Ensure WSL is accessible from Command Prompt: `wsl echo test`

### Multiple UE Versions Conflict

**Problem:** Auto-detection picks the wrong version.

**Solution:** Use environment variables to force a specific base path:
```batch
set UE_ROOT=C:\Path\With\Specific\Version
```

Or maintain separate config files and copy the right one before building:
```batch
copy ue_path.config.ue57 ue_path.config
build_5.bat
```

## CI/CD Integration

For continuous integration pipelines:

1. **Install UE**: Ensure UE is installed in a known location
2. **Set Environment Variables**: 
   - `UE_ROOT` for Unreal Engine path
   - `VRM4U_OUTPATH` for build output (optional - uses safe default if not set)
3. **Run Build**: Execute build scripts non-interactively

**GitHub Actions Example:**
```yaml
- name: Setup Environment
  run: |
    echo "UE_ROOT=C:\Program Files\Epic Games" >> $ENV:GITHUB_ENV
    echo "VRM4U_OUTPATH=${{ github.workspace }}\_buildout" >> $ENV:GITHUB_ENV

- name: Build Plugin
  run: |
    cd Source\ReleaseScript
    build_ver2.bat 5.7 Win64 Shipping VRM4U_5_7_%GITHUB_RUN_NUMBER%.zip
```

**GitLab CI Example:**
```yaml
build:
  script:
    - $env:UE_ROOT = "C:\UnrealEngine"
    - $env:VRM4U_OUTPATH = "$CI_PROJECT_DIR\_buildout"
    - cd Source\ReleaseScript
    - .\build_5.bat
```

**Notes for CI:**
- If `VRM4U_OUTPATH` is not set, builds use `%TEMP%\VRM4U_BuildOut` (safe default)
- Set `VRM4U_OUTPATH` to a workspace-relative path for better artifact collection
- Ensure the output directory has sufficient disk space for plugin builds

## Advanced Configuration

### Custom Output Directory

The default output directory is `%TEMP%\VRM4U_BuildOut`, which is safe and writable on all systems. You can customize it in two ways:

#### Per-Session Override (Temporary)

Set the environment variable before running builds:

```batch
set VRM4U_OUTPATH=D:\CustomOutput
build_ver2.bat 5.7 Win64 Shipping VRM4U_5_7_test.zip
```

#### Persistent Override

Set a system or user environment variable:

1. Open System Properties → Environment Variables
2. Add new variable:
   - **Name:** `VRM4U_OUTPATH`
   - **Value:** `C:\MyBuildOutput` (or your preferred path)
3. Restart Command Prompt and run builds

**Note:** The legacy `OUTPATH` environment variable is also supported for backward compatibility, but `VRM4U_OUTPATH` takes precedence if both are set.

### Custom Output Directory (Legacy Method - Not Recommended)

**Note:** The legacy `OUTPATH` environment variable is also supported for backward compatibility, but `VRM4U_OUTPATH` takes precedence if both are set.

### Custom Output Directory (Legacy Method - Not Recommended)

**Deprecated:** Editing the script directly is no longer necessary. Use `VRM4U_OUTPATH` environment variable instead.

~~Edit the build scripts to change `OUTPATH`:~~

```batch
REM In build_ver2.bat (DEPRECATED - use VRM4U_OUTPATH instead)
set OUTPATH=d:/tmp/_out  REM Change this to your preferred location
```

### Building from UE Source Build

If you built UE from source (not via Launcher), the auto-detection may not work. Use explicit configuration:

```batch
REM Set to the root where you cloned/built UE
set UE_ROOT=C:\Source\UnrealEngine

REM Ensure the folder structure matches:
REM C:\Source\UnrealEngine\UE_5.7\Engine\...
```

### Version-Specific Overrides

For testing or debugging specific versions, use per-invocation overrides:

```batch
REM Use a specific path just for this build
set UE_ROOT=D:\TestEngines && build_ver2.bat 5.7 Win64 Development test.zip
```

## Additional Resources

- Main README: [README.md](../README.md)
- Plugin Documentation: https://ruyo.github.io/VRM4U/
- UE Plugin Documentation: https://docs.unrealengine.com/en-US/ProductionPipelines/Plugins/
