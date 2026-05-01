/*
 * SafeDisc secdrv IOCTL emulation — adapted from SafeDiscLoader2 (same repo author lineage).
 * Upstream: https://github.com/nckstwrt/SafeDiscLoader2/blob/main/src/secdrv_ioctl.cpp
 */
#define _CRT_SECURE_NO_WARNINGS
#include <windows.h>
#include "../shared/utils.h"

enum SafeDiscCommand {
	GetDebugRegisterInfo = 0x3c,
	GetIdtInfo = 0x3d,
	SetupVerification = 0x3e,
	Command3Fh = 0x3f,
	Command40h = 0x40,
	Command41h = 0x41,
	Command42h = 0x42,
	Command43h = 0x43
};

typedef struct MainIoctlInBuffer {
	DWORD VersionMajor;
	DWORD VersionMinor;
	DWORD VersionPatch;

	SafeDiscCommand Command;
	DWORD VerificationData[0x100];

	DWORD ExtraDataSize;
	DWORD ExtraData[0x40];
} MainIoctlInBuffer;

typedef struct MainIoctlOutBuffer {
	DWORD VersionMajor;
	DWORD VersionMinor;
	DWORD VersionPatch;

	DWORD VerificationData[0x100];

	DWORD ExtraDataSize;
	DWORD ExtraData[0x80];
} MainIoctlOutBuffer;

static bool s_hasLoggedVersion = false;

static void BuildVerificationData(DWORD verificationData[0x100])
{
	DWORD curValue = 0xf367ac7f;
	verificationData[0] = *reinterpret_cast<int*>(0x7ffe0320);

	for (int i = 3; i > 0; --i) {
		curValue = 0x361962e9 - 0xd5acb1b * curValue;
		verificationData[i] = curValue;
		verificationData[0] ^= curValue;
	}
}

BOOL SafeDisc_ProcessMainIoctl(LPVOID lpInBuffer, DWORD nInBufferSize, LPVOID lpOutBuffer, DWORD nOutBufferSize)
{
	if (!lpInBuffer || !lpOutBuffer) {
		logc(FOREGROUND_RED, "invalid ioctl buffers: lpInBuffer %X, lpOutBuffer %X\n", reinterpret_cast<int>(lpInBuffer), reinterpret_cast<int>(lpOutBuffer));
		return FALSE;
	}

	if (nInBufferSize != sizeof(MainIoctlInBuffer)) {
		logc(FOREGROUND_RED, "invalid ioctl in-buffer size: %X\n", nInBufferSize);
		return FALSE;
	}

	if (nOutBufferSize != sizeof(MainIoctlOutBuffer) && nOutBufferSize != 0xC18) {
		logc(FOREGROUND_RED, "invalid ioctl out-buffer size: %X\n", nOutBufferSize);
		return FALSE;
	}

	MainIoctlInBuffer* inBuffer = static_cast<MainIoctlInBuffer*>(lpInBuffer);
	MainIoctlOutBuffer* outBuffer = static_cast<MainIoctlOutBuffer*>(lpOutBuffer);

	if (!s_hasLoggedVersion) {
		log("SafeDisc ioctl version %d.%d.%d detected.\n", (int)inBuffer->VersionMajor, (int)inBuffer->VersionMinor, (int)inBuffer->VersionPatch);
		s_hasLoggedVersion = true;
	}

	outBuffer->VersionMajor = 4;
	outBuffer->VersionMinor = 3;
	outBuffer->VersionPatch = 86;

	switch (inBuffer->Command) {
	case GetDebugRegisterInfo:
		outBuffer->ExtraDataSize = 4;
		outBuffer->ExtraData[0] = 0x400;
		break;
	case GetIdtInfo:
		outBuffer->ExtraDataSize = 4;
		outBuffer->ExtraData[0] = 0x2C8;
		break;
	case SetupVerification:
		log("command SetupVerification called\n");
		outBuffer->ExtraDataSize = 4;
		outBuffer->ExtraData[0] = 0x5278d11b;
		break;
	case Command3Fh:
		if (nOutBufferSize != 0xC18 || inBuffer->ExtraData[0] > 0x60)
			return FALSE;
		outBuffer->ExtraDataSize = 4;
		outBuffer->ExtraData[0] = 0;
		break;
	case Command40h:
		if (nOutBufferSize != 0xC18 || !inBuffer->ExtraData[0] || !inBuffer->ExtraData[1])
			return FALSE;
		outBuffer->ExtraDataSize = 4;
		if (inBuffer->ExtraData[1] <= 0x80)
			outBuffer->ExtraData[0] = 0x56791283;
		else
			outBuffer->ExtraData[0] = 0x587C1284;
		break;
	case Command41h:
		if (nOutBufferSize != 0xC18 ||
			!LOBYTE(inBuffer->ExtraData[0]))
			return FALSE;
		outBuffer->ExtraDataSize = 4;
		break;
	case Command42h:
		return FALSE;
	case Command43h:
		if (inBuffer->ExtraData[0] != 0x98A64100 || inBuffer->ExtraData[1] > 7 || inBuffer->ExtraData[1] == 4)
			return FALSE;
		outBuffer->ExtraDataSize = 4;
		outBuffer->ExtraData[0] = 0;
		break;
	default:
		logc(FOREGROUND_RED, "unhandled ioctl command: %X\n", static_cast<DWORD>(inBuffer->Command));
		return FALSE;
	}

	BuildVerificationData(outBuffer->VerificationData);
	return TRUE;
}
