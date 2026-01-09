// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Misc/EngineVersionComparison.h"
#include "UObject/StrongObjectPtr.h"
#include "OSCServer.h"	// for game build link error

#include "VrmVMCObject.generated.h"

struct FOSCMessage;

struct FVMCData {
	FString ServerAddress = "";
	int Port = 0;

	TMap<FString, FTransform> BoneData;
	TMap<FString, float> CurveData;

	void ClearData() {
		BoneData.Empty();
		CurveData.Empty();
	}

	bool operator==(const FVMCData& Other) const {
		if (Port != Other.Port) return false;
		if (ServerAddress != Other.ServerAddress) return false;
		return true;
	}
};


UCLASS()
class VRM4UCAPTURE_API UVrmVMCObject : public UObject
{
	GENERATED_BODY()

	FCriticalSection cs;

	TStrongObjectPtr<UOSCServer> OSCServer;

	FVMCData VMCData;
	FVMCData VMCData_Cache;

	bool bDataUpdated = false;

	// Diagnostic tracking
	int32 TotalPacketsReceived = 0;
	double LastPacketReceivedTime = 0.0;
	bool bHasReceivedRootTranslation = false;
	int32 LastBoneCount = 0;
	int32 LastCurveCount = 0;

public:


	FString ServerName;
	uint16 port;

	bool bForceUpdate = false;

	void CreateServer(FString name, uint16 port);
	void DestroyServer();
	void OSCReceivedMessageEvent(const FOSCMessage& Message, const FString& IPAddress, uint16 Port);

	bool CopyVMCData(FVMCData& dst);
	void ClearVMCData();

	// Diagnostic methods - thread-safe access with critical section
	int32 GetTotalPacketsReceived() const { 
		FScopeLock lock(&const_cast<FCriticalSection&>(cs)); 
		return TotalPacketsReceived; 
	}
	double GetLastPacketReceivedTime() const { 
		FScopeLock lock(&const_cast<FCriticalSection&>(cs)); 
		return LastPacketReceivedTime; 
	}
	bool HasReceivedRootTranslation() const { 
		FScopeLock lock(&const_cast<FCriticalSection&>(cs)); 
		return bHasReceivedRootTranslation; 
	}
	int32 GetLastBoneCount() const { 
		FScopeLock lock(&const_cast<FCriticalSection&>(cs)); 
		return LastBoneCount; 
	}
	int32 GetLastCurveCount() const { 
		FScopeLock lock(&const_cast<FCriticalSection&>(cs)); 
		return LastCurveCount; 
	}
};
