# VMC Diagnostics Manual Test Plan

This document outlines manual testing steps to verify the VMC diagnostics and troubleshooting improvements.

## Test Environment Setup

**Prerequisites:**
- Unreal Engine 5.x with VRM4U plugin installed
- A VMC sender application (e.g., VSeeFace, VMC Protocol test tool, or similar)
- VRM model imported into the project

## Test Cases

### Test 1: Console Variable Registration

**Objective:** Verify the debug console variable is registered and functional.

**Steps:**
1. Launch Unreal Editor with VRM4U plugin
2. Open Output Log (Window → Developer Tools → Output Log)
3. Open Console (press `` ` `` or `~`)
4. Type: `vrm4u.VMC.Debug`
5. Press Enter

**Expected Result:**
- Console should display current value (0 = disabled by default)
- No error messages

**Pass Criteria:** ✅ Console variable exists and shows current value

---

### Test 2: VMC Server Creation Logging

**Objective:** Verify diagnostic logging when VMC server is created.

**Steps:**
1. Enable debug mode: Type `vrm4u.VMC.Debug 1` in console
2. Open (or create) an Animation Blueprint with VMC node
3. Set Port to 39539, Server Address to "0.0.0.0"
4. Start PIE (Play In Editor)
5. Check Output Log

**Expected Result (Debug Enabled):**
```
LogVRM4UCapture: VMC: Successfully created OSC server '0.0.0.0' on port 39539
LogVRM4UCapture: VMC AnimNode: Initialized VMC receiver on 0.0.0.0:39539
LogVRM4UCapture: VMC Subsystem: VMC server created/found for 0.0.0.0:39539
```

**Expected Result (Debug Disabled):**
- Minimal or no VMC-related logging

**Pass Criteria:** ✅ Debug logs appear when enabled, minimal logs when disabled

---

### Test 3: Packet Reception Logging

**Objective:** Verify packet reception is logged with diagnostic information.

**Steps:**
1. Enable debug mode: `vrm4u.VMC.Debug 1`
2. Set up VMC AnimNode in Animation Blueprint (port 39539)
3. Start PIE
4. Start VMC sender application targeting 127.0.0.1:39539
5. Let it run for ~5 seconds
6. Check Output Log

**Expected Result:**
```
LogVRM4UCapture: VMC: Received packet #1 from 127.0.0.1:XXXXX - Bones: XX, Curves: XX, Has Root: Yes
LogVRM4UCapture: VMC: Received packet #101 from 127.0.0.1:XXXXX - Bones: XX, Curves: XX, Has Root: Yes
...
```
(Logs every 100th packet to avoid spam)

**Pass Criteria:** 
- ✅ Packet reception is logged
- ✅ Bone count, curve count, and root status are displayed
- ✅ Logging frequency is reasonable (every 100 packets)

---

### Test 4: No Packet Reception Warning

**Objective:** Verify clear messaging when VMC is configured but no packets arrive.

**Steps:**
1. Enable debug mode: `vrm4u.VMC.Debug 1`
2. Set up VMC AnimNode (port 39539)
3. Start PIE
4. Do NOT start any VMC sender
5. Wait 10 seconds
6. Check Output Log

**Expected Result:**
- Server creation logs appear
- No "received packet" logs (as expected)
- Clear indication that server is listening but not receiving data

**Pass Criteria:** ✅ Logs make it clear the server is listening but receiving no data

---

### Test 5: Port Conflict Detection

**Objective:** Verify clear error messaging when port is already in use.

**Steps:**
1. Enable debug mode: `vrm4u.VMC.Debug 1`
2. Manually occupy port 39539 with another application (e.g., another VMC receiver)
3. Set up VMC AnimNode (port 39539)
4. Start PIE
5. Check Output Log

**Expected Result:**
```
LogVRM4UCapture: Warning: VMC: FAILED to create OSC server '0.0.0.0' on port 39539. 
Check if port is already in use or blocked by firewall.
```

**Pass Criteria:** ✅ Clear warning message about port creation failure

---

### Test 6: Root Translation Detection

**Objective:** Verify logging indicates when root translation is received.

**Steps:**
1. Enable debug mode: `vrm4u.VMC.Debug 1`
2. Set up VMC with `bUseRemoteCenterPos = true`
3. Start VMC sender that transmits root/center position
4. Start PIE and let run for ~5 seconds
5. Check Output Log

**Expected Result:**
- Packet logs show `Has Root: Yes`
- Periodic message: 
  ```
  LogVRM4UCapture: Display: VMC AnimNode: Root translation data is being received and processed. 
  If character is not moving, check Skeleton's Root Bone Translation Retargeting mode...
  ```

**Pass Criteria:** 
- ✅ Root translation presence is detected
- ✅ Helpful reminder about skeleton retargeting appears

---

### Test 7: Root Bone Retargeting Issue Detection

**Objective:** Document the behavior when root translation is received but retargeting blocks it.

**Setup:**
1. Import VRM model
2. Open Skeleton asset
3. Set Root bone translation retargeting to "Animation" (incorrect setting)
4. Set up VMC AnimNode with debug enabled
5. Start VMC sender with root translation
6. Start PIE

**Expected Behavior:**
- Rotations apply correctly
- Character does NOT move (translation blocked)
- Debug log mentions root translation is present
- Console message hints at retargeting mode

**Fix Verification:**
1. Stop PIE
2. Change Root bone translation retargeting to "Skeleton"
3. Restart PIE

**Expected After Fix:**
- Character moves correctly with incoming root translation

**Pass Criteria:** 
- ✅ Issue is reproducible
- ✅ Debug logs help identify the problem
- ✅ Fix resolves the issue

---

### Test 8: Documentation Validation

**Objective:** Verify documentation is clear and helpful.

**Steps:**
1. Read `VMC_TROUBLESHOOTING.md`
2. Verify it covers:
   - [ ] Quick setup instructions
   - [ ] Root bone retargeting issue and fix
   - [ ] Network/port troubleshooting
   - [ ] Console variable usage
   - [ ] Debug log interpretation
   - [ ] FAQ section

**Pass Criteria:** 
- ✅ Documentation is clear and comprehensive
- ✅ Screenshots or specific UI paths are provided
- ✅ Common issues have actionable solutions

---

### Test 9: Default Configuration (No Debug)

**Objective:** Verify normal operation without debug mode.

**Steps:**
1. Ensure debug is disabled: `vrm4u.VMC.Debug 0`
2. Set up VMC AnimNode
3. Start VMC sender
4. Start PIE

**Expected Result:**
- Character animates correctly
- Minimal VMC logging (only warnings/errors if any)
- No performance impact from excessive logging

**Pass Criteria:** 
- ✅ VMC works correctly
- ✅ Logs are minimal and non-intrusive

---

## Regression Tests

### Existing Functionality

Verify that the changes don't break existing VMC functionality:

- [ ] VMC bone transforms apply correctly
- [ ] VMC blend shapes/morphs apply correctly
- [ ] Multiple VMC ports can be used simultaneously
- [ ] Perfect Sync mode still works
- [ ] Sample map `VRM4U_sample.umap` still works

---

## Performance Check

**Objective:** Ensure diagnostic code doesn't impact performance when disabled.

**Steps:**
1. Profile frame time with debug disabled
2. Profile frame time with debug enabled
3. Compare

**Pass Criteria:** 
- ✅ No measurable performance impact when debug is disabled
- ✅ Acceptable impact when debug is enabled (logging is known to have cost)

---

## Summary

**Total Test Cases:** 9  
**Manual Tests Required:** All tests require manual verification  
**Automated Tests:** None (would require VMC sender automation)

**Recommendation:** 
- All tests should pass before merging
- Test with at least one real VMC sender application
- Verify on both Windows and Mac if possible
- Test in both Editor (PIE) and packaged builds

---

**Test Plan Version:** 1.0  
**Date:** January 2026  
**Related Issues:** #551, #552
