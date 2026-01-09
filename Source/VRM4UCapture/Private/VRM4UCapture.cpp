// VRM4U Copyright (c) 2021-2024 Haruyoshi Yamamoto. This software is released under the MIT License.

#include "VRM4UCapture.h"
#include "CoreMinimal.h"
#include "VRM4UCaptureLog.h"
#include "Modules/ModuleManager.h"
#include "Internationalization/Internationalization.h"

#define LOCTEXT_NAMESPACE "VRM4UMisc"

DEFINE_LOG_CATEGORY(LogVRM4UCapture);

// Console variable for VMC debugging
TAutoConsoleVariable<int32> CVarVMCDebug(
	TEXT("vrm4u.VMC.Debug"),
	0,
	TEXT("Enable VMC debugging output.\n")
	TEXT("0: Disabled (default)\n")
	TEXT("1: Enabled - logs packet reception, port info, and diagnostics"),
	ECVF_Default
);

//////////////////////////////////////////////////////////////////////////
// FSpriterImporterModule

class FVRM4UCaptureModule : public FDefaultModuleImpl
{
public:
	virtual void StartupModule() override
	{
	}

	virtual void ShutdownModule() override
	{
	}
};

//////////////////////////////////////////////////////////////////////////

IMPLEMENT_MODULE(FVRM4UCaptureModule, VRM4UCapture);

//////////////////////////////////////////////////////////////////////////

#undef LOCTEXT_NAMESPACE
