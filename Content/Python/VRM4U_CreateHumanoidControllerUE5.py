# coding: utf-8
import unreal
import argparse
import re

print("VRM4U python begin")
print (__file__)

parser = argparse.ArgumentParser()
parser.add_argument("-vrm")
parser.add_argument("-rig")
parser.add_argument("-meta")
args = parser.parse_args()
print(args.vrm)

#print(dummy[3])

humanoidBoneList = [
	"hips",
	"leftUpperLeg",
	"rightUpperLeg",
	"leftLowerLeg",
	"rightLowerLeg",
	"leftFoot",
	"rightFoot",
	"spine",
	"chest",
	"upperChest", # 9 optional
	"neck",
	"head",
	"leftShoulder",
	"rightShoulder",
	"leftUpperArm",
	"rightUpperArm",
	"leftLowerArm",
	"rightLowerArm",
	"leftHand",
	"rightHand",
	"leftToes",
	"rightToes",
	"leftEye",
	"rightEye",
	"jaw",
	"leftThumbProximal",	# 24
	"leftThumbIntermediate",
	"leftThumbDistal",
	"leftIndexProximal",
	"leftIndexIntermediate",
	"leftIndexDistal",
	"leftMiddleProximal",
	"leftMiddleIntermediate",
	"leftMiddleDistal",
	"leftRingProximal",
	"leftRingIntermediate",
	"leftRingDistal",
	"leftLittleProximal",
	"leftLittleIntermediate",
	"leftLittleDistal",
	"rightThumbProximal",
	"rightThumbIntermediate",
	"rightThumbDistal",
	"rightIndexProximal",
	"rightIndexIntermediate",
	"rightIndexDistal",
	"rightMiddleProximal",
	"rightMiddleIntermediate",
	"rightMiddleDistal",
	"rightRingProximal",
	"rightRingIntermediate",
	"rightRingDistal",
	"rightLittleProximal",
	"rightLittleIntermediate",
	"rightLittleDistal",	#54
]

humanoidBoneParentList = [
	"", #"hips",
	"hips",#"leftUpperLeg",
	"hips",#"rightUpperLeg",
	"leftUpperLeg",#"leftLowerLeg",
	"rightUpperLeg",#"rightLowerLeg",
	"leftLowerLeg",#"leftFoot",
	"rightLowerLeg",#"rightFoot",
	"hips",#"spine",
	"spine",#"chest",
	"chest",#"upperChest"	9 optional
	"chest",#"neck",
	"neck",#"head",
	"chest",#"leftShoulder",			# <-- upper..
	"chest",#"rightShoulder",
	"leftShoulder",#"leftUpperArm",
	"rightShoulder",#"rightUpperArm",
	"leftUpperArm",#"leftLowerArm",
	"rightUpperArm",#"rightLowerArm",
	"leftLowerArm",#"leftHand",
	"rightLowerArm",#"rightHand",
	"leftFoot",#"leftToes",
	"rightFoot",#"rightToes",
	"head",#"leftEye",
	"head",#"rightEye",
	"head",#"jaw",
	"leftHand",#"leftThumbProximal",
	"leftThumbProximal",#"leftThumbIntermediate",
	"leftThumbIntermediate",#"leftThumbDistal",
	"leftHand",#"leftIndexProximal",
	"leftIndexProximal",#"leftIndexIntermediate",
	"leftIndexIntermediate",#"leftIndexDistal",
	"leftHand",#"leftMiddleProximal",
	"leftMiddleProximal",#"leftMiddleIntermediate",
	"leftMiddleIntermediate",#"leftMiddleDistal",
	"leftHand",#"leftRingProximal",
	"leftRingProximal",#"leftRingIntermediate",
	"leftRingIntermediate",#"leftRingDistal",
	"leftHand",#"leftLittleProximal",
	"leftLittleProximal",#"leftLittleIntermediate",
	"leftLittleIntermediate",#"leftLittleDistal",
	"rightHand",#"rightThumbProximal",
	"rightThumbProximal",#"rightThumbIntermediate",
	"rightThumbIntermediate",#"rightThumbDistal",
	"rightHand",#"rightIndexProximal",
	"rightIndexProximal",#"rightIndexIntermediate",
	"rightIndexIntermediate",#"rightIndexDistal",
	"rightHand",#"rightMiddleProximal",
	"rightMiddleProximal",#"rightMiddleIntermediate",
	"rightMiddleIntermediate",#"rightMiddleDistal",
	"rightHand",#"rightRingProximal",
	"rightRingProximal",#"rightRingIntermediate",
	"rightRingIntermediate",#"rightRingDistal",
	"rightHand",#"rightLittleProximal",
	"rightLittleProximal",#"rightLittleIntermediate",
	"rightLittleIntermediate",#"rightLittleDistal",
]

