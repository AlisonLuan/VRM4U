# VRM4U Troubleshooting Guide

This document contains solutions to common issues encountered when using the VRM4U plugin.

## Table of Contents

- [SpringBone Physics Issues](#springbone-physics-issues)
- [VMC (Virtual Motion Capture) Issues](#vmc-virtual-motion-capture-issues)
- [Runtime Load Mesh Deformation](#runtime-load-mesh-deformation)
- [Editor Freezes on Second PIE Run (UE5.6/5.7)](#editor-freezes-on-second-pie-run-ue5657)
- [Additional Resources](#additional-resources)

---

## SpringBone Physics Issues

**Common SpringBone problems:**
- Hair/clothing physics not working after import
- SpringBone works in standard import but not in certain projects (e.g., GASP-based projects)
- Physics appears disabled or bones don't move

### Diagnostic Steps

1. **Check the Output Log** for SpringBone initialization messages:
   - Look for messages starting with `[VRM4U SpringBone]`
   - Check if SpringBone data was found: `"Found X spring groups in metadata"`
   - Verify bones were initialized: `"X/Y bones found"` or `"X/Y joints initialized successfully"`
   - Look for warnings about missing bones or failed initialization

2. **Verify VRM Export Contains SpringBone Data:**
   - **VRM 0.x models:** Check for `"Parsing VRM0 SpringBone: X spring groups, Y collider groups found"`
   - **VRM 1.0 models:** Check for `"Parsing VRM1 SpringBone: X spring groups found"`
   - If you see `"springNum=0"` or `"VRMC_springBone extension not found"`, your VRM file may not contain physics data

3. **Check AnimNode Configuration:**
   - In your Animation Blueprint, locate the **VrmSpringBone** node
   - Verify `VrmMetaObject` is set OR `EnableAutoSearchMetaData` is checked
   - If you see warnings like `"VrmMetaObject is null"`, the node cannot find the VRM metadata

### VRoid Studio Export Compatibility

**Issue:** SpringBone physics may not work with older VRoid Studio exports (e.g., 2.3.x)

**Solution:**
- **Use VRoid Studio 2.4.1 or newer** to export your VRM file
- Older versions may export SpringBone data in formats that are incomplete or malformed
- Re-export your character from the latest VRoid Studio and re-import into Unreal Engine

**Why this happens:**
VRoid Studio changed its SpringBone export format between versions. Older exports may:
- Use incorrect field names or structure
- Missing collider or spring group references
- Have incomplete secondary animation data

### GASP Project Specific Issues

If SpringBone works in a blank project but not in a GASP (Game Animation Sample Project) based project:

1. **Check Post Process AnimBP Settings:**
   - GASP may use a Post Process Animation Blueprint that overrides bone transforms
   - Locate the Post Process AnimBP in your character's Skeletal Mesh settings
   - Ensure SpringBone evaluation order is correct (should run before Post Process or disable Post Process temporarily)

2. **Verify Physics Evaluation:**
   - Check if `bIgnorePhysicsCollision` or `bIgnoreVRMCollision` flags are accidentally set
   - Ensure `loopc` (loop count) is at least 1 (default is usually 1-4)

3. **Animation Blueprint Compatibility:**
   - Some template AnimBPs may not include or properly configure VRM nodes
   - Try using the VRM4U sample AnimBP as a reference

### Runtime Warnings to Check

The plugin now logs detailed warnings:
- `"VrmMetaObject is null"` → AnimNode configuration issue
- `"Bone 'X' not found in skeleton"` → Model/skeleton mismatch
- `"no SpringBone data found"` → VRM file has no physics data
- `"VRMC_springBone extension not found"` → VRM 1.0 file without physics extension

### Still Not Working?

1. **Test with a known-good VRM:**
   - Download a recent VRM from VRoid Hub or use a sample VRM from VRoid Studio 2.4.1+
   - Import it into a blank UE project
   - If it works there but not in your project, it's a project configuration issue

2. **Enable Verbose Logging:**
   - In `DefaultEngine.ini`, add:
     ```ini
     [Core.Log]
     LogVRM4U=Verbose
     LogVRM4ULoader=Verbose
     ```
   - Restart the editor and check the log for detailed SpringBone messages

3. **Check VRM File in External Viewer:**
   - Use UniVRM (Unity) or another VRM viewer to confirm physics works
   - If physics doesn't work there either, the VRM file itself may be broken

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

---

## Runtime Load Mesh Deformation

**Issue:** When using `VRM4U_runtimeload.umap` to load VRM files at runtime, some models may show mesh deformation (stretching, distortion) on animated instances while static instances look correct.

**Common symptoms:**
- Neck, limbs, or other body parts stretch unnaturally
- Issue only appears on moving/animated runtime-loaded models
- Static (non-animated) instance of the same model looks correct
- Problem doesn't occur with standard import (non-runtime load)

### Known Affected Models

- NicoNico "Rittai-chan" (td32797) - neck stretching reported
- Some older VRM 0.x models with non-uniform bone scales

### Diagnostic Steps

1. **Test with Standard Import:**
   - Import the same VRM file using the normal drag-and-drop method
   - Apply the same animation
   - If deformation doesn't occur, it's a runtime-load-specific issue

2. **Check for Non-Uniform Bone Scales:**
   - Some VRM models use non-uniform scale on bones for artistic effect
   - Runtime load path may handle bone scale differently than standard import

3. **Inspect Reference Pose:**
   - Runtime-loaded meshes may have incorrect reference pose initialization
   - This can cause skinning math to be applied incorrectly

### Current Status

This is a **known issue** being investigated (GitHub Issue #536). The deformation is specific to the runtime load pipeline and does not affect:
- Standard VRM import (drag-and-drop)
- Models that use uniform bone scales
- Static (non-animated) instances

### Workarounds

Until a fix is available:

1. **Use Standard Import Instead:**
   - If possible, import VRM files at editor time rather than runtime
   - Standard import path has correct mesh initialization

2. **Test Your Model:**
   - Load your specific VRM in `VRM4U_runtimeload.umap` before shipping
   - If deformation occurs, consider pre-importing the model

3. **Report Model-Specific Issues:**
   - If you find a model that deforms at runtime, report it with:
     - Model source/download link (if publicly available)
     - Screenshot of the deformation
     - VRM version (0.x or 1.0)

### Technical Details (For Developers)

The issue appears related to:
- Reference pose initialization order in `VrmConvertModel.cpp`
- Skin weight buffer creation for runtime-generated skeletal meshes
- Bone scale handling in the runtime animation update path
- Potential morph target application timing issues

A fix is in progress that ensures runtime-loaded skeletal meshes have:
- Correct reference pose matching standard import
- Properly initialized skin weight buffers
- Consistent bone scale handling between paths

---

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
