# Fix for Issue #548: UE5.7.0 PMX SkeletalMesh Import Crash

## Summary

Fixed a crash in Unreal Engine 5.7.0+ when opening imported PMX (and potentially other format) SkeletalMesh assets. The crash was caused by an empty MeshDescription triggering an "Array index out of bounds" assertion.

## Root Cause

In UE5.7.0, the Skeletal Mesh Editor initialization path calls `CreateMeshDescription`, which expects the mesh to have valid vertex and triangle data. When a model import failed or produced incomplete data (e.g., due to texture errors, missing bones, or corrupted mesh data), the resulting SkeletalMesh asset had:

- Empty or uninitialized MeshDescription
- Zero vertices in the position buffer
- No LOD render data

Opening such an asset in the editor would trigger array bounds checks, causing an immediate crash with errors like:
```
LogAnimation: Error: Skeleton Modifier: mesh description is empty.
Assertion failed: (Index >= 0) & (Index < ArrayNum)
Array index out of bounds: 0 into an array of size 0
```

## Changes Made

### 1. Early Mesh Data Validation (VrmConvertModel.cpp)

**Location**: After vertex/triangle counting (lines 851-868)

**What**: Added validation to check for empty mesh data before proceeding with SkeletalMesh construction.

**Why**: Prevents creation of invalid SkeletalMesh assets that would crash when opened. Fails early with clear error messages rather than creating unusable assets.

**Special Cases**: Skips validation when `IsDebugNoMesh()` is true (for VRMA animation-only imports).

```cpp
if (VRMConverter::Options::Get().IsDebugNoMesh() == false) {
    if (allVertex == 0 || allIndex == 0) {
        UE_LOG(LogVRM4ULoader, Error, TEXT("VRM4U: Import failed - mesh has no vertices or triangles..."));
        return false;
    }
}
```

### 2. Pre-PostLoad Validation (LoaderBPFunctionLibrary.cpp)

**Location**: Before calling `PostLoad()` on SkeletalMesh (lines 839-869)

**What**: Added comprehensive validation of SkeletalMesh render data before calling `PostLoad()`.

**Why**: The existing UE5.7 fix (calling `PostLoad()` to initialize MeshDescription) assumes the mesh has valid data. This validation ensures we don't call `PostLoad()` on an invalid mesh.

**Validation Steps**:
1. Check SkeletalMesh is non-null
2. Verify render data exists and has at least one LOD
3. Confirm LOD has at least one vertex
4. Only then call `PostLoad()`

**Special Cases**: Only validates geometry for non-NoMesh imports, but always validates that the SkeletalMesh object exists.

```cpp
if (out->SkeletalMesh) {
    if (VRMConverter::Options::Get().IsDebugNoMesh() == false) {
        FSkeletalMeshRenderData* RenderData = out->SkeletalMesh->GetResourceForRendering();
        if (!RenderData || RenderData->LODRenderData.Num() == 0) {
            UE_LOG(LogVRM4ULoader, Error, TEXT("VRM4U: SkeletalMesh has no LOD render data..."));
            RemoveAssetList(out);
            return false;
        }
        // Additional vertex count validation...
    }
    out->SkeletalMesh->PostLoad();
} else {
    UE_LOG(LogVRM4ULoader, Error, TEXT("VRM4U: SkeletalMesh is null..."));
    RemoveAssetList(out);
    return false;
}
```

### 3. Improved Texture Error Handling (VrmConvertTexture.cpp, VrmLoaderUtil.cpp)

**What**: 
- Added null/empty data check in `LoadImageFromMemory` (VrmLoaderUtil.cpp:609-612)
- Added null check after texture creation with graceful degradation (VrmConvertTexture.cpp:732-739)

**Why**: Texture loading failures (e.g., "Bmp header invalid") were contributing to incomplete imports. Instead of propagating failures upward, textures now fail individually with warnings while the import continues.

**Impact**: Models with some corrupted textures can now import successfully. Materials will reference null textures, which is better than a complete import failure.

```cpp
if (NewTexture2D == nullptr) {
    UE_LOG(LogVRM4ULoader, Warning, TEXT("VRM4U: Failed to create texture '%s'..."));
    UE_LOG(LogVRM4ULoader, Warning, TEXT("  This texture will be skipped..."));
    textureCompressTypeArray.Add(EVRMImportTextureCompressType::VRMITC_DXT1);
    vrmAssetList->Textures.Add(nullptr);
    continue;  // Continue with remaining textures
}
```

