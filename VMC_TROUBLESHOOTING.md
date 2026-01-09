# VMC Setup & Troubleshooting Guide

This guide helps you set up and troubleshoot VMC (Virtual Motion Capture) protocol reception in VRM4U.

## Table of Contents
- [Quick Setup](#quick-setup)
- [Common Issues](#common-issues)
- [Debugging Tools](#debugging-tools)
- [Technical Details](#technical-details)

---

## Quick Setup

### Prerequisites
- VRM4U plugin installed and enabled
- A VMC-compatible sender application (e.g., VSeeFace, VMC Protocol, etc.)

### Basic Setup Steps

1. **Import your VRM model** into Unreal Engine using VRM4U
2. **Open the sample map**: `VRM4UContent/Maps/VRM4U_sample.umap` or create your own
3. **Add VMC Animation Node** to your Animation Blueprint:
   - Open (or create) an Animation Blueprint for your VRM character
   - Add the "Vrm VMC" node (found under "VRM4U" category)
   - Set the `Port` (default: 39539) to match your VMC sender
   - Set the `Server Address` (default: "0.0.0.0" listens on all interfaces)
4. **Configure your VMC sender**:
   - Set sender's target IP to your machine's IP (127.0.0.1 for local)
   - Set sender's target port to match the port in step 3 (default: 39539)
5. **Start sending VMC data** from your sender application

---

## Common Issues

### Issue 1: Character Cannot Move / Root Position Locked

**Symptoms:**
- VMC data is being received (rotations work)
- Character's body moves/rotates correctly
- But character stays locked in place (no translation/movement)

**Root Cause:**
The skeleton's root bone translation retargeting mode is set incorrectly.

**Solution:**

1. Navigate to your VRM character's **Skeleton** asset in the Content Browser
2. Double-click to open the Skeleton Editor
3. In the **Skeleton Tree** panel (usually on the right), find the **Root** bone (topmost bone)
4. Right-click the Root bone → **Bone Translation Retargeting** → Select **"Skeleton"**
   - ❌ **NOT** "Animation" (this blocks translation)
   - ✅ **USE** "Skeleton" (allows translation through)

**Where to find this setting:**
```
Content Browser → Your VRM Skeleton Asset → Double-click
  └─ Skeleton Tree panel → Right-click Root bone
      └─ Bone Translation Retargeting → Skeleton
```

**Why this happens:**
By default, Unreal sets bone translation retargeting to "Animation" mode, which ignores incoming translation data from sources like VMC. Setting it to "Skeleton" allows the translation to be applied.

---

### Issue 2: No VMC Data Received (Even Sample Map)

**Symptoms:**
- Character doesn't respond to VMC at all
- No movement, no rotation updates
- Sample map also doesn't work

**Possible Causes & Solutions:**

#### A. Port Mismatch
- **Check:** VMC sender's target port must match your AnimNode's `Port` setting
- **Default:** 39539 (but verify both sides match)
- **Fix:** Update either the sender or the AnimNode to use the same port

#### B. Wrong IP Address / Bind Address
- **Check:** Sender's target IP must point to the correct machine
  - For local testing: use `127.0.0.1` or `localhost`
  - For network: use your machine's actual IP address
- **AnimNode Address:** 
  - `0.0.0.0` = listen on all network interfaces (recommended)
  - Specific IP = listen only on that interface

#### C. Firewall Blocking UDP Traffic
- VMC uses UDP protocol on the specified port
- **Windows Firewall:**
  1. Open "Windows Defender Firewall with Advanced Security"
  2. Create new Inbound Rule for UDP port (e.g., 39539)
  3. Allow the connection
- **Third-party firewalls:** Add exception for Unreal Editor and your port

#### D. Port Already in Use
- Another application might be using the same port
- **Fix:** 
  - Close other applications using that port, OR
  - Change the port number in both sender and receiver

#### E. Network Interface Issues
- If using multiple network adapters, ensure sender targets the correct one
- Try setting AnimNode `ServerAddress` to a specific local IP instead of `0.0.0.0`

---

### Issue 3: VMC Works in Other Apps (VSeeFace, Warudo) But Not VRM4U

This usually indicates either:
- **Port/Address mismatch** (see Issue 2 above)
- **Root bone retargeting** (see Issue 1 above)
- Different default ports: verify your sender's port matches VRM4U's AnimNode port

---

## Debugging Tools

### Enable VMC Debug Logging

VRM4U includes a console variable for detailed VMC diagnostics.

**How to Enable:**

1. **In Editor:** Open the Output Log window (Window → Developer Tools → Output Log)
2. **Open Console:** Press the backtick key (\`) or tilde (~) to open the console command line
3. **Enable Debug Mode:** Type:
   ```
   vrm4u.VMC.Debug 1
   ```
4. **To Disable Later:** Type:
   ```
   vrm4u.VMC.Debug 0
   ```

**What Gets Logged:**

When enabled, you'll see messages like:

```
LogVRM4UCapture: VMC: Successfully created OSC server '0.0.0.0' on port 39539
LogVRM4UCapture: VMC AnimNode: Initialized VMC receiver on 0.0.0.0:39539
LogVRM4UCapture: VMC: Received packet #1 from 127.0.0.1:39539 - Bones: 56, Curves: 52, Has Root: Yes
LogVRM4UCapture: VMC AnimNode: Root translation data is being received and processed...
```

**Interpreting the Output:**

- ✅ `Successfully created OSC server` → Server is listening correctly
- ❌ `FAILED to create OSC server` → Port conflict or permission issue
- ✅ `Received packet #X` → Data is arriving
- ❌ No "Received packet" messages → Check sender, firewall, port, IP
- ⚠️ `Bones: 0, Curves: 0` → Packets received but data not parsed (protocol mismatch?)
- ℹ️ `Has Root: Yes` → Root translation data is present

---

## Technical Details

### VMC Protocol Addresses

VRM4U listens for these OSC addresses:

| Address | Purpose |
|---------|---------|
| `/VMC/Ext/Root/Pos` | Root position (translation) |
| `/VMC/Ext/Bone/Pos` | Individual bone transforms |
| `/VMC/Ext/Blend/Val` | BlendShape/MorphTarget values |
| `/VMC/Ext/OK` | Frame sync marker |
| `/VMC/Ext/T` | Time sync marker |
| `/VMC/Ext/Blend/Apply` | Apply accumulated blend shapes |

### Default Configuration

| Setting | Default Value | Notes |
|---------|---------------|-------|
| Port | 39539 | Standard VMC protocol port |
| Server Address | 0.0.0.0 | Listen on all network interfaces |
| Protocol | UDP | VMC uses OSC over UDP |

### AnimNode Parameters

- **`bUseRemoteCenterPos`** (default: `true`): Apply incoming root position from sender
- **`ModelRelativeScale`** (default: `1.0`): Scale factor for incoming positions
- **`bIgnoreLocalRotation`** (default: `false`): Ignore local bone rotations
- **`bApplyPerfectSync`** (default: `true`): Support PerfectSync BlendShape format

---

## Checklist for "VMC Not Working"

When VMC doesn't work, check these in order:

- [ ] **Port numbers match** between sender and receiver
- [ ] **Sender target IP** points to correct machine (127.0.0.1 for local)
- [ ] **Firewall allows UDP** traffic on the VMC port
- [ ] **No port conflicts** (no other app using the same port)
- [ ] **AnimNode is active** in your Animation Blueprint
- [ ] **Enable `vrm4u.VMC.Debug 1`** and check Output Log for diagnostics
- [ ] **Root bone translation retargeting** set to "Skeleton" (for movement issues)

---

## Frequently Asked Questions

**Q: What port should I use?**  
A: Default is 39539. Use any free port, but make sure sender and receiver match.

**Q: Can I receive from multiple senders simultaneously?**  
A: Yes, use different ports for each sender and add multiple VMC AnimNodes.

**Q: Does VMC work in packaged builds?**  
A: Yes, VMC works in Development and Shipping builds. Debug logging requires Development builds.

**Q: Why does the character T-pose or snap back?**  
A: This usually means sender stopped transmitting or a frame sync issue. Check sender is running and transmitting continuously.

**Q: Can I record VMC data with Take Recorder?**  
A: Yes, VMC blend shapes and bone transforms can be recorded with Unreal's Take Recorder system (UE 4.27+).

---

## Additional Resources

- **VRM4U Main Documentation:** [https://ruyo.github.io/VRM4U/](https://ruyo.github.io/VRM4U/)
- **VMC Protocol Specification:** Check your VMC sender's documentation
- **Sample Map:** `VRM4UContent/Maps/VRM4U_sample.umap`

---

## Reporting Issues

If VMC still doesn't work after following this guide:

1. Enable `vrm4u.VMC.Debug 1` and capture Output Log
2. Note your Unreal Engine version
3. Note your VRM4U plugin version
4. Include:
   - VMC sender app name and version
   - Port and IP settings (sender & receiver)
   - Firewall status
   - Any error messages from Output Log
5. Create an issue on GitHub: [https://github.com/ruyo/VRM4U/issues](https://github.com/ruyo/VRM4U/issues)

---

**Last Updated:** January 2026  
**Addresses GitHub Issues:** #551, #552
