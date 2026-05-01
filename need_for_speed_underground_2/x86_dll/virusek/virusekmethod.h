#pragma once
#include "../shared/typedefs.h"

extern VirtualQuery_typedef VirtualQuery_Orig;
extern FindWindowA_typedef FindWindowA_Orig;

void RunVirusekMethod();
bool TryRunVirusekMethodOnce(const char* triggerName);
HWND WINAPI FindWindowA_Hook(LPCSTR lpClassName, LPCSTR lpWindowName);
SIZE_T WINAPI VirtualQuery_Hook(LPCVOID lpAddress, PMEMORY_BASIC_INFORMATION lpBuffer, SIZE_T dwLength);