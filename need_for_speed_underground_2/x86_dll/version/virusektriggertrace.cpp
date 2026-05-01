#define _CRT_SECURE_NO_WARNINGS
#include <windows.h>
#include <stdio.h>
#include "../shared/minhook/minhook.h"
#include "../shared/utils.h"
#include "virusektriggertrace.h"

static BOOL HookOne(LPCWSTR module, LPCSTR name, LPVOID detour, LPVOID* original)
{
	MH_STATUS s = MH_CreateHookApi(module, name, detour, original);
	if (s != MH_OK)
	{
		log("[VirusekTriggerTrace] MH_CreateHookApi(%ls,%s) -> %d\n", module, name, (int)s);
		return FALSE;
	}
	return TRUE;
}

static HWND(WINAPI* FindWindowW_Orig)(LPCWSTR, LPCWSTR);
static HWND WINAPI FindWindowW_Trace(LPCWSTR c, LPCWSTR w)
{
	log("[VirusekTriggerTrace] FindWindowW class=%ls name=%ls\n", c ? c : L"(null)", w ? w : L"(null)");
	return FindWindowW_Orig(c, w);
}

static HWND(WINAPI* FindWindowExA_Orig)(HWND, HWND, LPCSTR, LPCSTR);
static HWND WINAPI FindWindowExA_Trace(HWND a, HWND b, LPCSTR c, LPCSTR w)
{
	log("[VirusekTriggerTrace] FindWindowExA parent=%p after=%p class=%s name=%s\n",
		(void*)a, (void*)b, c ? c : "(null)", w ? w : "(null)");
	return FindWindowExA_Orig(a, b, c, w);
}

static HWND(WINAPI* FindWindowExW_Orig)(HWND, HWND, LPCWSTR, LPCWSTR);
static HWND WINAPI FindWindowExW_Trace(HWND a, HWND b, LPCWSTR c, LPCWSTR w)
{
	log("[VirusekTriggerTrace] FindWindowExW parent=%p after=%p class=%ls name=%ls\n",
		(void*)a, (void*)b, c ? c : L"(null)", w ? w : L"(null)");
	return FindWindowExW_Orig(a, b, c, w);
}

static BOOL(WINAPI* EnumWindows_Orig)(WNDENUMPROC, LPARAM);
static BOOL WINAPI EnumWindows_Trace(WNDENUMPROC cb, LPARAM p)
{
	log("[VirusekTriggerTrace] EnumWindows proc=%p lParam=%08X\n", (void*)cb, (unsigned)p);
	return EnumWindows_Orig(cb, p);
}

static HWND(WINAPI* GetForegroundWindow_Orig)(void);
static HWND WINAPI GetForegroundWindow_Trace(void)
{
	HWND h = GetForegroundWindow_Orig();
	log("[VirusekTriggerTrace] GetForegroundWindow -> %p\n", (void*)h);
	return h;
}

static HWND(WINAPI* GetDesktopWindow_Orig)(void);
static HWND WINAPI GetDesktopWindow_Trace(void)
{
	HWND h = GetDesktopWindow_Orig();
	log("[VirusekTriggerTrace] GetDesktopWindow -> %p\n", (void*)h);
	return h;
}

static HWND(WINAPI* GetShellWindow_Orig)(void);
static HWND WINAPI GetShellWindow_Trace(void)
{
	HWND h = GetShellWindow_Orig();
	log("[VirusekTriggerTrace] GetShellWindow -> %p\n", (void*)h);
	return h;
}

static int(WINAPI* MessageBoxA_Orig)(HWND, LPCSTR, LPCSTR, UINT);
static int WINAPI MessageBoxA_Trace(HWND h, LPCSTR t, LPCSTR c, UINT type)
{
	log("[VirusekTriggerTrace] MessageBoxA hwnd=%p caption=\"%s\"\n", (void*)h, c ? c : "");
	return MessageBoxA_Orig(h, t, c, type);
}

static int(WINAPI* MessageBoxW_Orig)(HWND, LPCWSTR, LPCWSTR, UINT);
static int WINAPI MessageBoxW_Trace(HWND h, LPCWSTR t, LPCWSTR c, UINT type)
{
	log("[VirusekTriggerTrace] MessageBoxW hwnd=%p caption=%ls\n", (void*)h, c ? c : L"");
	return MessageBoxW_Orig(h, t, c, type);
}

static BOOL(WINAPI* SetForegroundWindow_Orig)(HWND);
static BOOL WINAPI SetForegroundWindow_Trace(HWND h)
{
	log("[VirusekTriggerTrace] SetForegroundWindow hwnd=%p\n", (void*)h);
	return SetForegroundWindow_Orig(h);
}

static BOOL(WINAPI* ShowWindow_Orig)(HWND, int);
static BOOL WINAPI ShowWindow_Trace(HWND h, int nCmdShow)
{
	log("[VirusekTriggerTrace] ShowWindow hwnd=%p nCmdShow=%d\n", (void*)h, nCmdShow);
	return ShowWindow_Orig(h, nCmdShow);
}

static HINSTANCE(WINAPI* ShellExecuteA_Orig)(HWND, LPCSTR, LPCSTR, LPCSTR, LPCSTR, INT);
static HINSTANCE WINAPI ShellExecuteA_Trace(HWND h, LPCSTR op, LPCSTR file, LPCSTR params, LPCSTR dir, INT show)
{
	log("[VirusekTriggerTrace] ShellExecuteA op=\"%s\" file=\"%s\"\n",
		op ? op : "(null)", file ? file : "(null)");
	return ShellExecuteA_Orig(h, op, file, params, dir, show);
}

bool InstallVirusekTriggerTraceHooks(Config& config)
{
	if (!config.GetBool("VirusekTriggerTrace", false))
		return true;

	log("[VirusekTriggerTrace] Installing diagnostic hooks (see logs for API hits; not exhaustive).\n");

	int ok = 0;
	int fail = 0;
#define TRY(mod, name, hook, orig) \
	do { \
		if (HookOne(mod, name, (LPVOID)&hook, (LPVOID*)&orig)) \
			ok++; \
		else \
			fail++; \
	} while (0)

	TRY(L"user32", "FindWindowW", FindWindowW_Trace, FindWindowW_Orig);
	TRY(L"user32", "FindWindowExA", FindWindowExA_Trace, FindWindowExA_Orig);
	TRY(L"user32", "FindWindowExW", FindWindowExW_Trace, FindWindowExW_Orig);
	TRY(L"user32", "EnumWindows", EnumWindows_Trace, EnumWindows_Orig);
	TRY(L"user32", "GetForegroundWindow", GetForegroundWindow_Trace, GetForegroundWindow_Orig);
	TRY(L"user32", "GetDesktopWindow", GetDesktopWindow_Trace, GetDesktopWindow_Orig);
	TRY(L"user32", "GetShellWindow", GetShellWindow_Trace, GetShellWindow_Orig);
	TRY(L"user32", "MessageBoxA", MessageBoxA_Trace, MessageBoxA_Orig);
	TRY(L"user32", "MessageBoxW", MessageBoxW_Trace, MessageBoxW_Orig);
	TRY(L"user32", "SetForegroundWindow", SetForegroundWindow_Trace, SetForegroundWindow_Orig);
	TRY(L"user32", "ShowWindow", ShowWindow_Trace, ShowWindow_Orig);
	TRY(L"shell32", "ShellExecuteA", ShellExecuteA_Trace, ShellExecuteA_Orig);

#undef TRY

	log("[VirusekTriggerTrace] Hook results: ok=%d failed=%d\n", ok, fail);
	return true;
}
