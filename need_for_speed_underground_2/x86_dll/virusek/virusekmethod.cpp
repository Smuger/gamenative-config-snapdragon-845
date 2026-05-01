#define _CRT_SECURE_NO_WARNINGS
#include <windows.h>
#include "../shared/minhook/minhook.h"
#include "virusekmethod.h"
#include "../shared/utils.h"
#include "../shared/crcfixer.h"
#include "../shared/config.h"

extern Config config;

VirtualQuery_typedef VirtualQuery_Orig;
FindWindowA_typedef FindWindowA_Orig;

__declspec(naked) void Ret0()
{
	__asm xor eax, eax
	__asm ret
}

// This little function is an unnecessary hop but makes for a useful unchecked breakpoint when debugging
DWORD RemapToPtr3;
__declspec(naked) void JmpToPtr3()
{
	__asm 
	{
		push dword ptr [RemapToPtr3]
		ret
	}
}

DWORD CheckRegion(DWORD start, DWORD size, DWORD exeStart, DWORD exeEnd)
{
	logc(FOREGROUND_GREEN, "CheckRegion: Start: %08X Size: %08X (exe range %08X..%08X)\n", start, size, exeStart, exeEnd);
	BYTE* ptr = (BYTE*)start;
	size -= 0x48;
	DWORD candidatesSeen = 0;
	for (DWORD i = 0; i < size; i++)
	{
		if (ptr[i + 0] == 0x08 && ptr[i + 1] == 0x00 && ptr[i + 2] == 0x00 && ptr[i + 3] == 0x00 && ptr[i + 4] == 0x00 && ptr[i + 5] == 0x00 && ptr[i + 6] == 0x00 && ptr[i + 7] == 0x00)
		{
			candidatesSeen++;
			// Check Pointers
			DWORD ptr1Addr = i + 0x38;
			DWORD ptr1 = *(DWORD*)&ptr[ptr1Addr];	// Map to Ptr3
			DWORD ptr2Addr = i + 0x44;
			DWORD ptr2 = *(DWORD*)&ptr[ptr2Addr];	// Map to a xor eax,eax ret
			DWORD ptr3Addr = i + 0x2C;
			RemapToPtr3 = *(DWORD*)&ptr[ptr3Addr];	// Function to Map to

			logc(FOREGROUND_YELLOW, "[Virusek] Candidate layout at %08X: Ptr1=%08X Ptr2=%08X Ptr3=%08X\n", start + i, ptr1, ptr2, RemapToPtr3);

			if (ptr1 < exeStart || ptr1 > exeEnd ||
				ptr2 < exeStart || ptr2 > exeEnd ||
				RemapToPtr3 < exeStart || RemapToPtr3 > exeEnd)
			{
				logc(FOREGROUND_YELLOW, "[Virusek]   rejected: pointer(s) outside main module image\n");
				continue;
			}

			// just make sure all the bytes before where the pointers where are 0 and have their correct suffix bytes
			if (ptr[ptr1Addr - 1] != 0 || ptr[ptr1Addr + 4] != 0x5 ||
				ptr[ptr2Addr - 1] != 0 || ptr[ptr2Addr + 4] != 0xE ||
				ptr[ptr3Addr - 1] != 0 || ptr[ptr3Addr + 4] != 0x4)
			{
				logc(FOREGROUND_YELLOW, "[Virusek]   rejected: suffix bytes (expect 0/5/E/4 pattern)\n");
				continue;
			}

			logc(FOREGROUND_GREEN, "CheckRegion: Found SecuROM region to patch at %08X  (Ptr1: %08X Ptr2: %08X Ptr3: %08X)\n", start + i, ptr1, ptr2, RemapToPtr3);
			log("[Virusek] APPLYING in-memory patch at RVA+%08X (Ptr1->JmpToPtr3, Ptr2->Ret0)\n", (unsigned)(start + i - exeStart));

			*(DWORD*)&ptr[ptr1Addr] = (DWORD)&JmpToPtr3;
			*(DWORD*)&ptr[ptr2Addr] = (DWORD)&Ret0;

			GetKey(true);
			return i;
		}
	}
	if (candidatesSeen > 0)
		log("[Virusek] CheckRegion %08X: %u candidate layout(s) seen, none passed validation\n", start, (unsigned)candidatesSeen);
	return -1L;
}

