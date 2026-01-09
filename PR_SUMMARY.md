# Pull Request Summary: Fix UE5.7 VRM Retargeting

## Issue Reference
Fixes #558 - UE5.7: VRM4U retargeter produces broken leg/foot IK on Manny animations

## Problem Statement
In Unreal Engine 5.7, VRM characters imported via VRM4U show incorrect lower-body animation when retargeting default "Unarmed Manny" animations. Walk/Jog/Jump exhibit unstable or incorrect leg/foot behavior. The same VRM assets work correctly in UE 5.6.

**Root Cause**: UE5.7 changed the mannequin IK Rig expectations. VRM leg chains ending at toes (UE5.6 style) cause unstable foot IK in UE5.7. The solution requires moving IK goals and chain ends from toes to feet.

## Solution Overview

This PR implements a **version-aware** IK Rig generation system that automatically produces the correct configuration based on the Unreal Engine version:

- **UE5.6 and earlier**: Generates toe-based IK goals (`leftToes`, `rightToes`)
- **UE5.7 and later**: Generates foot-based IK goals (`leftFoot`, `rightFoot`)

Additionally, provides migration tools for existing UE5.6 assets to be updated for UE5.7.

## Changes Made

### 1. Core Fix: Automatic Version Detection
**File**: `Source/VRM4ULoader/Private/VrmConvertIKRig.cpp`

- Added `UE_VERSION_OLDER_THAN(5,7,0)` checks in three critical locations:
  1. `LocalSolverSetup()` function - selects appropriate goal bones (line ~133)
  2. Retarget chain mask selection - filters toe vs. foot chains (line ~1333)
  3. LocalSolverSetup call - passes correct table_no parameter (line ~1397)
  
- Applied same logic to BVH model handling for consistency

**Impact**: New VRM imports automatically generate correct IK Rig for current UE version.

### 2. Asset Migration Utility
**Files**: 
- `Source/VRM4UEditor/Public/VrmEditorBPFunctionLibrary.h`
- `Source/VRM4UEditor/Private/VrmEditorBPFunctionLibrary.cpp`

Added `FixIKRigForUE57Retargeting()` function (Blueprint-callable, UE5.7+ only):
- Detects toe-based goals in existing IK Rigs
- Removes old goals, creates new foot-based goals
- Preserves solver connections and chain assignments
- Updates retarget chains to end at feet instead of toes
- Comprehensive logging for transparency

**Impact**: Users can migrate existing UE5.6 assets without reinstalling UE5.6.

### 3. Automated Batch Migration Script
**File**: `Content/Python/VRM4U_FixIKRigUE57.py`

Python script for editor automation:
- Auto-discovers all VRM IK Rig assets in project
- Applies migration to each asset
- Provides detailed progress logging
- Includes safety confirmation requirement
- Saves modified assets automatically

**Impact**: Large projects with many VRM assets can be migrated in one operation.

### 4. Comprehensive Documentation
**Files**:
- `UE57_RETARGETING_FIX.md` (new) - Complete migration guide
- `README.md`, `README_en.md` - Added UE5.7 compatibility notices

Documentation includes:
- Technical explanation of the change
- Step-by-step migration instructions
- Multiple migration methods (reimport, manual, automated)
- Troubleshooting guide
- Python script usage

## Technical Details

### Version Detection Logic
```cpp
if (table_no == 0xFFFF) {  // Auto-detect mode
#if UE_VERSION_OLDER_THAN(5,7,0)
    table_no = 0; // Toe-based goals for UE5.6 and earlier
#else
    table_no = 1; // Foot-based goals for UE5.7+
#endif
}
```

### IK Goal Configuration
| UE Version | table_no | Goal Bones | Chain Ends | Mask Bit |
|------------|----------|------------|------------|----------|
| 5.6 and earlier | 0 | leftToes, rightToes | *Toes | 0x01 |
| 5.7 and later | 1 | leftFoot, rightFoot | *Foot | 0x02 |

## Testing Performed

### Code Quality
- ✅ Addressed all code review feedback
- ✅ Refactored duplicate logic with helper lambdas
- ✅ Fixed C++ style issues (spacing, templates)
- ✅ Added safety confirmations to automation scripts

### Compilation
- ⚠️ Cannot test compilation without UE installation
- 📋 **Recommended**: Build in both UE5.6 and UE5.7 to verify

### Functional Testing Required
1. **UE5.7 new import**: Verify foot-based IK Rig generation
2. **UE5.6 compatibility**: Verify toe-based IK Rig generation
3. **Migration utility**: Test on a UE5.6→5.7 migrated project
4. **Animation quality**: Retarget Manny walk/jog/jump, verify smooth motion
5. **Python script**: Test automated batch migration

## Breaking Changes
**None** - This is a backward-compatible fix:
- UE5.6 and earlier: Behavior unchanged
- UE5.7+: Automatically uses correct configuration
- Migration is opt-in for existing projects

## Migration Guide for Users

### For New Projects (UE5.7+)
No action needed - VRM imports will automatically use the correct configuration.

### For Existing Projects (UE5.6 → UE5.7)
Choose one method:

1. **Reimport VRM** (Recommended)
   - Delete old IK Rig assets
   - Re-import the VRM file
   
2. **Use Python Migration Script** (Batch)
   - Enable Python plugin
   - Run `Content/Python/VRM4U_FixIKRigUE57.py`
   
3. **Manual Migration** (Single asset)
   - Call `VrmEditorBPFunctionLibrary::FixIKRigForUE57Retargeting()` in BP or Python

See [UE57_RETARGETING_FIX.md](./UE57_RETARGETING_FIX.md) for detailed instructions.

## Files Changed
```
Content/Python/VRM4U_FixIKRigUE57.py                      | 159 ++++++++++
README.md                                                 |   3 +
README_en.md                                              |   3 +
Source/VRM4UEditor/Private/VrmEditorBPFunctionLibrary.cpp | 209 +++++++++++++
Source/VRM4UEditor/Public/VrmEditorBPFunctionLibrary.h    |  11 +
Source/VRM4ULoader/Private/VrmConvertIKRig.cpp            |  53 ++--
UE57_RETARGETING_FIX.md                                   | 142 ++++++++++
```
**Total**: 7 files changed, 564 insertions(+), 16 deletions(-)

## Checklist
- [x] Code changes implement version-aware IK Rig generation
- [x] Migration utility function implemented and documented
- [x] Automated batch migration script provided
- [x] Documentation complete with troubleshooting
- [x] README files updated
- [x] Code review feedback addressed
- [x] No breaking changes
- [ ] Compilation verified (requires UE installation)
- [ ] Functional testing with UE5.6 and UE5.7 (requires testing environment)

## Next Steps
1. **Code Review**: Request review from maintainers
2. **Build Verification**: Compile in UE5.6 and UE5.7
3. **Testing**: Functional tests with actual VRM assets
4. **Release**: Include in next VRM4U version with release notes
5. **Documentation**: Update wiki/website if applicable

---

**Closes #558**
