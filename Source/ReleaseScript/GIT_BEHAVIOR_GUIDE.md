# Build Script Git Behavior - Safety Guide

## Overview

The VRM4U release scripts (`build_ver.bat` and `build_ver2.bat`) include an **opt-in** git reset feature to help with automated release builds. This document explains the behavior and how to use it safely.

## Default Behavior (Safe for Local Development)

By default, **the build scripts DO NOT modify your git state**. They will:
- ✅ Build the plugin for the specified UE version
- ✅ Package the build output
- ✅ Create release ZIP files
- ❌ **NOT** run `git reset`
- ❌ **NOT** run `git checkout`
- ❌ **NOT** run `git pull`

This ensures that:
- Your working directory changes are preserved
- Your current branch is not changed
- You can build locally without losing uncommitted work

## Opt-In Git Reset

For automated CI/CD builds or release pipelines, you can enable git cleanup:

### Enabling Git Reset

Set the environment variable **before** running the build script:

#### Windows CMD
```cmd
set RELEASESCRIPT_GIT_RESET=1
call build_ver2.bat 5.7 Win64 Shipping output.zip
```

#### Windows PowerShell
```powershell
$env:RELEASESCRIPT_GIT_RESET = "1"
.\build_ver2.bat 5.7 Win64 Shipping output.zip
```

#### Bash (WSL/Linux/macOS)
```bash
export RELEASESCRIPT_GIT_RESET=1
./build_ver2.bat 5.7 Win64 Shipping output.zip
```

### What It Does

When `RELEASESCRIPT_GIT_RESET=1` is set:

1. **Displays a warning**:
   ```
   [build_ver2] RELEASESCRIPT_GIT_RESET=1 detected - performing git reset --hard HEAD
   [build_ver2] WARNING: This will discard all uncommitted changes in your working directory!
   [build_ver2] Resetting to current HEAD...
   ```

2. **Runs `git reset --hard HEAD`**:
   - Discards all uncommitted changes
   - Resets tracked files to their last committed state
   - **DOES NOT** change branches
   - **DOES NOT** pull from remote

3. **Continues on error**:
   - If git reset fails, the script logs a warning and continues
   - The build process is not interrupted

## Safety Features

### No Automatic Branch Switching
The scripts **DO NOT**:
- Switch to a specific branch (e.g., `master` or `main`)
- Run `git checkout <branch>`
- Move `HEAD` to a different commit than your current position

The reset is **always** to the current `HEAD`, which is:
- Your current branch tip (if on a branch)
- Your current detached HEAD position (if not on a branch)

### No Automatic Pull
The scripts **DO NOT**:
- Run `git pull`
- Fetch from remote
- Update your local branch with remote changes

### Working with Uncommitted Changes
If you have uncommitted changes and run with `RELEASESCRIPT_GIT_RESET=1`:
- **All uncommitted changes will be lost**
- **Untracked files are preserved** (not deleted)
- **Staged changes are reset** (removed from index)

## Use Cases

### ✅ Good Use Cases for Git Reset

1. **Automated CI/CD Builds**
   ```yaml
   # GitHub Actions example
   - name: Build VRM4U Release
     env:
       RELEASESCRIPT_GIT_RESET: 1
     run: |
       cd Source/ReleaseScript
       ./build_ver2.bat 5.7 Win64 Shipping VRM4U_5_7_${{ github.run_number }}.zip
   ```

2. **Nightly Builds**
   - Ensures a clean state for each nightly build
   - Previous build artifacts don't interfere with the next build

3. **Release Pipelines**
   - Start each release build from a known clean state
   - Avoid contamination from previous build attempts

### ❌ Bad Use Cases (Don't Enable)

1. **Local Development Builds**
   - You want to test changes before committing
   - You need to iterate on code
   - **Solution**: Don't set `RELEASESCRIPT_GIT_RESET` (default behavior)

2. **Building from Uncommitted Experiments**
   - Testing a quick fix or prototype
   - **Solution**: Commit your changes first, or don't enable git reset

3. **Building from Multiple Branches**
   - Switching between feature branches
   - **Solution**: Switch branches manually with `git checkout`, then build without reset

## Troubleshooting

### "git reset failed - continuing anyway"
This warning appears when:
- You're not in a git repository
- Git is not installed or not in PATH
- The `.git` directory is corrupted

**Action**: The build continues normally. If you need git reset to work, investigate the git error.

### "I lost my changes!"
If you accidentally ran with `RELEASESCRIPT_GIT_RESET=1` and lost uncommitted work:

1. **Check git reflog** (may recover some work):
   ```bash
   git reflog
   git reset --hard HEAD@{1}
   ```

2. **Check editor auto-saves** (some IDEs keep backups)

3. **Learn for next time**: Always commit or stash before running builds with reset enabled

### "The build modified files I didn't expect"
The build scripts (`version.ps1`, `build_ver2.bat`) may modify:
- `VRM4U.uplugin` (based on target UE version)
- `.uproject` files (if using `build_ver.bat`)

These modifications are **intentional** and part of the versioning process. They happen **regardless** of the `RELEASESCRIPT_GIT_RESET` setting.

If you want to preserve the original files:
- Commit your work before building
- Or stash changes: `git stash`
- Or use a clean working tree for builds

## Migration from Older Versions

### Before (Pre-Fix)
Older versions of the build scripts may have:
- Run `git reset` unconditionally
- Switched branches without warning
- Changed your `HEAD` unexpectedly

### After (Current)
The current implementation:
- Requires explicit opt-in via `RELEASESCRIPT_GIT_RESET=1`
- Logs warnings when git operations are performed
- Never changes branches (only resets to current HEAD)
- Safe for local development by default

## Best Practices

1. **For Local Development**:
   - Do NOT set `RELEASESCRIPT_GIT_RESET`
   - Commit your changes regularly
   - Use `git status` before and after builds

2. **For CI/CD Pipelines**:
   - Set `RELEASESCRIPT_GIT_RESET=1` in the environment
   - Clone a fresh repository for each build (preferred)
   - Or reset to ensure clean state between builds

3. **For Release Builds**:
   - Tag your release commit first
   - Check out the tag for building
   - Set `RELEASESCRIPT_GIT_RESET=1` to ensure clean state

4. **For Collaboration**:
   - Document in your build instructions whether git reset should be enabled
   - Use separate machines/VMs for automated builds
   - Keep development and release build environments separate

## Summary

| Scenario | RELEASESCRIPT_GIT_RESET | Expected Behavior |
|----------|-------------------------|-------------------|
| Local dev, testing changes | Not set (default) | No git operations, changes preserved |
| Local dev, clean build | Not set (default) | No git operations, manual cleanup needed |
| CI/CD automated builds | Set to `1` | Git reset to HEAD, clean state |
| Release pipeline | Set to `1` | Git reset to HEAD, clean state |
| Building from tag | Not set or `1` | Either is safe (tag is immutable) |
| Building from dirty working tree | Not set (default) | Changes preserved (may affect build) |

**Remember**: The safest approach is to **always commit or stash your work** before running any build script, regardless of the git reset setting.
