# SecuROM 7 / Virusek layer

This folder holds **SecuROM**-oriented code (including **SecuROM 7**-style bypass paths) and the **Virusek** in-memory method used when **`UseVirusekMethod`** is enabled in `version.json`.

| File | Role |
|------|------|
| `virusekmethod.cpp` / `virusekmethod.h` | Virusek scan/patch (`VirtualQuery` walk, **`FindWindowA`** one-shot trigger, optional **`RestrictProcessors`**) |
| `securom7_hooks.cpp` / `securom7_hooks.h` | **`SecuRom7_RegisterHooks()`**: SecuROM SMS **`OpenFileMappingW`**, CD spoofing (**`GetDriveTypeW`**, **`GetVolumeInformationW`**), **`GetFileAttributes`**, **`IsBadReadPtr`**, **`KiUserExceptionDispatcher` / `NtContinue`** HWBP path + **`CRCFixer`**, optional **`FindWindowA`** registration when Virusek is on |
| `trigger_trace.cpp` / `trigger_trace.h` | Optional UI/API tracing hooks when **`VirusekTriggerTrace`** is set |

**SafeDisc-only** logic (`secdrv` IOCTL, `LoadLibraryA` temp DLLs, decrypt tables) lives in **`../safedisc/`**. The main loader (`safedisc/version_loader.cpp`) calls **`SecuRom7_RegisterHooks()`** after installing SafeDisc hooks so both stacks share one **`MH_EnableHook(MH_ALL_HOOKS)`** pass.
