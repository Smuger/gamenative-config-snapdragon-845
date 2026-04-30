#include <windows.h>
#include <winternl.h>
#include "../shared/typedefs.h"
#include "deviceiocontrolhook.h"

extern NtDeviceIoControlFile_typedef NtDeviceIoControlFile_Orig;

NTSTATUS WINAPI NtDeviceIoControlFile_Hook(
	HANDLE FileHandle,
	HANDLE Event,
	PIO_APC_ROUTINE ApcRoutine,
	PVOID ApcContext,
	PIO_STATUS_BLOCK IoStatusBlock,
	ULONG IoControlCode,
	PVOID InputBuffer,
	ULONG InputBufferLength,
	PVOID OutputBuffer,
	ULONG OutputBufferLength)
{
	return NtDeviceIoControlFile_Orig(
		FileHandle,
		Event,
		ApcRoutine,
		ApcContext,
		IoStatusBlock,
		IoControlCode,
		InputBuffer,
		InputBufferLength,
		OutputBuffer,
		OutputBufferLength);
}
