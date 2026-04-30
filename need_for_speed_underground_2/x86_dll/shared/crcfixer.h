void CRCFixer(DWORD start = -1L, DWORD end = -1L, bool removeJNE = false, bool autoApplyPatches = true);
void ApplyPatches();
void ReversePatches();
void WritePatchDWORD(DWORD Addr, DWORD Value, bool reverse = false);
void WritePatchBYTE(DWORD Addr, BYTE Value, bool reverse = false);
void RestrictProcessors(int CPUs = 8);