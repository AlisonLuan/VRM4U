# SpringBone Physics & Runtime Load Diagnostics - Implementation Notes

**Issues Addressed:**
- #553: SpringBone physics missing in GASP with VRoid 2.3.x exports
- #536: Runtime-loaded "NicoNico Rittai-chan" neck mesh stretching

**Date:** January 2026
**Target Version:** UE5.6.1+

---

## Summary

This implementation adds **comprehensive diagnostics and validation** for two user-reported issues related to SpringBone physics and runtime mesh loading in VRM4U. Without access to specific test models and environments, the approach focuses on:

1. **Detailed logging** to help users identify root causes
2. **Runtime validation** to detect problematic conditions
3. **Comprehensive documentation** with troubleshooting steps
4. **Thread-safe implementation** suitable for production use

---

## Changes Made

### 1. SpringBone Initialization Logging

**Files Modified:**
- `Source/VRM4U/Private/VrmSpringBone.cpp`
- `Source/VRM4U/Private/AnimNode_VrmSpringBone.cpp`
- `Source/VRM4ULoader/Private/VrmConvertMetadata.cpp`

**What it does:**

#### VRM0 SpringBone (Legacy)
Logs when initializing spring bones:
- Total spring group count
- Bone counts per group (found vs total)
- Warnings for missing bones in skeleton
- Collider group and total collider count
- Success/failure status

Example log output:
```
[VRM4U SpringBone] Initializing VRM0 SpringBone: Found 3 spring groups in metadata
[VRM4U SpringBone] Spring group 0: 8/8 bones found (stiffness=0.50, gravity=0.20, drag=0.40, hitRadius=0.05)
[VRM4U SpringBone] Initialized 2 collider groups with 6 total colliders
[VRM4U SpringBone] VRM0 SpringBone initialization complete. Physics is active.
```

#### VRM1 SpringBone (Modern)
Logs when initializing joints:
- Spring count, collider count, collider group count
- Detailed warnings for invalid joints (missing bone, no parent, out of range)
- Success/failure count

Example log output:
```
[VRM4U SpringBone] Initializing VRM1 SpringBone: 2 springs, 4 colliders, 2 collider groups
[VRM4U SpringBone] VRM1 SpringBone initialization complete. 12/12 joints initialized successfully. Physics is active.
```

#### Import-Time Warnings
Logs during VRM file import:
- Warns if VRM1.0 model missing `VRMC_springBone` extension
- Warns if VRM0 model has `springNum=0` (no physics data)
- Suggests possible causes (older VRoid version, model without secondary animation)

### 2. AnimNode Runtime Warnings

**Files Modified:**
- `Source/VRM4U/Private/AnimNode_VrmSpringBone.cpp`
- `Source/VRM4U/Public/AnimNode_VrmSpringBone.h`

**What it does:**

#### Per-Instance Warning Flags
Added thread-safe warning flags to track whether warnings have been logged:
```cpp
private:
    bool bHasLoggedMetaObjectWarning = false;
    bool bHasLoggedManagerWarning = false;
```

These are per-AnimNode-instance, avoiding:
- Thread-safety issues with static bools
- Log spam in multi-threaded animation evaluation
- Race conditions between animation threads

#### Warning Conditions
1. **Missing VrmMetaObject:**
   - Logs: `"VrmMetaObject is null. SpringBone physics cannot run."`
   - Suggests: Check AnimNode has valid reference or EnableAutoSearchMetaData is true

2. **Missing SpringManager:**
   - Logs: `"SpringManager is null. This should not happen - initialization failed."`
   - Indicates: Internal error (should be investigated if seen)

### 3. Runtime Load Mesh Validation

**Files Modified:**
- `Source/VRM4ULoader/Private/VrmConvertModel.cpp`

**What it does:**

