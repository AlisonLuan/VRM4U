// VRM4U Copyright (c) 2021-2024 Haruyoshi Yamamoto. This software is released under the MIT License.

#include "VrmEditorBPFunctionLibrary.h"

#include "Engine/Engine.h"
#include "Logging/MessageLog.h"
#include "Engine/Canvas.h"
#if	UE_VERSION_OLDER_THAN(4,26,0)
#include "AssetRegistryModule.h"
#else
#include "AssetRegistry/AssetRegistryModule.h"
#endif

#include "MovieScene.h"
#include "MovieSceneSequence.h"
#include "Sections/MovieSceneFloatSection.h"

// IK Rig includes for UE5+ (use centralized version-aware header)
#if !UE_VERSION_OLDER_THAN(5,0,0)
#include "VrmRigHeader.h"
#endif

//#include "VRM4U.h"

//OnGlobalTimeChanged

int UVrmEditorBPFunctionLibrary::EvaluateCurvesFromSequence(const UMovieSceneSequence* Seq, float FrameNo, TArray<FString>& names, TArray<float> &curves) {
    names.Empty();
    curves.Empty();

#if	UE_VERSION_OLDER_THAN(4,26,0)
    return 0;
#else

    //if (Track == nullptr) return 0;

    if (Seq == nullptr) return 0;
    if (Seq->GetMovieScene() == nullptr) return 0;

    TArray<UMovieSceneSection*> Sections = Seq->GetMovieScene()->GetAllSections();
    //const auto &Sections = Track->GetAllSections();
    for (UMovieSceneSection* Section : Sections){
        UMovieSceneFloatSection* FloatSection = Cast<UMovieSceneFloatSection>(Section);
        //UMovieSceneControlRigParameterSection* s = Cast<UMovieSceneControlRigParameterSection>(Section);

        if (FloatSection == nullptr) {
            continue;
        }
        const FMovieSceneFloatChannel& Channel = FloatSection->GetChannel();
        float Value;
        FFrameTime Time((int)(FMath::Floor(FrameNo)), FMath::Frac(FrameNo));
        bool Success = Channel.Evaluate(Time, Value);
        if (Success) {
            curves.Add(Value);
            names.Add(FloatSection->GetName());
        }
    }
    return curves.Num();
#endif
}

