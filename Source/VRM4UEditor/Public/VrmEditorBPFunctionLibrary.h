// VRM4U Copyright (c) 2021-2024 Haruyoshi Yamamoto. This software is released under the MIT License.

#pragma once
#include "Kismet/BlueprintFunctionLibrary.h"
#include "Engine/EngineTypes.h"
#include "Engine/TextureRenderTarget2D.h"
#include "Misc/EngineVersionComparison.h"

#include "VrmEditorBPFunctionLibrary.generated.h"

class UTextureRenderTarget2D;
class UMaterialInstanceConstant;
class UAnimationAsset;
class USkeleton;

/**
 * 
 */
UCLASS()
class VRM4UEDITOR_API UVrmEditorBPFunctionLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()
	
public:

	//UFUNCTION(BlueprintCallable,Category="VRM4U", meta = (DevelopmentOnly))
	//static bool VRMBakeAnim(const USkeletalMeshComponent *skc, const FString &FilePath, const FString &AssetFileName);


	//UFUNCTION(BlueprintCallable,Category="VRM4U")
	//static void VRMTransMatrix(const FTransform &transform, TArray<FLinearColor> &matrix, TArray<FLinearColor> &matrix_inv);

	//UFUNCTION(BlueprintPure, Category = "VRM4U")
	//static void VRMGetMorphTargetList(const USkeletalMesh *target, TArray<FString> &morphTargetList);


	UFUNCTION(BlueprintCallable, Category = "VRM4U")
	static int EvaluateCurvesFromSequence(const UMovieSceneSequence* Seq, float FrameNo, TArray<FString>& names, TArray<float>& curves);

	/**
	 * Fix IK Rig for UE5.7+ retargeting compatibility.
	 * Updates IK goals from toe-based (UE5.6) to foot-based (UE5.7+) configuration.
	 * This function is useful for migrating existing VRM assets imported in UE5.6 to work correctly in UE5.7+.
	 * 
	 * @param IKRigAsset The IK Rig asset to fix (typically named IK_*_Mannequin)
	 * @return true if the fix was applied successfully, false otherwise
	 */
	UFUNCTION(BlueprintCallable, Category = "VRM4U", meta = (DevelopmentOnly))
	static bool FixIKRigForUE57Retargeting(class UIKRigDefinition* IKRigAsset);
};