#### Non-Uniform Bone Scale Detection
Checks each bone's scale for uniformity after skeleton creation:
```cpp
// Check if scale is uniform (all components equal within tolerance)
const float ScaleAvg = (Scale.X + Scale.Y + Scale.Z) / 3.0f;
const float MaxDiff = FMath::Max3(
    FMath::Abs(Scale.X - ScaleAvg),
    FMath::Abs(Scale.Y - ScaleAvg),
    FMath::Abs(Scale.Z - ScaleAvg));
if (MaxDiff > 0.01f) {
    NonUniformScaleBones++;
}
```

Warns if non-uniform scales detected:
```
[VRM4U RuntimeLoad] 3 bones have non-uniform scale. This may cause mesh deformation when animated. Affected model: SK_Character_C
```

**Why this matters:**
Non-uniform bone scales can cause mesh stretching/deformation during animation because:
- Skinning matrices may not account for non-uniform parent scale correctly
- Animation blending with non-uniform scale can produce unexpected results
- Different code paths (runtime vs editor) may handle scale differently

#### Render Data Validation
Checks mesh resources after `InitResources()`:
```cpp
const FSkeletalMeshRenderData* RenderData = sk->GetResourceForRendering();
if (RenderData && RenderData->LODRenderData.Num() > 0) {
    const FSkeletalMeshLODRenderData& LODData = RenderData->LODRenderData[0];
    // Check for issues
}
```

Logs:
- LOD count, section count, required bone count (normal case)
- Warning if no required bones but sections exist (potential bug)
- Warning if render data unavailable (initialization failure)

Example output:
```
[VRM4U RuntimeLoad] Mesh initialized: 1 LODs, 3 sections in LOD0, 42 required bones. Model: SK_Character_C
```

### 4. Troubleshooting Documentation

**Files Modified:**
- `TROUBLESHOOTING.md`

**What it adds:**

#### SpringBone Physics Issues Section
Comprehensive guide covering:
- Common symptoms and diagnostic steps
- How to check Output Log for initialization messages
- VRoid Studio version compatibility (2.3.x vs 2.4.1+)
- GASP project specific troubleshooting
- AnimNode configuration checklist
- Enable verbose logging instructions
- Testing with known-good VRM files

#### Runtime Load Mesh Deformation Section
Documents Issue #536 with:
- Common symptoms (neck/limb stretching)
- Known affected models
- Diagnostic steps to distinguish from other issues
- Current status and limitations
- Workarounds (use standard import, test before shipping)
- Technical details for developers
- How to report new cases

---

## Design Decisions

### Why Diagnostics Instead of Fixes?

Without access to:
1. Specific VRM models that exhibit the issues
2. VRoid 2.3.x export samples to compare format
3. UE5.6.1 + GASP test environment
4. Reproduction steps

Implementing a "fix" would be **guessing** and could:
- Introduce new bugs
- Not actually solve the user's problem
- Break working cases

Instead, this implementation provides:
- **Information** for users to solve their own issues
- **Diagnostics** for developers to debug future cases
- **Detection** of known problematic conditions
- **Documentation** of workarounds and best practices

### Thread-Safety Approach

Original code used `static bool bWarningLogged` which is problematic because:
- Multiple AnimNode instances share the same flag
- Animation evaluation can be multi-threaded
- Race conditions can occur
- One instance's warning suppresses others

New approach uses per-instance member variables:
- Each AnimNode tracks its own warning state
- Thread-safe because each thread operates on different instances
- No race conditions or shared state
- Better for debugging (each instance can warn independently)

### Log Prefixes

Consistent prefixes for easy filtering:
- `[VRM4U SpringBone]` - All SpringBone-related messages
- `[VRM4U RuntimeLoad]` - All runtime load validation messages

Users can filter logs:
```
LogVRM4U: [VRM4U SpringBone] ...
LogVRM4ULoader: [VRM4U SpringBone] Parsing VRM0 SpringBone: ...
LogVRM4ULoader: [VRM4U RuntimeLoad] ...
```

### Validation Timing

Validations run at strategic points:
1. **Import time:** When VRM file is first parsed
2. **Skeleton creation:** After reference skeleton is built
3. **Mesh initialization:** After InitResources completes
4. **Animation init:** When AnimNode first initializes

