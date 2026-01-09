# UE5.7 Retargeting Fix for VRM4U

## Overview

Starting with Unreal Engine 5.7, the IK Rig system requires different configuration for stable lower-body retargeting. VRM4U now automatically generates version-appropriate IK Rig configurations.

## What Changed

### UE5.6 and Earlier
- IK goals placed on **toe bones** (`leftToes`, `rightToes`)
- Leg chains end at toe bones
- Configuration: `table_no=0`, mask `0x01`

### UE5.7 and Later
- IK goals placed on **foot bones** (`leftFoot`, `rightFoot`)
- Leg chains end at foot bones
- Separate toe chains created if needed
- Configuration: `table_no=1`, mask `0x02`

## For New Imports

When you import a VRM file in VRM4U with UE5.7+, the correct foot-based IK Rig configuration is automatically generated. No manual changes needed.

## Migrating Existing Assets from UE5.6

If you have VRM assets imported in UE5.6 that exhibit broken leg/foot animations in UE5.7, you have two options:

### Option 1: Reimport the VRM (Recommended)

1. Locate your original `.vrm` file
2. Delete the existing IK Rig assets (e.g., `IK_YourModel_Mannequin`)
3. Re-import the VRM file
4. VRM4U will generate new UE5.7-compatible IK Rig assets

### Option 2: Use the Migration Utility (UE5.7+ Only)

VRM4U provides a Blueprint-callable editor utility function to update existing IK Rigs:

#### Quick Method: Run the Python Script

The easiest way to migrate multiple assets is using the provided Python script:

1. Open your UE5.7+ project in Unreal Editor
2. Enable Python scripting if not already enabled:
   - Edit > Plugins > Search for "Python Editor Script Plugin" > Enable and restart
3. Open the Output Log: Window > Developer Tools > Output Log
4. Run the migration script:
   - Tools > Execute Python Script...
   - Navigate to `Plugins/VRM4U/Content/Python/VRM4U_FixIKRigUE57.py`
   - Click "Open" to execute

The script will automatically find and fix all VRM IK Rig assets in your project.

#### Manual Method: Via Blueprint (Editor Utility Widget):

```cpp
// Create an Editor Utility Widget or Editor Utility Blueprint
// Add this node:
bool Success = VrmEditorBPFunctionLibrary::FixIKRigForUE57Retargeting(YourIKRigAsset);
```

#### Manual Method: Via Python Console:

```python
import unreal

# Load your IK Rig asset
ik_rig = unreal.load_asset('/Game/YourVRMModel/IK_YourModel_Mannequin')

# Fix it for UE5.7
success = unreal.VrmEditorBPFunctionLibrary.fix_ik_rig_for_ue57_retargeting(ik_rig)

if success:
    print("IK Rig updated successfully for UE5.7!")
    # Save the asset
    unreal.EditorAssetLibrary.save_loaded_asset(ik_rig)
else:
    print("Failed to update IK Rig. Check the log for details.")
```

The migration utility will:
- Remove toe-based IK goals (`leftToes_Goal`, `rightToes_Goal`)
- Create foot-based IK goals (`leftFoot_Goal`, `rightFoot_Goal`)
- Update leg retarget chains to end at feet instead of toes
- Preserve solver connections and settings
- Mark the asset as modified (remember to save!)

## Technical Details

### Code Changes

The fix is implemented in `Source/VRM4ULoader/Private/VrmConvertIKRig.cpp`:

1. **LocalSolverSetup function** (line ~133):
   - Added automatic version detection
   - Selects appropriate goal configuration based on engine version

2. **Retarget chain creation** (line ~1333):
   - Uses version-appropriate mask to select toe-based or foot-based chains

3. **LocalSolverSetup call** (line ~1397):
   - Explicitly passes version-appropriate table_no

### Version Detection

```cpp
#if UE_VERSION_OLDER_THAN(5,7,0)
    table_no = 0; // Use toe-based goals for UE5.6 and earlier
#else
    table_no = 1; // Use foot-based goals for UE5.7+
#endif
```

## Troubleshooting

### My animations still look broken after migration

1. **Clear intermediate files**: Delete the `Intermediate/` and `Saved/` folders in your project
2. **Check IK Rig configuration**:
   - Open the IK Rig asset (e.g., `IK_YourModel_Mannequin`)
   - Verify goals are on `leftFoot` and `rightFoot` (not `leftToes`/`rightToes`)
   - Check that leg chains end at foot bones
3. **Rebuild retargeter**: Delete and recreate the retargeter asset (`RTG_YourModel`)

### Migration utility reports "no toe-based goals found"

Your IK Rig is likely already configured for UE5.7+ or has a custom configuration. No migration needed.

### I need both UE5.6 and UE5.7 compatibility

Unfortunately, the IK Rig configuration is version-specific. Recommended approach:
1. Keep separate project versions or branches for UE5.6 and UE5.7
2. Or maintain two sets of IK Rig assets (one for each version)

## References

- Original Issue: [AlisonLuan/VRM4U#558](https://github.com/AlisonLuan/VRM4U/issues/558)
- Unreal Engine IK Rig Documentation: [IK Rig in Unreal Engine](https://docs.unrealengine.com/5.7/en-US/ik-rig-in-unreal-engine/)

## Version History

- **VRM4U 2025-01-09**: Added automatic UE5.7 detection and migration utility
