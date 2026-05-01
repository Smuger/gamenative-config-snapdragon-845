# x86_dll

## Build

### CI (GitHub Actions)

On **tag push**, workflow [`.github/workflows/build-nfsug2-version-dll.yml`](../../.github/workflows/build-nfsug2-version-dll.yml) builds **Release Win32** (`SecuROMLoader.vcxproj`) and attaches **`version.dll`** and **`version.json`** to a **GitHub Release** for that tag (plus a workflow artifact). **Manual runs** (`workflow_dispatch`) build and upload the artifact only. Example: `git tag nfsug2-v1.0.0 && git push origin nfsug2-v1.0.0`.

### Local (Visual Studio)

1. Open `SecuROMLoader.sln` in Visual Studio (open the **folder containing** `SecuROMLoader.vcxproj`, so relative paths resolve).
2. Set configuration to **Release** and platform **x86** (maps to **Win32** in the project).
3. Build. Output is **`version.dll`** under `bin\Win32\Release\` (Release) next to the `.vcxproj`.
4. If the build fails on the toolset, edit `SecuROMLoader.vcxproj` and change `PlatformToolset` (`v143` → `v142`, etc.) to match what you have installed.

**Already in this tree:** sources under `version/`, `shared/`, `virusek/`, `shared/minhook/`, plus `version\version.def`. Nothing else is required in-repo for a normal MSVC link beyond the Windows SDK and C++ workload.

**Common first-build issues:** wrong platform (must be **x86**, not x64), missing Desktop development with C++, or `PlatformToolset` mismatch.

## Deploy (game folder)

1. Copy **`version.dll`** next to the game executable (e.g. **`speed2.exe`** for NFS Underground 2). The stock **`version.dll`** remains in `System32`; this proxy loads it from the resolved system path and forwards exports (`version\version.cpp`).
2. Config is loaded from **`version.json` in the same directory as the main `.exe`**. Copy the repo template **`../version.json`** (or merge keys) beside the game exe.

## Config: `version.json`

Resolved next to the **main executable** (see `securomloader.cpp` / `GetMainExecutableDirectory`).

**Bootstrap log:** On every load, **`version.loader.log`** is appended beside the main `.exe` with a timestamp, PID, exe path, and **`version.dll` path**. This does **not** depend on `version.json` or `logging`, so you can confirm the proxy ran even when config is missing or logging is off.

**JSON:** valid commas between properties; **keys** are case-sensitive (`tiny-json`).

| Key | Type | Used for |
|-----|------|------------|
| `logging` | bool | Console / file logging in `SecuROMLoader` |
| `logFile` | string | Log path; may substitute `ProcessID` (see `securomloader.cpp`) |
| `logCreateFile` | bool | Verbose `CreateFile` / attribute logging (default **true** if omitted) |
| `UseVirusekMethod` | bool | Hook `FindWindowA` + SecuROM scan (`virusekmethod.cpp`) |
| `VirusekProbeAtDllLoad` | bool | If **true**, runs `RunVirusekMethod()` once right after hooks enable (diagnostic; usually **no** fingerprint match until after unpack) |
| `VirusekTriggerTrace` | bool | If **true**, logs **`[VirusekTriggerTrace]`** lines for a fixed set of **user32** / **shell32** APIs (FindWindowW, FindWindowExA/W, EnumWindows, MessageBox*, ShowWindow, …) so you can pick an alternative trigger to `FindWindowA`. Not exhaustive; **ShowWindow** can be noisy. |
| `VirusekDiskTrace` | bool | If **true**, logs **`[VirusekDiskTrace]`** lines from **`GetDriveTypeA`/`W`** and **`GetVolumeInformationA`/`W`** with **`CDROMDriveLetter`** and **`matchesLetter`** (1 = path uses your spoofed CD letter). Grep-friendly (`grep VirusekDiskTrace`). |
| `VirusekTriggerEnumWindows` | bool | If **true** (with **`UseVirusekMethod`**), first **`EnumWindows`** call runs **`RunVirusekMethod`** once (shared global gate with other triggers). Enables **`EnumWindows`** hook even when **`VirusekTriggerTrace`** is false. |
| `VirusekTriggerFirstDriveTypeMatch` | bool | If **true**, first **`GetDriveTypeA`/`W`** whose path matches **`CDROMDriveLetter`** runs **`RunVirusekMethod`** once (same global gate). |
| `CDROMDriveLetter` | string | Spoofed disc letter (e.g. `F`) |
| `CDROMVolumeName` | string | Volume label for that letter |
| `fileMappings` | array of `{ "source", "target" }` | Path rewrites |
| `CPUCount` | int | `RestrictProcessors` |
| `GeometryCheckOneToZero` | bool | CRC / geometry (`crcfixer.cpp`) |
| `Override7C0` | string | Optional hex for `+7C0`-style checks |
| `exeFile` | string | Optional; only `TestConfig()` in `config.cpp` reads it today |
| `SafeDiscSupport` | bool | **SafeDisc:** emulate **secdrv** IOCTLs (`0xEF002407`, stub `0xCA002813`) and **`\\.\SecDrv` → NUL** (from [SafeDiscLoader2](https://github.com/nckstwrt/SafeDiscLoader2) `secdrv_ioctl` + `CheckForSecDrv` pattern). Does **not** include full `LoadLibraryA` temp-DLL patches — see `safedisc/README.md`. |

**Alternate Virusek triggers:** `FindWindowA` often never runs on Wine. Use **`VirusekTriggerEnumWindows`** and/or **`VirusekTriggerFirstDriveTypeMatch`** (see table). Only **one** run occurs per process across **`FindWindowA`**, **`EnumWindows`**, **`GetDriveType*`**, and **`VirusekProbeAtDllLoad`** (`TryRunVirusekMethodOnce`). Disable **`VirusekProbeAtDllLoad`** when testing alternate triggers so the probe does not consume the single run.

### NFS Underground 2

- **Install vs play disc:** In this project’s typical deployment (e.g. Wine / Android / a fixed drive letter for the game folder), the **install** often lives on **`A:\`** (e.g. `A:\speed2.exe` with **`version.dll`** and **`version.json` beside it). That is **not** the play disc. **`CDROMDriveLetter`** must still be the drive where **disc 2** is mounted (e.g. **`F`**) so **`bin.dat`**, volume checks, and locale DLLs resolve from **retail disc 2**—do **not** set `CDROMDriveLetter` to `A` just because the game is on `A:\` (that would spoof the install drive as a CD-ROM).
- **Wine / Proton:** the game often calls **`GetVolumeInformationW`** / **`GetDriveTypeW`** / **`CreateFileW`** instead of the `*A` APIs. This loader hooks **both** ANSI and Unicode variants so volume label spoofing (`CDROMVolumeName`) and the configured play-disc letter apply under Wine as well.

- Installer / disc layouts live under **`../iso1/`** (disc 1) and **`../iso2/`** (disc 2, includes `speed2.exe`).
- Template JSON in repo (same tree): **`../version.json`** — copy beside **`speed2.exe`** as **`version.json`** and tune `CDROMVolumeName` / mappings if your protection still checks drives.

## Runtime / behavior gaps (optional)

- **`ApplyCompatibilityPatches()`** is declared in `compatibility.h` but not called from `securomloader.cpp` today; add a call after config load if you want DPI / per-title patches.
- **`DllMain`** calls `Load()` directly on attach; heavy work under the loader lock can deadlock in some titles — a worker thread is safer if you hit that.
- **`deviceiocontrolhook.cpp`** forwards `NtDeviceIoControlFile` to the original; replace with real logic if you need IOCTL-level disc emulation.

## Attribution

Work in this directory is derived from **[nckstwrt / SecuROMLoader](https://github.com/nckstwrt/SecuROMLoader)**.

## Disclaimer

This code is not intended to promote piracy. Prefer buying and running original copies of the games you care about.