for i in range(len(humanoidBoneList)):
    humanoidBoneList[i] = humanoidBoneList[i].lower()

for i in range(len(humanoidBoneParentList)):
    humanoidBoneParentList[i] = humanoidBoneParentList[i].lower()

######

##

rigs = unreal.ControlRigBlueprint.get_currently_open_rig_blueprints()
print(rigs)

for r in rigs:
    s:str = r.get_path_name()
    ss:str = args.rig
    if (s.find(ss) < 0):
        print("no rig")
    else:
        rig = r


#rig = rigs[10]
hierarchy = unreal.ControlRigBlueprintLibrary.get_hierarchy(rig)

h_con = hierarchy.get_controller()

#elements = h_con.get_selection()
#sk = rig.get_preview_mesh()
#k = sk.skeleton
#print(k)

#print(sk.bone_tree)

#
#kk = unreal.RigElementKey(unreal.RigElementType.BONE, "hipssss");
#kk.name = ""
#kk.type = 1;

#print(h_con.get_bone(kk))

#print(h_con.get_elements())

### 全ての骨
modelBoneListAll = []
modelBoneNameList = []

for e in hierarchy.get_bones():
    if (e.type == unreal.RigElementType.BONE):
        modelBoneListAll.append(e)
        # Normalize bone name: lowercase and trim whitespace
        modelBoneNameList.append("{}".format(e.name).lower().strip())

print(modelBoneListAll[0])

#exit
#print(k.get_editor_property("bone_tree")[0].get_editor_property("translation_retargeting_mode"))
#print(k.get_editor_property("bone_tree")[0].get_editor_property("parent_index"))

#unreal.select

#vrmlist = unreal.VrmAssetListObject
#vrmmeta = vrmlist.vrm_meta_object
#print(vrmmeta.humanoid_bone_table)

#selected_actors = unreal.EditorLevelLibrary.get_selected_level_actors()
#selected_static_mesh_actors = unreal.EditorFilterLibrary.by_class(selected_actors,unreal.StaticMeshActor.static_class())

#static_meshes = np.array([])



## meta 取得
reg = unreal.AssetRegistryHelpers.get_asset_registry();
a = reg.get_all_assets();

if (args.meta):
    for aa in a:
        if (aa.get_editor_property("object_path") == args.meta):
            v:unreal.VrmMetaObject = aa
            vv = aa.get_asset()

if vv is None:
    for aa in a:
        if (aa.get_editor_property("object_path") == args.vrm):
            v:unreal.VrmAssetListObject = aa
            vv = v.get_asset().vrm_meta_object
print(vv)
meta = vv

print (meta)

### モデル骨のうち、ヒューマノイドと同じもの
### 上の変換テーブル
humanoidBoneToModel = {"" : ""}
humanoidBoneToModel.clear()

    
### modelBoneでループ
#for bone_h in meta.humanoid_bone_table:
for bone_h_base in humanoidBoneList:

    bone_h = None
    for e in meta.humanoid_bone_table:
        if ("{}".format(e).lower() == bone_h_base):
            bone_h = e;
            break;

    print("{}".format(bone_h))

    if bone_h is None:
        continue

    bone_m = meta.humanoid_bone_table[bone_h]
    
    # Trim whitespace and normalize bone name
    bone_m_normalized = "{}".format(bone_m).lower().strip()

    try:
        i = modelBoneNameList.index(bone_m_normalized)
    except ValueError:
        i = -1
    if (i < 0):
        continue
    if ("{}".format(bone_h).lower() == "upperchest"):
        continue;

    humanoidBoneToModel["{}".format(bone_h).lower()] = bone_m_normalized

    if ("{}".format(bone_h).lower() == "chest"):
        #upperchestがあれば、これの次に追加
        bh = 'upperchest'
        print("upperchest: check begin")
        for e in meta.humanoid_bone_table:
            if ("{}".format(e).lower() != 'upperchest'):
                continue

            bm = "{}".format(meta.humanoid_bone_table[e]).lower()
            if (bm == ''):
                continue

            humanoidBoneToModel[bh] = bm
            humanoidBoneParentList[10] = "upperchest"
            humanoidBoneParentList[12] = "upperchest"
            humanoidBoneParentList[13] = "upperchest"

            print("upperchest: find and insert parent")
            break
        print("upperchest: check end")


