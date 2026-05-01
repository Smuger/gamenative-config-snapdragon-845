#define _CRT_SECURE_NO_WARNINGS
#include <windows.h>
#include <winternl.h>
#include <profileapi.h>
#include <string>

#include "../shared/config.h"
#include "../shared/nstring.h"
#include "../shared/utils.h"
#include "../shared/minhook/minhook.h"
#include "../shared/typedefs.h"
#include "../shared/crcfixer.h"
#include "virusekmethod.h"
#include "trigger_trace.h"
#include "securom7_hooks.h"

extern Config config;
extern bool logCreateFile;

DWORD CDCheckStartAddr = 0;
DWORD CDCheckEndAddr = 0;
bool NtContinueLogging = false;

OpenFileMappingW_typedef OpenFileMappingW_Orig;
GetDriveTypeW_typedef GetDriveTypeW_Orig;
GetVolumeInformationW_typedef GetVolumeInformationW_Orig;
GetFileAttributesA_typedef GetFileAttributesA_Orig;
GetFileAttributesW_typedef GetFileAttributesW_Orig;
IsBadReadPtr_typedef IsBadReadPtr_Orig;
KiUserExceptionDispatcher_typedef KiUserExceptionDispatcher_Orig;
NtContinue_typedef NtContinue_Orig;

int HWBPStage = 0;
int HWBPCheckDone = 0;
bool Securom7Confirmed = false;

void WINAPI KiUserExceptionDispatcher_RealHook(PEXCEPTION_RECORD ExceptionRecord, PCONTEXT Context);
void WINAPI KiUserExceptionDispatcher_Hook(PEXCEPTION_RECORD ExceptionRecord, PCONTEXT Context);

HANDLE WINAPI OpenFileMappingW_Hook(DWORD dwDesiredAccess, BOOL bInheritHandle, LPCWSTR lpName)
{
	logc(FOREGROUND_YELLOW, "OpenFileMappingW Hook - lpName: %ls\n", lpName ? lpName : L"!NULL!");
	HANDLE hHandle = OpenFileMappingW_Orig(dwDesiredAccess, bInheritHandle, lpName);
	if (lpName)
	{
		NString name = lpName;
		if (name.Contains("-=[SMS_"))
		{
			logc(FOREGROUND_YELLOW, "Detected SecuROM SMS file mapping name!\n");
			if (hHandle == NULL)
			{
				logc(FOREGROUND_YELLOW, "Creating fake SMS file mapping for name: %ls\n", lpName);
				hHandle = CreateFileMapping(INVALID_HANDLE_VALUE, NULL, PAGE_READWRITE, 0, 1723, name);
				MapViewOfFile(hHandle, FILE_MAP_ALL_ACCESS, 0, 0, 1723);
			}
		}
	}
	logc(FOREGROUND_YELLOW, "OpenFileMappingW: Handle: %08X\n", hHandle);
	return hHandle;
}

BOOL WINAPI IsBadReadPtr_Hook(CONST VOID* lp, UINT_PTR ucb)
{
	DWORD ret = (DWORD)_ReturnAddress();
	if (CDCheckStartAddr != 0 && ret >= CDCheckStartAddr && ret <= CDCheckEndAddr)
		return TRUE;
	return IsBadReadPtr_Orig(lp, ucb);
}

UINT WINAPI GetDriveTypeW_Hook(LPCWSTR lpRootPathName)
{
	const bool diskTrace = config.GetBool("VirusekDiskTrace", false);
	int matchesCd = 0;
	if (const char* cd = config.GetValue("CDROMDriveLetter"); cd && lpRootPathName && lpRootPathName[0])
	{
		wchar_t d = (wchar_t)towupper((unsigned char)cd[0]);
		if (towupper(lpRootPathName[0]) == d)
			matchesCd = 1;
	}
	if (diskTrace)
		log("[VirusekDiskTrace] GetDriveTypeW path=\"%ls\" CDROMDriveLetter=\"%s\" matchesLetter=%d\n",
			lpRootPathName ? lpRootPathName : L"(null)",
			config.GetValue("CDROMDriveLetter") ? config.GetValue("CDROMDriveLetter") : "(null)",
			matchesCd);

	if (matchesCd && config.GetBool("VirusekTriggerFirstDriveTypeMatch", false) && config.GetBool("UseVirusekMethod"))
		TryRunVirusekMethodOnce("GetDriveTypeW");

	if (const char* cd = config.GetValue("CDROMDriveLetter"); cd && lpRootPathName && lpRootPathName[0])
	{
		wchar_t d = (wchar_t)towupper((unsigned char)cd[0]);
		if (towupper(lpRootPathName[0]) == d)
		{
			logc(FOREGROUND_GREEN, "GetDriveTypeW_Hook = %ls IS A CDROM!\n", lpRootPathName ? lpRootPathName : L"NULL");
			return DRIVE_CDROM;
		}
	}
	log("GetDriveTypeW_Hook = %ls\n", lpRootPathName ? lpRootPathName : L"NULL");
	return GetDriveTypeW_Orig(lpRootPathName);
}

