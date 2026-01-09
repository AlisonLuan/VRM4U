// Fill out your copyright notice in the Description page of Project Settings.


#include "VrmVMCObject.h"
#include "VRM4U_VMCSubsystem.h"
#include "VRM4UCapture.h"

#include "Engine/Engine.h"
#include "UObject/StrongObjectPtr.h"
#include "Misc/ScopeLock.h"
#include "OSCManager.h"
#include "OSCServer.h"
#include "VRM4UCaptureLog.h"

void UVrmVMCObject::DestroyServer() {
	ServerName = "";
	port = 0;

	if (OSCServer.Get()) {
		OSCServer->Stop();
	}
	OSCServer.Reset(nullptr);
}
void UVrmVMCObject::CreateServer(FString inName, uint16 inPort) {
	ServerName = inName;
	port = inPort;
#if	UE_VERSION_OLDER_THAN(4,25,0)
#else
	OSCServer.Reset(UOSCManager::CreateOSCServer(ServerName, port, true, true, FString(), this));

	const bool bDebugEnabled = CVarVMCDebug.GetValueOnAnyThread() > 0;
	
	if (OSCServer.Get())
	{
		if (bDebugEnabled)
		{
			UE_LOG(LogVRM4UCapture, Log, TEXT("VMC: Successfully created OSC server '%s' on port %d"), *ServerName, port);
		}
		
		OSCServer->OnOscMessageReceivedNative.RemoveAll(nullptr);
		OSCServer->OnOscMessageReceivedNative.AddUObject(this, &UVrmVMCObject::OSCReceivedMessageEvent);

#if WITH_EDITOR
		OSCServer->SetTickInEditor(true);
#endif // WITH_EDITOR
	}
	else
	{
		UE_LOG(LogVRM4UCapture, Warning, TEXT("VMC: FAILED to create OSC server '%s' on port %d. Check if port is already in use or blocked by firewall."), *ServerName, port);
	}
#endif
}

void UVrmVMCObject::OSCReceivedMessageEvent(const FOSCMessage& Message, const FString& IPAddress, uint16 Port) {

	FOSCAddress a = UOSCManager::GetOSCMessageAddress(Message);
	FString addressPath = UOSCManager::GetOSCAddressFullPath(a);

	TArray<FString> str;
	UOSCManager::GetAllStrings(Message, str);

	TArray<float> curve;
	UOSCManager::GetAllFloats(Message, curve);

	FTransform t;
	float f = 0;
	if (curve.Num() == 1) {
		f = curve[0];
	}
	if (curve.Num() >= 7) {
		t.SetLocation(FVector(-curve[0], curve[2], curve[1]) * 100.f);
		t.SetRotation(FQuat(-curve[3], curve[5], curve[4], curve[6]));
	}
	if (curve.Num() >= 10) {
		t.SetScale3D(FVector(curve[7], curve[9], curve[8]));
	}

	if (addressPath == TEXT("/VMC/Ext/Root/Pos")) {
		VMCData.BoneData.FindOrAdd(str[0]) = t;
		bDataUpdated = true;
		bHasReceivedRootTranslation = true;
	}
	if (addressPath == TEXT("/VMC/Ext/Bone/Pos")) {
		VMCData.BoneData.FindOrAdd(str[0]) = t;
		bDataUpdated = true;
	}
	if (addressPath == TEXT("/VMC/Ext/Blend/Val")) {
		VMCData.CurveData.FindOrAdd(str[0]) = f;
		bDataUpdated = true;
	}

	if (bDataUpdated == true){
		bool b = bForceUpdate;
		if (addressPath == TEXT("/VMC/Ext/OK")) {
			b = true;
		}
		if (addressPath == TEXT("/VMC/Ext/T")) {
			b = true;
		}
		if (addressPath == TEXT("/VMC/Ext/Blend/Apply")) {
			b = true;
		}
		
		if (b) {
			FScopeLock lock(&cs);
			VMCData_Cache = VMCData;
			bDataUpdated = false;
			
			// Update diagnostics
			TotalPacketsReceived++;
			LastPacketReceivedTime = FPlatformTime::Seconds();
			LastBoneCount = VMCData_Cache.BoneData.Num();
			LastCurveCount = VMCData_Cache.CurveData.Num();
			
			const bool bDebugEnabled = CVarVMCDebug.GetValueOnAnyThread() > 0;
			if (bDebugEnabled && TotalPacketsReceived % 100 == 1) // Log on packet 1, then every 100th packet thereafter (101, 201, ...) to avoid spam
			{
				UE_LOG(LogVRM4UCapture, Log, TEXT("VMC: Received packet #%d from %s:%d - Bones: %d, Curves: %d, Has Root: %s"),
					TotalPacketsReceived, *IPAddress, Port, LastBoneCount, LastCurveCount, 
					bHasReceivedRootTranslation ? TEXT("Yes") : TEXT("No"));
			}
		}
	}

}
bool UVrmVMCObject::CopyVMCData(FVMCData& dst) {
	FScopeLock lock(&cs);
	dst = VMCData_Cache;
	return true;
}

void UVrmVMCObject::ClearVMCData() {
	FScopeLock lock(&cs);
	VMCData.ClearData();
	VMCData_Cache.ClearData();
}

