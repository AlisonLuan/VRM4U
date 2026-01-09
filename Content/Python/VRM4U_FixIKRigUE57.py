"""
VRM4U UE5.7 IK Rig Migration Script

This script helps migrate VRM IK Rig assets from UE5.6 (toe-based goals) 
to UE5.7+ (foot-based goals) configuration.

Usage:
    1. Open your UE5.7+ project in Unreal Editor
    2. Enable Python scripting: Edit > Plugins > Search for "Python Editor Script Plugin"
    3. Open Python console: Tools > Execute Python Script
    4. Run this script or import it:
       
       import unreal
       # Load and run this script
       unreal.PythonScriptLibrary.execute_python_command_ex(
           r"exec(open(r'PATH_TO_THIS_SCRIPT/VRM4U_FixIKRigUE57.py').read())",
           unreal.ExecutionMode.EXECUTE_FILE
       )

Requirements:
    - Unreal Engine 5.7 or later
    - VRM4U plugin with UE5.7 fix installed
"""

import unreal

def find_vrm_ik_rigs():
    """Find all VRM IK Rig assets in the project."""
    asset_registry = unreal.AssetRegistryHelpers.get_asset_registry()
    
    # Find all IKRigDefinition assets
    ik_rig_class = unreal.IKRigDefinition
    filter_data = unreal.ARFilter(
        class_names=[ik_rig_class.get_class().get_name()],
        recursive_paths=True
    )
    
    all_ik_rigs = asset_registry.get_assets(filter_data)
    
    # Filter to VRM-related IK Rigs (typically named IK_*_Mannequin)
    vrm_ik_rigs = []
    for asset_data in all_ik_rigs:
        asset_name = asset_data.asset_name
        if "Mannequin" in asset_name or "VRM" in asset_name or "IK_" in asset_name:
            vrm_ik_rigs.append(asset_data)
    
    return vrm_ik_rigs

def fix_ik_rig(ik_rig_asset):
    """
    Fix a single IK Rig asset for UE5.7 compatibility.
    
    Args:
        ik_rig_asset: The UIKRigDefinition asset to fix
        
    Returns:
        True if successful, False otherwise
    """
    try:
        success = unreal.VrmEditorBPFunctionLibrary.fix_ik_rig_for_ue57_retargeting(ik_rig_asset)
        return success
    except Exception as e:
        unreal.log_error(f"Error fixing IK Rig: {e}")
        return False

def main():
    """Main migration function."""
    unreal.log("=" * 80)
    unreal.log("VRM4U UE5.7 IK Rig Migration Tool")
    unreal.log("=" * 80)
    
    # Find VRM IK Rigs
    unreal.log("\nSearching for VRM IK Rig assets...")
    vrm_ik_rigs = find_vrm_ik_rigs()
    
    if not vrm_ik_rigs:
        unreal.log_warning("No VRM IK Rig assets found in project.")
        return
    
    unreal.log(f"Found {len(vrm_ik_rigs)} potential VRM IK Rig asset(s):")
    for asset_data in vrm_ik_rigs:
        unreal.log(f"  - {asset_data.package_name}")
    
    # Interactive confirmation
    # Note: UE Python doesn't have built-in UI dialogs. In production, you might:
    # 1. Use an Editor Utility Widget to show a proper confirmation dialog
    # 2. Require a command-line flag/argument to proceed
    # 3. Have users modify this variable before running the script
    
    # For safety, default to False - users must explicitly enable auto-processing
    # CHANGE THIS TO True TO ENABLE AUTOMATIC MIGRATION:
    auto_confirm = False
    
    if not auto_confirm:
        unreal.log("\n" + "!" * 80)
        unreal.log("WARNING: This script will modify IK Rig assets in your project!")
        unreal.log("Please ensure you have a backup before proceeding.")
        unreal.log("")
        unreal.log("To proceed:")
        unreal.log("  1. Edit this script and set 'auto_confirm = True' (line 93), then run again, OR")
        unreal.log("  2. Call this script with confirmation handled by an Editor Utility Widget")
        unreal.log("!" * 80)
        unreal.log("\nMigration cancelled - auto_confirm is False.")
        return
    
    # If we reach here, auto_confirm is True
    unreal.log("\nAuto-confirm enabled - proceeding with migration...")
    
    # Process each IK Rig
    unreal.log("\nProcessing IK Rigs...")
    success_count = 0
    skip_count = 0
    error_count = 0
    
    for asset_data in vrm_ik_rigs:
        asset_path = str(asset_data.package_name)
        unreal.log(f"\nProcessing: {asset_path}")
        
        # Load the asset
        ik_rig = unreal.load_asset(asset_path)
        if not ik_rig:
            unreal.log_error(f"  Failed to load asset: {asset_path}")
            error_count += 1
            continue
        
        # Fix the IK Rig
        if fix_ik_rig(ik_rig):
            unreal.log(f"  ✓ Successfully updated: {asset_data.asset_name}")
            
            # Save the asset
            if unreal.EditorAssetLibrary.save_loaded_asset(ik_rig):
                unreal.log(f"  ✓ Saved: {asset_data.asset_name}")
                success_count += 1
            else:
                unreal.log_warning(f"  ⚠ Updated but failed to save: {asset_data.asset_name}")
        else:
            unreal.log_warning(f"  ⚠ Skipped (already UE5.7+ or no changes needed): {asset_data.asset_name}")
            skip_count += 1
    
    # Summary
    unreal.log("\n" + "=" * 80)
    unreal.log("Migration Summary:")
    unreal.log(f"  Successfully updated: {success_count}")
    unreal.log(f"  Skipped (no changes needed): {skip_count}")
    unreal.log(f"  Errors: {error_count}")
    unreal.log("=" * 80)
    
    if success_count > 0:
        unreal.log("\n✓ Migration complete! Your IK Rigs are now configured for UE5.7+")
        unreal.log("  Don't forget to also update any retargeter assets (RTG_*) that reference these IK Rigs.")
    elif skip_count > 0 and error_count == 0:
        unreal.log("\nℹ All IK Rigs are already configured for UE5.7+ or don't need migration.")
    else:
        unreal.log_warning("\n⚠ Some errors occurred during migration. Check the log for details.")

if __name__ == "__main__":
    main()