BOOL WINAPI GetVolumeInformationW_Hook(LPCWSTR lpRootPathName, LPWSTR lpVolumeNameBuffer, DWORD nVolumeNameSize, LPDWORD lpVolumeSerialNumber, LPDWORD lpMaximumComponentLength, LPDWORD lpFileSystemFlags, LPWSTR lpFileSystemNameBuffer, DWORD nFileSystemNameSize)
{
	if (config.GetBool("VirusekDiskTrace", false))
	{
		int matchesCd = 0;
		if (const char* cd = config.GetValue("CDROMDriveLetter"); cd && lpRootPathName && lpRootPathName[0]
			&& towupper(lpRootPathName[0]) == (wchar_t)towupper((unsigned char)cd[0]))
			matchesCd = 1;
		log("[VirusekDiskTrace] GetVolumeInformationW lpRootPathName=\"%ls\" CDROMDriveLetter=\"%s\" matchesLetter=%d\n",
			lpRootPathName ? lpRootPathName : L"(null)",
			config.GetValue("CDROMDriveLetter") ? config.GetValue("CDROMDriveLetter") : "(null)",
			matchesCd);
	}
	logc(FOREGROUND_BLUE, "GetVolumeInformationW_Hook: lpRootPathName: %ls\n", lpRootPathName ? lpRootPathName : L"NULL");
	BOOL ret = GetVolumeInformationW_Orig(lpRootPathName, lpVolumeNameBuffer, nVolumeNameSize, lpVolumeSerialNumber, lpMaximumComponentLength, lpFileSystemFlags, lpFileSystemNameBuffer, nFileSystemNameSize);
	const char* CDROMVolumeName = config.GetValue("CDROMVolumeName");
	if (const char* cd = config.GetValue("CDROMDriveLetter"); CDROMVolumeName && cd && lpVolumeNameBuffer && lpRootPathName && lpRootPathName[0]
		&& towupper(lpRootPathName[0]) == (wchar_t)towupper((unsigned char)cd[0]))
	{
		wchar_t wvol[256];
		if (MultiByteToWideChar(CP_ACP, 0, CDROMVolumeName, -1, wvol, 256) > 0 && wcslen(wvol) < nVolumeNameSize)
		{
			wcscpy(lpVolumeNameBuffer, wvol);
			logc(FOREGROUND_BLUE, "GetVolumeInformationW_Hook: Replacing VolumeName with: %ls\n", lpVolumeNameBuffer);
			if (lpFileSystemNameBuffer && nFileSystemNameSize > 5)
				wcscpy(lpFileSystemNameBuffer, L"CDFS");
			ret = TRUE;
		}
	}
	return ret;
}

DWORD WINAPI GetFileAttributesA_Hook(LPCSTR lpFileName)
{
	std::string strFileName;
	if (lpFileName)
	{
		strFileName = config.GetFileMapping(lpFileName);
		lpFileName = strFileName.c_str();
	}
	if (logCreateFile && lpFileName)
		log("GetFileAttributesA_Hook Hook - lpFileName: %s\n", lpFileName == NULL ? "!NULL!" : lpFileName);
	return GetFileAttributesA_Orig(lpFileName);
}

DWORD WINAPI GetFileAttributesW_Hook(LPCWSTR lpFileName)
{
	std::string strFileName;
	NString temp;

	if (lpFileName)
	{
		NString wideStr(lpFileName);
		strFileName = config.GetFileMapping(wideStr);
		temp = strFileName.c_str();
		lpFileName = temp;
	}
	if (logCreateFile && lpFileName)
		log("GetFileAttributesW_Hook Hook - lpFileName: %S\n", lpFileName == NULL ? L"!NULL!" : lpFileName);
	return GetFileAttributesW_Orig(lpFileName);
}

void WINAPI KiUserExceptionDispatcher_RealHook(PEXCEPTION_RECORD ExceptionRecord, PCONTEXT Context)
{
	if (ExceptionRecord->ExceptionCode == 0xC0000094)
	{
		NtContinueLogging = false;
		return;
	}
	if (ExceptionRecord->ExceptionCode == 0xC000001D)
		HWBPStage = 1;
	else
	{
		if (HWBPStage >= 1 && ExceptionRecord->ExceptionCode == 0x80000004)
			HWBPStage++;
		else
			HWBPStage = 0;
	}
}

