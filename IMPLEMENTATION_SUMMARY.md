# VMC Troubleshooting Implementation Summary

## Overview

This implementation addresses GitHub issues #551 and #552 by adding comprehensive diagnostics, documentation, and troubleshooting guides for VMC (Virtual Motion Capture) functionality in VRM4U.

## Issues Addressed

### Issue #551: "Character can't move"
- **Problem:** Character receives VMC rotation data but root position is locked
- **Root Cause:** Skeleton root bone translation retargeting set to "Animation" instead of "Skeleton"
- **Solution:** Documented the required setting and added diagnostics to help users identify this

### Issue #552: "Can't send/receive VMC data"
- **Problem:** VMC data not working after update, even in sample map
- **Root Cause:** Port/network configuration mismatch or misconfiguration
- **Solution:** Added diagnostic logging and comprehensive network troubleshooting guide

## Implementation Details

### 1. Console Variable for Debug Mode

**File:** `Source/VRM4UCapture/Private/VRM4UCapture.cpp`

Added `vrm4u.VMC.Debug` console variable:
- Default: 0 (disabled)
- When enabled (1): Logs detailed VMC diagnostics
- Zero performance impact when disabled
- Usage: Type `vrm4u.VMC.Debug 1` in UE console

### 2. Diagnostic Tracking

**File:** `Source/VRM4UCapture/Public/VrmVMCObject.h`

Added diagnostic fields to UVrmVMCObject:
- `TotalPacketsReceived` - Track total packet count
- `LastPacketReceivedTime` - Timestamp of last packet
- `bHasReceivedRootTranslation` - Flag for root translation data
- `LastBoneCount` / `LastCurveCount` - Data content tracking

Public getter methods for querying diagnostic state.

### 3. Enhanced Logging

**Files Modified:**
- `Source/VRM4UCapture/Private/VrmVMCObject.cpp`
- `Source/VRM4UCapture/Private/AnimNode_VrmVMC.cpp`
- `Source/VRM4UCapture/Private/VRM4U_VMCSubsystem.cpp`

**Logging Added:**

**On Server Creation:**
```cpp
LogVRM4UCapture: VMC: Successfully created OSC server '0.0.0.0' on port 39539
LogVRM4UCapture: VMC AnimNode: Initialized VMC receiver on 0.0.0.0:39539
```
Or if failed:
```cpp
LogVRM4UCapture: Warning: VMC: FAILED to create OSC server '0.0.0.0' on port 39539...
```

**On Packet Reception (every 100th packet to avoid spam):**
```cpp
LogVRM4UCapture: VMC: Received packet #101 from 127.0.0.1:12345 - Bones: 56, Curves: 52, Has Root: Yes
```

**Root Translation Hint (every ~5 seconds):**
```cpp
LogVRM4UCapture: Display: VMC AnimNode: Root translation data is being received and processed. 
If character is not moving, check Skeleton's Root Bone Translation Retargeting mode...
```

**Empty Data Warning:**
```cpp
LogVRM4UCapture: Warning: VMC AnimNode: Packets are being received (count: 150) but no bone/curve data is parsed...
```

### 4. Documentation

**New Files Created:**

#### `VMC_TROUBLESHOOTING.md` (250 lines)
Comprehensive guide covering:
- Quick setup steps
- Issue #551: Character cannot move (root bone retargeting)
  - Step-by-step fix with exact UI navigation
  - Why it happens
  - Where to find the setting
- Issue #552: No VMC data received
  - Port mismatch troubleshooting
  - Network/firewall checklist
  - Bind address configuration
- Debugging tools section
  - How to enable `vrm4u.VMC.Debug`
  - Log interpretation guide
- Technical details (protocol, ports, parameters)
- Troubleshooting checklist
- FAQ

#### `VMC_TEST_PLAN.md` (272 lines)
Manual test plan for verification:
- 9 test cases covering all diagnostic features
- Regression tests for existing functionality
- Performance verification steps
- Test scenarios for both reported issues

#### Updated Files:
- `TROUBLESHOOTING.md` - Added VMC section with link to comprehensive guide
- `README.md` (Japanese) - Added troubleshooting section with VMC link
- `README_en.md` (English) - Enhanced troubleshooting section

