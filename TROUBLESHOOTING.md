# VRM4U Troubleshooting Guide

This document contains solutions to common issues encountered when using the VRM4U plugin.

## Table of Contents

- [VMC (Virtual Motion Capture) Issues](#vmc-virtual-motion-capture-issues)
- [Editor Freezes on Second PIE Run (UE5.6/5.7)](#editor-freezes-on-second-pie-run-ue5657)
- [Additional Resources](#additional-resources)

---

## VMC (Virtual Motion Capture) Issues

**Common VMC problems:**
- Character doesn't move (root position locked)
- No VMC data received (even in sample map)
- Works in other apps but not VRM4U

**→ See the comprehensive [VMC Setup & Troubleshooting Guide](VMC_TROUBLESHOOTING.md) for:**
- Step-by-step setup instructions
- Root bone retargeting configuration (most common issue)
- Network/firewall troubleshooting
- Debug logging and diagnostics
- FAQ and solutions

---

## Editor Freezes on Second PIE Run (UE5.6/5.7)

**Issue:** The Unreal Editor freezes when starting Play In Editor (PIE) for the second time after VRM4U is installed, particularly in Lyra Starter Game projects.

**Symptoms:**
- First PIE session starts and stops normally
- Second PIE session causes editor to become unresponsive (hard freeze)
- Issue occurs with PIE mode only; Standalone play works normally
- Commonly seen in Lyra project with `L_ShooterGym` map

**Root Cause:**
Multiple delegate lifecycle management issues caused delegates to be registered multiple times without proper cleanup between PIE sessions, leading to dangling references and deadlocks.

**Fix:**
This issue has been fixed in VRM4U builds released after January 2026 (see GitHub Issue #555 for details). The fix includes:
- Proper delegate handle management in VRM4UImporterModule
- Safe lambda captures and cleanup in VRM4U_RenderSubsystem
- Complete delegate cleanup in VRM4U_VMCSubsystem
- Reset of PIE state flags between sessions

**Affected Versions:**
- UE 5.6 and UE 5.7 with VRM4U plugin (versions before January 2026)

**Workaround (if using older plugin version):**
If you're using an older version of VRM4U and cannot update immediately:
1. Restart the editor between PIE sessions
2. Use Standalone play instead of PIE
3. Disable VRM4U plugin when not actively working with VRM assets

**How to Verify Fix:**
1. Open Lyra Starter Game project with VRM4U plugin installed
2. Load map: `Plugins/GameFeatures/ShooterCore/Content/Maps/L_ShooterGym.umap`
3. Start PIE (e.g., "New Editor Window (PIE)")
4. Stop PIE
5. Start PIE again
6. Verify editor does not freeze

**Related Issue:** GitHub Issue #555

## Additional Resources

For more information about VRM4U:
- [VMC Setup & Troubleshooting](VMC_TROUBLESHOOTING.md) - Complete guide for VMC protocol issues
- [Main README](README.md)
- [English README](README_en.md)
- [UE5.7 Retargeting Fix](UE57_RETARGETING_FIX.md)
- [Thumb Control Fix](THUMB_FIX_README.md)

## Reporting New Issues

If you encounter issues not covered here:
1. Check the [GitHub Issues](https://github.com/ruyo/VRM4U/issues) page
2. Search for similar problems
3. If no match found, create a new issue with:
   - Unreal Engine version
   - VRM4U plugin version/commit
   - Detailed reproduction steps
   - Log files (if available)
   - Screenshots or videos (if applicable)