bool UVrmEditorBPFunctionLibrary::FixIKRigForUE57Retargeting(UIKRigDefinition* IKRigAsset)
{
#if UE_VERSION_OLDER_THAN(5,0,0)
    // IK Rigs not supported before UE5
    UE_LOG(LogTemp, Warning, TEXT("FixIKRigForUE57Retargeting: IK Rigs not supported in UE4"));
    return false;
#elif UE_VERSION_OLDER_THAN(5,7,0)
    // Not needed for UE5.6 and earlier
    UE_LOG(LogTemp, Warning, TEXT("FixIKRigForUE57Retargeting: This function is only needed for UE5.7+"));
    return false;
#else
    if (!IKRigAsset)
    {
        UE_LOG(LogTemp, Error, TEXT("FixIKRigForUE57Retargeting: Invalid IK Rig asset"));
        return false;
    }

#if WITH_EDITOR
    UIKRigController* Controller = UIKRigController::GetController(IKRigAsset);
    if (!Controller)
    {
        UE_LOG(LogTemp, Error, TEXT("FixIKRigForUE57Retargeting: Could not get IK Rig controller for %s"), *IKRigAsset->GetName());
        return false;
    }

    UE_LOG(LogTemp, Log, TEXT("FixIKRigForUE57Retargeting: Processing IK Rig: %s"), *IKRigAsset->GetName());

    bool bModified = false;
    
    // Helper lambda to convert toe goal/bone names to foot equivalents
    auto ConvertToeToFoot = [](const FString& InName) -> FString {
        FString OutName = InName;
        OutName.ReplaceInline(TEXT("Toes"), TEXT("Foot"));
        OutName.ReplaceInline(TEXT("toes"), TEXT("foot"));
        return OutName;
    };
    
    // Helper lambda to check if a goal is toe-based
    auto IsToeBasedGoal = [](const FString& GoalName, const FString& BoneName) -> bool {
        return ((GoalName.Contains(TEXT("Toes")) || GoalName.Contains(TEXT("Toe"))) && 
                (BoneName.Contains(TEXT("Toes")) || BoneName.Contains(TEXT("toes"))));
    };
    
    // Find and update toe-based goals to foot-based goals
    TArray<FName> GoalsToRemove;
    TMap<FName, FName> GoalBoneMapping; // Old goal name -> new bone name
    TMap<FName, FName> NewToOldGoalMapping; // New goal name -> old goal name (for reverse lookup)
    
    const TArray<UIKRigEffectorGoal*>& Goals = IKRigAsset->GetGoalArray();
    for (UIKRigEffectorGoal* Goal : Goals)
    {
        if (!Goal) continue;
        
        FString GoalName = Goal->GoalName.ToString();
        FString BoneName = Goal->BoneName.ToString();
        
        // Check if this is a toe-based IK goal that should be changed to foot
        if (IsToeBasedGoal(GoalName, BoneName))
        {
            FString FootBoneName = ConvertToeToFoot(BoneName);
            FString FootGoalName = ConvertToeToFoot(GoalName);
            
            GoalsToRemove.Add(Goal->GoalName);
            GoalBoneMapping.Add(*FootGoalName, *FootBoneName);
            NewToOldGoalMapping.Add(*FootGoalName, Goal->GoalName);
            
            UE_LOG(LogTemp, Log, TEXT("  - Will replace goal '%s' (bone: %s) with '%s' (bone: %s)"), 
                   *GoalName, *BoneName, *FootGoalName, *FootBoneName);
            bModified = true;
        }
    }
    
    if (!bModified)
    {
        UE_LOG(LogTemp, Warning, TEXT("FixIKRigForUE57Retargeting: No toe-based goals found in %s. Asset may already be configured for UE5.7+"), *IKRigAsset->GetName());
        return false;
    }
    
    // Store solver connections before removing goals
    TMap<FName, int32> GoalSolverConnections;
    TMap<FName, FName> ChainGoalAssignments; // Chain name -> goal name
    
    const auto& RetargetChains = IKRigAsset->GetRetargetChains();
    for (const FBoneChain& Chain : RetargetChains)
    {
        if (Chain.IKGoalName != NAME_None)
        {
            ChainGoalAssignments.Add(Chain.ChainName, Chain.IKGoalName);
        }
    }
    
    // Get solver connections
    for (int32 SolverIndex = 0; SolverIndex < Controller->GetNumSolvers(); ++SolverIndex)
    {
        for (const FName& GoalName : GoalsToRemove)
        {
            // Check if this goal is connected to this solver
            // We'll need to reconnect the new goal to the same solver
            if (Goals.ContainsByPredicate([GoalName](const UIKRigEffectorGoal* G) { return G && G->GoalName == GoalName; }))
            {
                GoalSolverConnections.Add(GoalName, SolverIndex);
            }
        }
    }
    
    // Remove old toe-based goals
    for (const FName& GoalName : GoalsToRemove)
    {
        Controller->RemoveGoal(GoalName);
        UE_LOG(LogTemp, Log, TEXT("  - Removed goal: %s"), *GoalName.ToString());
    }
    
    // Add new foot-based goals
    for (const auto& Mapping : GoalBoneMapping)
    {
        FName NewGoalName = Mapping.Key;
        FName NewBoneName = Mapping.Value;
        
        // Create the new goal
        FName CreatedGoal = Controller->AddNewGoal(NewGoalName, NewBoneName);
        if (CreatedGoal != NAME_None)
        {
            UE_LOG(LogTemp, Log, TEXT("  - Created new goal: %s on bone: %s"), *NewGoalName.ToString(), *NewBoneName.ToString());
            
            // Reconnect to solver if it was connected before
            // Use the reverse mapping to find the old goal name
            if (const FName* OldGoalNamePtr = NewToOldGoalMapping.Find(NewGoalName))
            {
                if (GoalSolverConnections.Contains(*OldGoalNamePtr))
                {
                    int32 SolverIndex = GoalSolverConnections[*OldGoalNamePtr];
                    Controller->ConnectGoalToSolver(CreatedGoal, SolverIndex);
                    UE_LOG(LogTemp, Log, TEXT("  - Connected goal %s to solver %d"), *CreatedGoal.ToString(), SolverIndex);
                }
            }
            
            // Reassign to retarget chains
            for (const auto& ChainAssignment : ChainGoalAssignments)
            {
                // Use the reverse mapping to find the old goal name
                if (const FName* OldGoalNamePtr = NewToOldGoalMapping.Find(NewGoalName))
                {
                    if (ChainAssignment.Value == *OldGoalNamePtr)
                    {
                        Controller->SetRetargetChainGoal(ChainAssignment.Key, CreatedGoal);
                        UE_LOG(LogTemp, Log, TEXT("  - Assigned goal %s to chain %s"), *CreatedGoal.ToString(), *ChainAssignment.Key.ToString());
                    }
                }
            }
        }
        else
        {
            UE_LOG(LogTemp, Error, TEXT("  - Failed to create goal: %s"), *NewGoalName.ToString());
        }
    }
    
    // Update retarget chains from *Toes to *Foot end bones
    for (const FBoneChain& Chain : RetargetChains)
    {
        FString ChainName = Chain.ChainName.ToString();
        FString EndBone = Chain.EndBone.BoneName.ToString();
        
        if ((ChainName.Contains(TEXT("Leg")) || ChainName.Contains(TEXT("leg"))) && 
            (EndBone.Contains(TEXT("Toes")) || EndBone.Contains(TEXT("toes"))))
        {
            // Change chain end bone from toes to foot
            FString NewEndBone = EndBone;
            NewEndBone.ReplaceInline(TEXT("Toes"), TEXT("Foot"));
            NewEndBone.ReplaceInline(TEXT("toes"), TEXT("foot"));
            
            // We need to get the start bone to update the chain
            FString StartBone = Chain.StartBone.BoneName.ToString();
            
            // Preserve IK goal assignment: if this chain was using a toe-based goal that
            // was converted to a foot-based goal, remap to the new goal name.
            FName GoalNameToUse = Chain.IKGoalName;
            for (const TPair<FName, FName>& GoalPair : NewToOldGoalMapping)
            {
                // NewToOldGoalMapping maps NewGoalName -> OldGoalName
                if (GoalPair.Value == Chain.IKGoalName)
                {
                    GoalNameToUse = GoalPair.Key;
                    UE_LOG(LogTemp, Log, TEXT("  - Remapping chain goal from %s to %s"), *Chain.IKGoalName.ToString(), *GoalNameToUse.ToString());
                    break;
                }
            }
            
            UE_LOG(LogTemp, Log, TEXT("  - Updating chain '%s' end bone from %s to %s"), *ChainName, *EndBone, *NewEndBone);
            
            // Remove and recreate the chain with new end bone and updated goal
            Controller->RemoveRetargetChain(Chain.ChainName);
            Controller->AddRetargetChain(Chain.ChainName, *StartBone, *NewEndBone, GoalNameToUse);
        }
    }
    
    IKRigAsset->MarkPackageDirty();
    UE_LOG(LogTemp, Log, TEXT("FixIKRigForUE57Retargeting: Successfully updated IK Rig: %s"), *IKRigAsset->GetName());
    return true;
#else
    UE_LOG(LogTemp, Error, TEXT("FixIKRigForUE57Retargeting: Editor support required"));
    return false;
#endif // WITH_EDITOR
#endif // version check
}