This catches issues as early as possible while avoiding false positives.

---

## Testing Without Test Models

Since we don't have access to the specific models, the implementation was validated through:

1. **Code Review:** Addressed all feedback (thread-safety, algorithm efficiency, documentation)
2. **Static Analysis:** No security issues found by CodeQL
3. **Logic Review:** Validation logic based on engine internals and VRM spec
4. **Log Format:** Consistent with existing VRM4U logging patterns
5. **Documentation:** Clear troubleshooting steps that users can follow

---

## What Users Will See

### Scenario 1: VRoid 2.3.x Export Missing SpringBone

**Import time:**
```
LogVRM4ULoader: Warning: [VRM4U SpringBone] VRM0 model but no SpringBone data found (springNum=0). 
                SpringBone physics will not work. This may indicate an older VRoid export version or 
                model without secondary animation.
```

**User action:** Re-export from VRoid 2.4.1+ and reimport.

### Scenario 2: AnimNode Misconfigured

**Runtime:**
```
LogVRM4U: Warning: [VRM4U SpringBone] VrmMetaObject is null. SpringBone physics cannot run. 
          Make sure the AnimNode has a valid VrmMetaObject reference or EnableAutoSearchMetaData is true.
```

**User action:** Check Animation Blueprint node settings.

### Scenario 3: Runtime Load with Non-Uniform Scale

**Load time:**
```
LogVRM4ULoader: Warning: [VRM4U RuntimeLoad] 3 bones have non-uniform scale. This may cause mesh 
                deformation when animated. Affected model: SK_NicoNico_Rittaichan_C
LogVRM4ULoader: Log: [VRM4U RuntimeLoad] Mesh initialized: 1 LODs, 5 sections in LOD0, 56 required bones. 
                Model: SK_NicoNico_Rittaichan_C
```

**User action:** Check TROUBLESHOOTING.md, use standard import if deformation occurs.

---

## Future Improvements

When test models become available:

### For Issue #553 (SpringBone Missing)
1. Compare VRoid 2.3.x vs 2.4.1 JSON structure
2. Identify specific field differences
3. Add backward-compatible parsing if data is valid but encoded differently
4. Add automatic migration/conversion if feasible

### For Issue #536 (Runtime Mesh Deformation)
1. Reproduce with Rittai-chan or similar model
2. Compare runtime vs standard import skeletal mesh state
3. Identify exact point where deformation is introduced
4. Implement targeted fix (likely reference pose or scale handling)
5. Add regression test with affected model

### Additional Diagnostics
- Bone hierarchy validation
- Skin weight sanity checks
- Morph target range validation
- Memory usage logging for large models

---

## Maintenance Notes

### Log Levels
- **Error:** Never used (nothing is fatal)
- **Warning:** Used for user-actionable issues
- **Log:** Used for informational messages during normal operation

### Backward Compatibility
All changes are additive:
- No breaking API changes
- No changes to asset formats
- No changes to existing behavior (only adds logging/warnings)
- Safe to deploy to existing projects

### Performance Impact
Minimal:
- Logging only during initialization (not per-frame)
- Validation runs once per model load
- No runtime overhead during animation
- Thread-safe member variables (no synchronization needed)

---

## Related Issues & Documentation

- GitHub Issue #553: UE 5.6 GASP – Spring Bones don't work / no physics
- GitHub Issue #536: "NicoNico Rittai-chan" model neck mesh stretches when using `VRM4U_runtimeload`
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - User-facing troubleshooting guide
- [VRM 0.x Specification](https://github.com/vrm-c/vrm-specification/tree/master/specification/0.0)
- [VRM 1.0 Specification](https://github.com/vrm-c/vrm-specification/tree/master/specification/VRMC_vrm-1.0)

---

## Contact

For questions about this implementation:
- Check TROUBLESHOOTING.md first
- Search GitHub Issues for similar problems
- Create new issue with reproduction steps and log output