## Code Quality & Safety

### Performance
- **Zero impact when disabled:** All debug logging is gated by console variable check
- **Minimal impact when enabled:** Logs are throttled (every 100th packet, every 300 frames)
- Diagnostic tracking uses simple counters and flags

### Thread Safety
- Uses existing critical section locks in VrmVMCObject
- Console variable accessed via `GetValueOnAnyThread()` (thread-safe)
- No new threading issues introduced

### Backward Compatibility
- All changes are additive (no breaking changes)
- Default behavior unchanged (debug off by default)
- Existing VMC functionality untouched

### Code Style
- Follows existing VRM4U code patterns
- Uses existing log category (LogVRM4UCapture)
- Consistent with UE4/UE5 coding standards

## Testing Recommendations

### Manual Tests Required:
1. **Console variable registration** - Verify `vrm4u.VMC.Debug` command works
2. **Server creation logging** - Verify logs appear on VMC AnimNode init
3. **Packet reception** - Verify packet count and data logged correctly
4. **Port conflict** - Verify clear error when port in use
5. **Root translation detection** - Verify "Has Root: Yes/No" is accurate
6. **Root retargeting issue** - Reproduce Issue #551 and verify fix
7. **No data received** - Verify diagnostics help identify Issue #552
8. **Documentation** - Verify guides are clear and complete

### Regression Tests:
- VMC bone transforms still apply correctly
- VMC blend shapes still apply correctly
- Multiple VMC ports still work
- Perfect Sync mode still works
- Sample maps still function

## Files Changed Summary

```
Source/VRM4UCapture/Private/AnimNode_VrmVMC.cpp    |  42 additions
Source/VRM4UCapture/Private/VRM4UCapture.cpp       |  10 additions
Source/VRM4UCapture/Private/VRM4U_VMCSubsystem.cpp |  20 additions
Source/VRM4UCapture/Private/VrmVMCObject.cpp       |  39 additions
Source/VRM4UCapture/Public/VrmVMCObject.h          |  15 additions
TROUBLESHOOTING.md                                 |  25 additions
VMC_TEST_PLAN.md                                   | 272 new file
VMC_TROUBLESHOOTING.md                             | 250 new file
README.md                                          |   3 additions
README_en.md                                       |   2 additions

Total: 10 files changed, 673 insertions(+), 5 deletions(-)
```

## User Impact

### For Users Experiencing Issue #551 (Root Locked):
1. Enable debug: `vrm4u.VMC.Debug 1`
2. See log: "Root translation data is being received..."
3. Follow VMC_TROUBLESHOOTING.md → Issue 1
4. Fix: Set root bone translation retargeting to "Skeleton"
5. Problem resolved

### For Users Experiencing Issue #552 (No Data):
1. Enable debug: `vrm4u.VMC.Debug 1`
2. Check logs:
   - "FAILED to create OSC server" → Port conflict
   - No "Received packet" logs → Network/firewall issue
   - "Bones: 0, Curves: 0" → Protocol mismatch
3. Follow VMC_TROUBLESHOOTING.md → Issue 2
4. Work through checklist
5. Problem identified and resolved

### For All Users:
- Clear, searchable documentation
- Self-service troubleshooting
- Reduced "VMC is broken" support requests
- Better understanding of VMC requirements

## Future Enhancements (Out of Scope)

Potential future improvements (not implemented):
- On-screen debug overlay (optional HUD display)
- Blueprint-accessible diagnostic queries
- Automated skeleton retargeting check on import
- VMC sender test utility
- Unit tests for VMC protocol parsing

## References

- GitHub Issue #551: https://github.com/ruyo/VRM4U/issues/551
- GitHub Issue #552: https://github.com/ruyo/VRM4U/issues/552
- VMC Protocol: (see sender app documentation)
- Unreal Engine Skeleton Retargeting: UE documentation

## Conclusion

This implementation provides users with the tools and documentation needed to self-diagnose and fix the two most common VMC issues. The diagnostics are lightweight, opt-in, and follow UE best practices. The documentation is comprehensive and actionable.

**Status:** ✅ Ready for review and merge
