// VRM4U Copyright (c) 2021-2024 Haruyoshi Yamamoto. This software is released under the MIT License.

using UnrealBuildTool;

public class VRM4UEditor : ModuleRules
{
	public VRM4UEditor(ReadOnlyTargetRules Target) : base(Target)
	{
        PCHUsage = ModuleRules.PCHUsageMode.UseExplicitOrSharedPCHs;

        PrivateDependencyModuleNames.AddRange(
			new string[] {
				"Core",
				"CoreUObject",
                "InputCore",
                "EditorStyle",
                "Engine",
				"UnrealEd",
                "Slate",
                "SlateCore",

                "MovieSceneCapture",

				"MovieScene",
				"MovieSceneTracks",

				//"ControlRigEditor",

				"VRM4U",
			});

		// Add IKRig dependencies for UE5+ (needed for VrmEditorBPFunctionLibrary)
		BuildVersion Version;
		if (BuildVersion.TryRead(BuildVersion.GetDefaultFileName(), out Version))
		{
			if (Version.MajorVersion == 5)
			{
				PrivateDependencyModuleNames.Add("IKRig");
				if (Target.bBuildEditor)
				{
					PrivateDependencyModuleNames.Add("IKRigEditor");
				}
			}
		}

		PrivateIncludePathModuleNames.AddRange(
			new string[] {
				"AssetTools",
				"AssetRegistry",
            });

		DynamicallyLoadedModuleNames.AddRange(
			new string[] {
				"AssetTools",
				"AssetRegistry"
			});

        PrivateIncludePaths.AddRange(
        new string[] {
			//"../Runtime/Renderer/Private",
        });
    }
}