void __declspec(naked) WINAPI KiUserExceptionDispatcher_Hook(PEXCEPTION_RECORD ExceptionRecord, PCONTEXT Context)
{
	__asm
	{
		MOV EAX, [ESP + 4]
		MOV ECX, [ESP]
		PUSH EAX
		PUSH ECX
		CALL KiUserExceptionDispatcher_RealHook
		jmp KiUserExceptionDispatcher_Orig
	}
}

NTSTATUS WINAPI NtContinue_Hook(PCONTEXT Context, BOOLEAN RaiseAlert)
{
	if (NtContinueLogging)
	{
		logc(FOREGROUND_PURPLE, "NtContinue_Hook: ThreadContext: %08X RaiseAlert: %d\n", Context, RaiseAlert);
		logc(FOREGROUND_PURPLE, "DR0: %08X DR1: %08X DR2: %08X DR3: %08X\n", Context->Dr0, Context->Dr1, Context->Dr2, Context->Dr3);
		logc(FOREGROUND_PURPLE, "DR6: %08X DR7: %08X\n", Context->Dr6, Context->Dr7);
		logc(FOREGROUND_PURPLE, "EIP: %08X\n", Context->Eip);
	}

	if (HWBPStage == 5)
	{
		logc(FOREGROUND_RED, "End of HWBP detection!\n");
		if (HWBPCheckDone++ == 1)
		{
			Securom7Confirmed = true;
			CRCFixer();
			GetKey(true);
		}
		HWBPStage = 0;
	}

	return NtContinue_Orig(Context, RaiseAlert);
}

void SecuRom7_RegisterHooks(void)
{
	MH_STATUS status = MH_OK;
	if ((status = MH_CreateHookApi(L"kernel32", "OpenFileMappingW", &OpenFileMappingW_Hook, reinterpret_cast<LPVOID*>(&OpenFileMappingW_Orig))) != MH_OK)
	{
		log("Unable to hook OpenFileMappingW: %d\n", status);
		return;
	}

	if (MH_CreateHookApi(L"kernel32", "GetDriveTypeW", &GetDriveTypeW_Hook, reinterpret_cast<LPVOID*>(&GetDriveTypeW_Orig)) != MH_OK)
	{
		log("Unable to hook GetDriveTypeW\n");
		return;
	}

	if (MH_CreateHookApi(L"kernel32", "GetVolumeInformationW", &GetVolumeInformationW_Hook, reinterpret_cast<LPVOID*>(&GetVolumeInformationW_Orig)) != MH_OK)
	{
		log("Unable to hook GetVolumeInformationW\n");
		return;
	}

	if ((status = MH_CreateHookApi(L"kernel32", "GetFileAttributesA", &GetFileAttributesA_Hook, reinterpret_cast<LPVOID*>(&GetFileAttributesA_Orig))) != MH_OK)
	{
		log("Unable to hook GetFileAttributesA: %d\n", status);
		return;
	}

	if ((status = MH_CreateHookApi(L"kernel32", "GetFileAttributesW", &GetFileAttributesW_Hook, reinterpret_cast<LPVOID*>(&GetFileAttributesW_Orig))) != MH_OK)
	{
		log("Unable to hook GetFileAttributesW: %d\n", status);
		return;
	}

	if (MH_CreateHookApi(L"kernel32", "IsBadReadPtr", &IsBadReadPtr_Hook, reinterpret_cast<LPVOID*>(&IsBadReadPtr_Orig)) != MH_OK)
	{
		log("Unable to hook IsBadReadPtr\n");
		return;
	}

	if (!config.GetBool("UseVirusekMethod"))
	{
		if (MH_CreateHookApi(L"ntdll", "KiUserExceptionDispatcher", &KiUserExceptionDispatcher_Hook, reinterpret_cast<LPVOID*>(&KiUserExceptionDispatcher_Orig)) != MH_OK)
			log("Unable to hook KiUserExceptionDispatcher\n");
		if (MH_CreateHookApi(L"ntdll", "NtContinue", &NtContinue_Hook, reinterpret_cast<LPVOID*>(&NtContinue_Orig)) != MH_OK)
			log("Unable to hook NtContinue\n");
	}

	if (config.GetBool("UseVirusekMethod"))
	{
		if (MH_CreateHookApi(L"user32", "FindWindowA", &FindWindowA_Hook, reinterpret_cast<LPVOID*>(&FindWindowA_Orig)) != MH_OK)
			log("Unable to hook FindWindowA\n");
	}

	InstallVirusekTriggerTraceHooks(config);
}