void RunVirusekMethod()
{
	DWORD exeStart = (DWORD)GetModuleHandle(NULL);
	DWORD exeSize = GetExeSizeInMemory();
	DWORD exeEnd = exeStart + exeSize;

	log("[Virusek] ===== RunVirusekMethod (SecuROM 7/8 in-image patch) =====\n");
	log("[Virusek] Main module: base=%08X size=%08X end=%08X\n", exeStart, exeSize, exeEnd);

	MEMORY_BASIC_INFORMATION mbi;
	DWORD AddrFound = -1L;
	DWORD ret = VirtualQuery((void*)0, &mbi, sizeof(mbi));
	DWORD regionsTotal = 0;
	DWORD regionsExecutableGuard = 0;
	if (ret == 0)
	{
		log("[Virusek] VirtualQuery(0) failed; cannot walk regions — abort scan\n");
		return;
	}

	while (true)
	{
		regionsTotal++;
		const bool guard =
			mbi.State == 0x1000 &&
			((mbi.Protect & 0xEE) != 0) &&
			((mbi.Protect & 0x100) == 0);

		if (guard)
		{
			regionsExecutableGuard++;
			DWORD Addr = CheckRegion((DWORD)mbi.BaseAddress, mbi.RegionSize, exeStart, exeEnd);
			if (Addr != 0xFFFFFFFF)
			{
				AddrFound = Addr;
				log("[Virusek] Patch succeeded: absolute=%08X (region base=%08X RVA-like offset=%08X)\n",
					(unsigned)((DWORD)mbi.BaseAddress + Addr),
					(unsigned)(DWORD)mbi.BaseAddress,
					(unsigned)Addr);
				break;
			}
		}

		if (mbi.RegionSize <= 0)
			break;

		ret = VirtualQuery((void*)(((DWORD)mbi.BaseAddress) + mbi.RegionSize), &mbi, sizeof(mbi));
		if (ret == 0)
			break;
	}

	log("[Virusek] VirtualQuery walk: regionsSeen=%u regionsMatchingExecutableGuard=%u\n",
		(unsigned)regionsTotal, (unsigned)regionsExecutableGuard);

	if (AddrFound != -1L)
		logc(FOREGROUND_BROWN, "[Virusek] RESULT: SecuROM patch applied (FindWindow trigger). Offset in matched region=%08X\n", AddrFound);
	else
		log("[Virusek] RESULT: NO matching SecuROM fingerprint — no in-memory patch applied (game build may differ or FindWindow not used as expected).\n");
	log("[Virusek] ===== RunVirusekMethod end =====\n");
}

static bool s_virusekRanOnce = false;

bool TryRunVirusekMethodOnce(const char* triggerName)
{
	if (!config.GetBool("UseVirusekMethod"))
		return false;
	if (s_virusekRanOnce)
		return false;
	s_virusekRanOnce = true;
	log("[Virusek] TryRunVirusekMethodOnce trigger=%s\n", triggerName ? triggerName : "?");
	RunVirusekMethod();
	return true;
}

HWND WINAPI FindWindowA_Hook(LPCSTR lpClassName, LPCSTR lpWindowName)
{
	MH_STATUS status = MH_DisableHook(&FindWindowA);
	log("[Virusek] FindWindowA_Hook ENTER (Virusek trigger): class=\"%s\" name=\"%s\" MH_DisableHook=%d\n",
		lpClassName ? lpClassName : "",
		lpWindowName ? lpWindowName : "",
		(int)status);
	logc(FOREGROUND_BROWN, "FindWindowA_Hook: lpClassName: %s lpWindowName: %s status=%08X\n", lpClassName ? lpClassName : "NULL", lpWindowName ? lpWindowName : "NULL", status);

	TryRunVirusekMethodOnce("FindWindowA");

	log("[Virusek] FindWindowA_Hook: calling original FindWindowA (one-shot hook disabled)\n");
	
	// Skylanders specific testing!
	/*
	CRCFixer(-1L, -1L, true, false);
	WritePatchBYTE(0x013EEE76, 0xB0);		// mov al, 0
	WritePatchBYTE(0x013EEE77, 0x00);
	WritePatchBYTE(0x013EEE78, 0x90);
	WritePatchBYTE(0x012667F1, 0x39);		// cmp eax, eax
	WritePatchBYTE(0x012667F2, 0xC0);
	WritePatchDWORD(0x0159A910, 0x90C3C031); // xor eax,eax ret // Patching this stops paul.dll loading
	WritePatchDWORD(0x01416B80, 0x080A5BE9); // jmp to the good function from the bad one
	WritePatchBYTE(0x01416B84, 0x00);
	WritePatchBYTE(0x01416B85, 0x90);
	WritePatchBYTE(0x01416B86, 0x90);
	WritePatchBYTE(0x00EA1F9A, 0x39);		// 6005 patch cmp eax, eax
	WritePatchBYTE(0x00EA1F9B, 0xC0);
	ApplyPatches();
	GetKey(true);
	*/
	{
		int cpus = config.GetInt("CPUCount", -1);
		log("[Virusek] RestrictProcessors(CPUCount=%d)\n", cpus);
		RestrictProcessors(cpus);
	}
	HWND fwRet = FindWindowA_Orig(lpClassName, lpWindowName);
	log("[Virusek] FindWindowA_Orig returned HWND=%p\n", (void*)fwRet);
	return fwRet;
}

BOOL VirtualQuery_Hook_Logging = false;
SIZE_T WINAPI VirtualQuery_Hook(LPCVOID lpAddress, PMEMORY_BASIC_INFORMATION lpBuffer, SIZE_T dwLength)
{
	if (lpAddress == NULL)
		VirtualQuery_Hook_Logging = true;
	if (VirtualQuery_Hook_Logging)
		logc(FOREGROUND_CYAN, "VirtualQuery_Hook: lpAddress: %08X %08X\n", (DWORD)lpAddress, dwLength);
	SIZE_T ret = VirtualQuery_Orig(lpAddress, lpBuffer, dwLength);
	if (dwLength == sizeof(MEMORY_BASIC_INFORMATION))
	{
		if (VirtualQuery_Hook_Logging)
		{
			logc(FOREGROUND_CYAN, "Ret: %08X BaseAddress: %08X AllocationBase: %08X AllocationProtect: %08X RegionSize: %08X State: %08X Protect: %08X Type: %08X\n", ret,
				 (DWORD)lpBuffer->BaseAddress, (DWORD)lpBuffer->AllocationBase, lpBuffer->AllocationProtect, lpBuffer->RegionSize, lpBuffer->State, lpBuffer->Protect, lpBuffer->Type);
		}
	}
	else
		logc(FOREGROUND_RED, "VirtualQuery_Hook: Unexpected dwLength: %d\n", dwLength);
	return ret;
}