# Validate and fix thumb bone mapping for VRM 0.x models
# VRM 0.x has confusing naming: "Proximal" refers to metacarpal (first bone),
# while anatomically it should refer to the proximal phalange (second bone).
# This can cause controls to be mispositioned.
#
# Set FIX_THUMB_MAPPING_FOR_VRM0X = False to disable automatic fix
FIX_THUMB_MAPPING_FOR_VRM0X = True

print("Validating thumb bone mapping...")
print(f"Automatic thumb mapping fix: {'ENABLED' if FIX_THUMB_MAPPING_FOR_VRM0X else 'DISABLED'}")

for hand_side in ["left", "right"]:
    thumb_proximal_key = f"{hand_side}thumbproximal"
    thumb_intermediate_key = f"{hand_side}thumbintermediate"
    thumb_distal_key = f"{hand_side}thumbdistal"
    
    if thumb_proximal_key in humanoidBoneToModel and thumb_intermediate_key in humanoidBoneToModel and thumb_distal_key in humanoidBoneToModel:
        bone1 = humanoidBoneToModel[thumb_proximal_key]
        bone2 = humanoidBoneToModel[thumb_intermediate_key]
        bone3 = humanoidBoneToModel[thumb_distal_key]
        
        print(f"{hand_side.capitalize()} thumb mapping:")
        print(f"  Proximal -> {bone1}")
        print(f"  Intermediate -> {bone2}")
        print(f"  Distal -> {bone3}")
        
        # Apply fix if enabled
        if FIX_THUMB_MAPPING_FOR_VRM0X:
            # Check if bones follow VRoid naming pattern with numbers
            if "thumb" in bone1 and "thumb" in bone2:
                match1 = re.search(r'thumb[\D]*(\d+)', bone1)
                match2 = re.search(r'thumb[\D]*(\d+)', bone2)
                
                if match1 and match2:
                    num1 = int(match1.group(1))
                    num2 = int(match2.group(1))
                    
                    # Validate that extracted indices are within expected VRoid thumb range (1-3)
                    if not (1 <= num1 <= 3 and 1 <= num2 <= 3):
                        print(f"  ⚠ Thumb bone numbers outside expected range (1-3): Proximal→thumb{num1}, Intermediate→thumb{num2}. Skipping auto-fix.")
                    else:
                        # If Proximal is mapped to thumb2, shift everything down
                        if num1 == 2 and num2 == 3:
                            print(f"  ⚠ Detected off-by-one error: Proximal→thumb{num1}, Intermediate→thumb{num2}")
                            
                            # Look for thumb1 bone (ensure we don't match thumb11, thumb21, etc.)
                            thumb1_candidates = [b for b in modelBoneNameList if re.match(r'.*thumb[\D]*1(?:\D|$)', b, re.IGNORECASE)]
                            if thumb1_candidates:
                                # Prefer bones without suffix modifiers like "_twist" or "_helper"
                                simple_candidates = [b for b in thumb1_candidates if not any(suffix in b for suffix in ['_twist', '_helper', '_ik', '_fk'])]
                                thumb1_bone = simple_candidates[0] if simple_candidates else thumb1_candidates[0]
                                print(f"  ✓ Applying fix: Proximal→{thumb1_bone}, Intermediate→{bone1}, Distal→{bone2}")
                                humanoidBoneToModel[thumb_proximal_key] = thumb1_bone
                                humanoidBoneToModel[thumb_intermediate_key] = bone1
                                humanoidBoneToModel[thumb_distal_key] = bone2
                            else:
                                print(f"  ✗ Could not find thumb1 bone to apply fix")
                        elif num1 == 1 and num2 == 2:
                            print(f"  ✓ Thumb bone mapping appears correct (1, 2, 3 pattern detected)")

print("Thumb validation complete.")



parent=None
control_to_mat={None:None}

count = 0

### 骨名からControlへのテーブル
name_to_control = {"dummy_for_table" : None}

print("loop begin")

