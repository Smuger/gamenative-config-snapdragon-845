#pragma once
#include <windows.h>
#include "../shared/minhook/minhook.h"
#include "../shared/utils.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

bool ByteSearch(const BYTE* data, const BYTE* pattern, const bool* wildcard, int patternSize)
{
	bool matched = true;
	for (int i = 0; i < patternSize; i++)
	{
		if (wildcard && wildcard[i])
			continue;
		if (data[i] != pattern[i])
		{
			matched = false;
			break;
		}
	}
	return matched;
}

BYTE* ByteSearch(BYTE* data, const int dataSize, const BYTE* pattern, const bool* wildcard, int patternSize)
{
	BYTE* ret = NULL;

	for (int i = 0; i < dataSize-patternSize; i++)
	{
		if (ByteSearch(data + i, pattern, wildcard, patternSize))
		{
			ret = data + i;
			break;
		}
	}

	return ret;
}

BYTE* ByteSearch(BYTE* data, const int dataSize, const char* szPattern)
{
	int patternSize = (int)((strlen(szPattern) + 1) / 3);
	char* szPatternDupe = _strdup(szPattern);
	char* strPtr = szPatternDupe;
	BYTE* pattern = new BYTE[patternSize]();
	bool* wildcard = new bool[patternSize]();
	for (int i = 0; i < patternSize; i++)
	{
		strPtr[2] = 0;
		if (_stricmp(strPtr, "??") == 0)
			wildcard[i] = true;
		else
			pattern[i] = (BYTE)strtol(strPtr, NULL, 16);
		strPtr += 3;
	}

	BYTE* ret = ByteSearch(data, dataSize, pattern, wildcard, patternSize);

	free(szPatternDupe);
	delete[] pattern;
	delete[] wildcard;

	return ret;
}

bool CreateMinHook(LPVOID pTarget, LPVOID pDetour, LPVOID* result, bool enabled = true)
{
	MH_STATUS status = MH_Initialize();

	if (status != MH_OK && status != MH_ERROR_ALREADY_INITIALIZED)
		return false;

	if ((status = MH_CreateHook(pTarget, pDetour, result)) != MH_OK)
	{
		printf("MH_CreateHook Failed = %d\n", status);
		return (status == MH_OK);
	}

	if (enabled)
		status = MH_EnableHook(pTarget);

	return (status == MH_OK);
}

void DumpToFile(const char* szFilename, BYTE* data, int dataSize)
{
	FILE* fout = fopen(szFilename, "wb");
	if (fout)
	{
		fwrite(data, 1, dataSize, fout);
		fclose(fout);
	}
	else
		printf("Could not DumpToFile: %s\n", szFilename);
}
