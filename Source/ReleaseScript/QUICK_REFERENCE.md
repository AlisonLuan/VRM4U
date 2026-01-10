# Quick Reference: VRM4U Build Scripts

This is a quick reference for configuring and using VRM4U build scripts.

## TL;DR

**Auto-detection works for most users!** Just run the build script if UE is installed via Epic Games Launcher:

```batch
cd Source\ReleaseScript
build_5.bat
```

**Have only some UE versions installed?** The script will automatically skip missing versions and continue!

## When Auto-Detection Fails

If you see "Unreal Engine not found", choose one of these methods:

### Method 1: Environment Variable (Best for CI)

```batch
set UE_ROOT=C:\YourPath\Epic Games
build_5.bat
```

### Method 2: Config File (Best for Local Development)

```batch
cd Source\ReleaseScript
copy ue_path.config.example ue_path.config
notepad ue_path.config
REM Edit to contain: C:\YourPath\Epic Games
build_5.bat
```

### Method 3: Legacy Variables (Backward Compatible)

```batch
set UE5BASE=C:\YourPath\Epic Games
build_5.bat
```

## Supported Environment Variables

Listed by priority (highest to lowest):

1. `UE_ROOT` - Recommended for new usage
2. `UE_ENGINE_DIR` - Alternative name
3. `UE5BASE` - Legacy, still supported
4. `UE4BASE` - Legacy, still supported

## Expected Directory Structure

The path you provide should be the BASE directory. The scripts will append the version:

```
<YOUR_BASE_PATH>\
  ├── UE_5.7\
  │   └── Engine\
  │       ├── Binaries\Win64\UnrealEditor.exe
  │       └── Build\BatchFiles\RunUAT.bat
  ├── UE_5.6\
  │   └── Engine\...
  └── UE_4.27\
      └── Engine\...
```

**Do NOT include** `UE_5.7` in the path you configure!

## Examples

### Example 1: Standard Epic Launcher Install
```
Your UE is at: C:\Program Files\Epic Games\UE_5.7\Engine\...
Configure as:  C:\Program Files\Epic Games
```

### Example 2: Custom Drive
```
Your UE is at: D:\UnrealEngine\UE_5.7\Engine\...
Configure as:  D:\UnrealEngine
```

### Example 3: Multiple Versions
```
Your UE versions:
  E:\Engines\UE_5.7\Engine\...
  E:\Engines\UE_5.6\Engine\...
  E:\Engines\UE_4.27\Engine\...

Configure as: E:\Engines
```

## Troubleshooting

**"Version directory not found"**
- Check that `<your_path>\UE_<version>` exists
- Verify version number matches (e.g., `5.7` not `5.7.0`)

**"Required UE files not found"**
- Ensure the version is fully installed
- Check for `Engine\Build\BatchFiles\RunUAT.bat`
- Check for `Engine\Binaries\Win64\UnrealEditor.exe`

**"Cannot open script"**
- Run from correct directory: `Source\ReleaseScript\`
- Use `call resolve_ue_path.bat 5.7` not just `resolve_ue_path.bat 5.7`

## Version Configuration

### Choose Which Versions to Build

**Method 1: Environment Variable (Quick Override)**

```batch
set BUILD_UE_VERSIONS=5.7,5.6
build_5.bat
```

**Method 2: versions.txt File (Persistent Config)**

```batch
cd Source\ReleaseScript
copy versions.txt.example versions.txt
notepad versions.txt
REM Uncomment the versions you have installed
build_5.bat
```

**Method 3: Use Default (Tries all: 5.7, 5.6, 5.5, 5.4, 5.3, 5.2)**

```batch
build_5.bat
REM Will skip versions you don't have installed
```

### Skip vs Strict Mode

**Default: Skip missing versions** (recommended for local development)
```batch
build_5.bat
REM Builds what you have, skips the rest
```

**Strict: Fail if any version is missing** (recommended for CI)
```batch
set STRICT_VERSIONS=1
build_5.bat
REM Fails immediately if any configured version is not installed
```

## More Information

- See [BUILD_VERSION_CONFIG.md](BUILD_VERSION_CONFIG.md) for detailed version configuration guide
- See [TEST_PLAN_VERSIONS.md](TEST_PLAN_VERSIONS.md) for testing version handling
- See [BUILDING.md](../../BUILDING.md) for complete documentation
- See [VERSION_SCRIPT_GUIDE.md](VERSION_SCRIPT_GUIDE.md) for details on version.ps1 usage
- See [GIT_BEHAVIOR_GUIDE.md](GIT_BEHAVIOR_GUIDE.md) for git safety and RELEASESCRIPT_GIT_RESET
- See [TEST_PLAN.md](TEST_PLAN.md) for testing the build scripts