###### root
key = unreal.RigElementKey(unreal.RigElementType.NULL, 'root_s')
space = hierarchy.find_null(key)
if (space.get_editor_property('index') < 0):
    space = h_con.add_null('root_s', space_type=unreal.RigSpaceType.SPACE)
else:
    space = key

key = unreal.RigElementKey(unreal.RigElementType.CONTROL, 'root_c')
control = hierarchy.find_control(key)
if (control.get_editor_property('index') < 0):
    control = h_con.add_control('root_c',
        space_name=space.name,
        gizmo_color=[1.0, 0.0, 0.0, 1.0],
        )
else:
    control = key
    h_con.set_parent(control, space)
parent = control

setting = h_con.get_control_settings(control)
setting.shape_visible = False
h_con.set_control_settings(control, setting)


for ee in humanoidBoneToModel:

    element = humanoidBoneToModel[ee]
    humanoidBone = ee
    modelBoneNameSmall = element

	# 対象の骨
    #modelBoneNameSmall = "{}".format(element.name).lower()
    #humanoidBone = modelBoneToHumanoid[modelBoneNameSmall];
    boneNo = humanoidBoneList.index(humanoidBone)
    print("{}_{}_{}__parent={}".format(modelBoneNameSmall, humanoidBone, boneNo,humanoidBoneParentList[boneNo]))

	# 親
    if count != 0:
        parent = name_to_control[humanoidBoneParentList[boneNo]]

	# 階層作成
    bIsNew = False
    name_s = "{}_s".format(humanoidBone)
    key = unreal.RigElementKey(unreal.RigElementType.NULL, name_s)
    space = hierarchy.find_null(key)
    if (space.get_editor_property('index') < 0):
        space = h_con.add_space(name_s, space_type=unreal.RigSpaceType.SPACE)
        bIsNew = True
    else:
        space = key

    name_c = "{}_c".format(humanoidBone)
    key = unreal.RigElementKey(unreal.RigElementType.CONTROL, name_c)
    control = hierarchy.find_control(key)
    if (control.get_editor_property('index') < 0):
        control = h_con.add_control(name_c,
            space_name=space.name,
            gizmo_color=[1.0, 0.0, 0.0, 1.0],
            )
        #h_con.get_control(control).gizmo_transform = gizmo_trans
        if (24<=boneNo & boneNo<=53):
            gizmo_trans = unreal.Transform([0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.1, 0.1, 0.1])
        else:
            gizmo_trans = unreal.Transform([0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [1, 1, 1])

        if (17<=boneNo & boneNo<=18):
            gizmo_trans = unreal.Transform([0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [1, 1, 1])
        cc = h_con.get_control(control)
        cc.set_editor_property('gizmo_transform', gizmo_trans)
        cc.set_editor_property('control_type', unreal.RigControlType.ROTATOR)
        h_con.set_control(cc)
        #h_con.set_control_value_transform(control,gizmo_trans)
        bIsNew = True
    else:
        control = key
        if (bIsNew == True):
            h_con.set_parent(control, space)


    # テーブル登録
    name_to_control[humanoidBone] = control
    print(humanoidBone)


    # ロケータ 座標更新
    # 不要な上層階層を考慮
	
    # Get bone index with error handling
    try:
        boneIndex = modelBoneNameList.index(modelBoneNameSmall)
    except ValueError:
        print(f"ERROR: Bone '{modelBoneNameSmall}' not found in skeleton hierarchy!")
        print(f"Available bones: {modelBoneNameList[:10]}...")  # Print first 10 for debugging
        continue
    
    gTransform = hierarchy.get_global_transform(modelBoneListAll[boneIndex])
    
    # Debug logging for thumb bones to help diagnose issues
    if "thumb" in humanoidBone.lower():
        print(f"Thumb bone: {humanoidBone} -> model bone: {modelBoneNameSmall} (index: {boneIndex})")
        print(f"  Transform location: {gTransform.translation}")
    
    if count == 0:
        bone_initial_transform = gTransform
    else:
        #bone_initial_transform = h_con.get_initial_transform(element)
        bone_initial_transform = gTransform.multiply(control_to_mat[parent].inverse())

    hierarchy.set_global_transform(space, gTransform, True)


    control_to_mat[control] = gTransform

    # 階層修正
    h_con.set_parent(space, parent)
    
    count += 1
    if (count >= 500):
        break
