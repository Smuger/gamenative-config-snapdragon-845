#define _CRT_SECURE_NO_WARNINGS
#include <windows.h>
#include <winternl.h>
#include "../shared/typedefs.h"
#include "../shared/config.h"
#include "deviceiocontrolhook.h"
#include "../safedisc/secdrv_ioctl.h"

extern Config config;
extern NtDeviceIoControlFile_typedef NtDeviceIoControlFile_Orig;

#ifndef STATUS_SUCCESS
#define STATUS_SUCCESS ((NTSTATUS)0x00000000L)
#endif
#ifndef STATUS_UNSUCCESSFUL
#define STATUS_UNSUCCESSFUL ((NTSTATUS)0xC0000001L)
#endif

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
	if (config.GetBool("SafeDiscSupport", false))
	{
		if (IoControlCode == 0xEF002407)
		{
			if (SafeDisc_ProcessMainIoctl(InputBuffer, InputBufferLength, OutputBuffer, OutputBufferLength))
			{
				IoStatusBlock->Information = OutputBufferLength;
				IoStatusBlock->Status = STATUS_SUCCESS;
				return IoStatusBlock->Status;
			}
			IoStatusBlock->Status = STATUS_UNSUCCESSFUL;
			return IoStatusBlock->Status;
		}
		if (IoControlCode == 0xCA002813)
		{
			IoStatusBlock->Status = STATUS_UNSUCCESSFUL;
			return IoStatusBlock->Status;
		}
	}

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
