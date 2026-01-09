# Thumb Control Fix for VRM 0.x Models (Issue #561)

## Problem Summary

In Unreal Engine 5.7.1 (and potentially earlier versions), Control Rigs generated from VRM 0.x models (such as VRoid Studio exports) exhibit thumb control misalignment:

- `thumb01_ctrl` is positioned at the `thumb02` bone location
- `thumb02_ctrl` is offset from expected position
- `thumb03_ctrl` is correctly positioned

This causes finger deformation and "snapping" when using Backwards Solve during animation baking.

## Root Cause

VRM 0.x specification uses ambiguous thumb bone naming:
- "Proximal" refers to the metacarpal bone (first bone from hand)
- "Intermediate" refers to the proximal phalange (second bone)
- "Distal" refers to the distal phalange (third bone)

This differs from anatomical naming and VRM 1.0 specification, leading to an off-by-one error in control positioning.

## Solution

The fix has been implemented in the Control Rig generation Python scripts:
- `Content/Python/VRM4U_CreateHumanoidControllerUE5.py`
- `Content/Python/VRM4U_CreateHumanoidController.py`

### What the Fix Does

1. **Detects off-by-one error:** Checks if thumb bone mapping follows the pattern Proximal→thumb2, Intermediate→thumb3
2. **Automatically corrects mapping:** Shifts mappings to Proximal→thumb1, Intermediate→thumb2, Distal→thumb3
3. **Provides logging:** Shows detected issues and applied corrections in the Output Log

### How to Apply the Fix

#### For New Control Rigs

1. Import your VRM model as usual
2. Duplicate `CR_VRoidSimpleUE5Body` from `VRM4U/Util/Actor/latest/`
3. Open the duplicated Control Rig and set Preview Mesh to your VRM skeletal mesh
4. Open `WBP_ControlRig` (VRM4U utility widget)
5. Assign your edited Control Rig asset
6. Click **Generate AllRig / BodyRig**
7. The fix will automatically apply if thumb bones are detected as misaligned
8. Check the Output Log for confirmation messages

#### For Existing Control Rigs

Existing generated Control Rigs need to be regenerated:

1. **Back up your project** (recommended)
2. Delete the old generated Control Rig assets
3. Follow the "For New Control Rigs" steps above

## Configuration

The automatic fix is **enabled by default**. To disable it (if needed):

1. Open `Content/Python/VRM4U_CreateHumanoidControllerUE5.py` in a text editor
2. Find the line: `FIX_THUMB_MAPPING_FOR_VRM0X = True`
3. Change to: `FIX_THUMB_MAPPING_FOR_VRM0X = False`
4. Save and regenerate your Control Rig

## Verification

After generating a Control Rig with the fix:

1. Open the Control Rig editor
2. Select thumb controls (named with pattern `{humanoidBone}_c`, e.g., `leftthumbproximal_c`, `leftthumbintermediate_c`, `leftthumbdistal_c`)
3. Verify each control is positioned at its corresponding humanoid thumb bone:
   - `leftthumbproximal_c` should be at the first thumb bone (e.g., `j_bip_l_thumb1` or `thumb_01_l`)
   - `leftthumbintermediate_c` should be at the second thumb bone (e.g., `j_bip_l_thumb2` or `thumb_02_l`)
   - `leftthumbdistal_c` should be at the third thumb bone (e.g., `j_bip_l_thumb3` or `thumb_03_l`)
4. Repeat for right hand controls (e.g., `rightthumbproximal_c`, `rightthumbintermediate_c`, `rightthumbdistal_c`)

## Testing Animation Baking

1. Apply a retargeted animation (e.g., Mixamo "typing") to your character
2. Enable the layered Control Rig
3. Bake the animation
4. Verify fingers (especially thumbs) do not bend backwards or snap

## Troubleshooting

### Fix Not Applied

If you see the message "Thumb bone mapping appears correct", the fix determined your model doesn't need correction. This could mean:
- Your model already has correct mapping
- Bone names don't follow the expected pattern (thumb1/thumb2/thumb3)

### Controls Still Misaligned

If controls are still misaligned after applying the fix:
1. Check the Output Log for error messages
2. Verify your VRM model's thumb bone names (should contain "thumb" and numbers 1/2/3)
3. Set `FIX_THUMB_MAPPING_FOR_VRM0X = True` and regenerate
4. Report the issue with:
   - VRM model source (VRoid Studio version, etc.)
   - Thumb bone names from your model
   - Output Log contents

## Additional Improvements

This fix also includes:
- **Error handling:** Better error messages when bones aren't found
- **Name normalization:** Trims whitespace from bone names
- **Debug logging:** Detailed logging for thumb bone operations

## Technical Details

For developers interested in the implementation:

**Detection Logic:**
```python
# Extracts numbers from bone names (e.g., "j_bip_l_thumb2" → 2)
# If Proximal→thumb2 and Intermediate→thumb3, triggers fix
```

**Correction Logic:**
```python
# Searches for thumb1 bone in skeleton
# Shifts mapping: Proximal→thumb1, Intermediate→thumb2, Distal→thumb3
```

## Related Issues

- GitHub Issue: #561
- Affects: UE5.7.1 (potentially earlier versions)
- VRM Version: 0.x (VRoid Studio exports)
- Unaffected: VRM 1.0 models (use Metacarpal/Proximal/Distal naming)

## Credits

Fix developed for VRM4U plugin issue #561.