### 4. Humanoid Asset Error Handling (VrmConvertRig.cpp)

**Location**: UE < 5.0 Humanoid Rig loading (lines 138-151)

**What**: Added null check for `/Engine/EngineMeshes/Humanoid` asset with graceful degradation.

**Why**: Missing engine content shouldn't block imports. The warning in the issue logs suggested this was a contributing factor, though not the direct cause.

**Impact**: Import continues without retargeting setup if engine humanoid asset is missing.

## Error Messages Added

All new error messages follow a consistent format:

1. **Primary error**: Clear statement of what failed
2. **Context**: Why it matters (e.g., "will cause crash in UE5.7+")
3. **Guidance**: What the user should check or do next

Examples:
```
VRM4U: Import failed - mesh has no vertices or triangles. Vertices=0, Triangles=0. This may be caused by:
  - Invalid or corrupted model file
  - Unsupported model format version
  - Missing mesh data in the source file
Please verify the model file is valid and try re-exporting from the source application.
```

```
VRM4U: SkeletalMesh has no vertices. This will cause a crash when opening the asset in UE5.7+.
Please check the source model file for corruption or missing mesh data.
```

## Testing Recommendations

### Regression Testing (UE 5.1-5.6)

1. **Valid PMX imports**: Ensure normal PMX files still import correctly
2. **VRM imports**: Test VRM 0.x and VRM 1.0 models
3. **VRMA imports**: Verify animation-only imports work (NoMesh path)
4. **Texture variations**: Test models with various texture formats (PNG, JPEG, BMP)

### UE5.7+ Validation

1. **Empty mesh handling**: The original crash scenario should now fail gracefully with clear errors
2. **Partial corruption**: Models with some texture errors should import with warnings
3. **Asset opening**: Successfully imported meshes should open without crashes

### Edge Cases

1. **Zero-vertex mesh**: Should be caught and rejected with error
2. **Missing bones**: Should be handled by existing bone validation
3. **Missing engine content**: Should warn but continue (UE < 5.0 only)
4. **VRMA with no skeleton**: Should work if NoMesh is set

## Files Modified

1. `Source/VRM4ULoader/Private/VrmConvertModel.cpp`
   - Added early mesh data validation
   - Prevents creation of invalid assets

2. `Source/VRM4ULoader/Private/LoaderBPFunctionLibrary.cpp`
   - Added pre-PostLoad validation
   - Ensures MeshDescription is populated before editor access

3. `Source/VRM4ULoader/Private/VrmConvertTexture.cpp`
   - Improved texture failure handling
   - Allows partial texture failures

4. `Source/VRM4ULoader/Private/VrmLoaderUtil.cpp`
   - Added input validation for image loading
   - Better error messages for image format issues

5. `Source/VRM4ULoader/Private/VrmConvertRig.cpp`
   - Added null check for Humanoid asset (UE < 5.0)
   - Prevents crashes from missing engine content

## Backward Compatibility

- **UE 5.1-5.6**: No behavior changes for valid models. Invalid models now fail more gracefully.
- **UE < 5.0**: Humanoid asset loading is more robust, but functionality is otherwise unchanged.
- **VRMA/NoMesh**: Properly handled with conditional validation.

## Related Issues

- Maintainer comment (Oct 17, 2025): "Please use the latest plugin. This fixes an issue where initialization was insufficient in UE5.7."
  - The `PostLoad()` call at line 863 of LoaderBPFunctionLibrary.cpp is the fix referenced
  - Our changes add defensive guardrails around this fix

## Future Enhancements

Consider adding:
1. **Import validation UI**: Pre-import checks that warn about potential issues
2. **Mesh repair**: Automatic fixing of minor mesh issues (degenerate triangles, duplicate vertices)
3. **Asset health check**: Editor utility to validate existing assets and flag problematic ones
4. **Automated tests**: Unit tests for mesh validation logic with fixture files

## References

- GitHub Issue: #548
- UE5.7 Retargeting Fix: UE57_RETARGETING_FIX.md (different issue, for reference)
- Related code: VrmConvertModel.cpp InitResources calls (UE5.7 version gating at line 1867-1871)
