# x86_dll

## Build

### CI (GitHub Actions)

On **tag push**, workflow [`.github/workflows/build-nfsug2-version-dll.yml`](../../.github/workflows/build-nfsug2-version-dll.yml) builds **Release Win32** with **MSBuild** (`microsoft/setup-msbuild`) and attaches **`version.dll`** to a **GitHub Release** for that tag (plus a workflow artifact). **Manual runs** (`workflow_dispatch`) build and upload the artifact only. Example: `git tag nfsug2-v1.0.0 && git push origin nfsug2-v1.0.0`.

### Local (Visual Studio)

1. Open `SecuROMLoader.sln` in Visual Studio (open the **folder containing** `SecuROMLoader.vcxproj`, so relative paths resolve).
2. Set configuration to **Release** and platform **x86** (maps to **Win32** in the project).
3. Build. Output is **`version.dll`** (`TargetName` in `SecuROMLoader.vcxproj`), under something like `Release\` or `Debug\` next to the `.vcxproj`, depending on VS defaults.
4. If the build fails on the toolset, edit `SecuROMLoader.vcxproj` and change `PlatformToolset` (`v143` → `v142`, etc.) to match what you have installed.

**Already in this tree:** sources under `version/`, `shared/`, `virusek/`, `shared/minhook/`, plus `version\version.def`. Nothing else is required in-repo for a normal MSVC link beyond the Windows SDK and C++ workload.

**Common first-build issues:** wrong platform (must be **x86**, not x64), missing Desktop development with C++, or `PlatformToolset` mismatch.

## Deploy (game folder)

1. Copy **`version.dll`** next to the game executable that will load the proxy (same layout as upstream SecuROMLoader for your target title).
2. The loader calls `config.LoadConfig("version.json")` — filename is fixed. Copy the repo template **`need_for_speed_underground_2/nfs-underground-2.version.json`** into the **same directory as the game `.exe`** and rename it to **`version.json`** (or merge its keys into an existing `version.json`).
3. Keep the real Microsoft **`version.dll`** in `System32`; this project’s DLL forwards to it after resolving the system path (see `version\version.cpp`).

## Config: `version.json`

Loaded from the **process current directory** (typically the game’s install folder when you start the `.exe` from Explorer).

**JSON:** valid commas between properties; **keys** are case-sensitive (`tiny-json`).

| Key | Type | Used for |
|-----|------|------------|
| `logging` | bool | Console / file logging in `SecuROMLoader` |
| `logFile` | string | Log path; may substitute `ProcessID` (see `securomloader.cpp`) |
| `logCreateFile` | bool | Verbose `CreateFile` / attribute logging |
| `UseVirusekMethod` | bool | Hook `FindWindowA` + SecuROM scan (`virusekmethod.cpp`) |
| `CDROMDriveLetter` | string | Spoofed disc letter (e.g. `F`) |
| `CDROMVolumeName` | string | Volume label for that letter |
| `fileMappings` | array of `{ "source", "target" }` | Path rewrites |
| `CPUCount` | int | `RestrictProcessors` |
| `GeometryCheckOneToZero` | bool | CRC / geometry (`crcfixer.cpp`) |
| `Override7C0` | string | Optional hex for `+7C0`-style checks |
| `exeFile` | string | Optional; only `TestConfig()` in `config.cpp` reads it today |

### NFS Underground 2

- Installer / disc layouts live under **`../iso1/`** (disc 1) and **`../iso2/`** (disc 2, includes `speed2.exe`).
- Template JSON: **`../nfs-underground-2.version.json`** — copy/rename to **`version.json`** beside the installed `speed2.exe` and tune `CDROMVolumeName` / mappings if your protection still checks drives.

## Runtime / behavior gaps (optional)

- **`ApplyCompatibilityPatches()`** is declared in `compatibility.h` but not called from `securomloader.cpp` today; add a call after config load if you want DPI / per-title patches.
- **`DllMain`** calls `Load()` directly on attach; heavy work under the loader lock can deadlock in some titles — a worker thread is safer if you hit that.
- **`deviceiocontrolhook.cpp`** forwards `NtDeviceIoControlFile` to the original; replace with real logic if you need IOCTL-level disc emulation.

## Attribution

Work in this directory is derived from **[nckstwrt / SecuROMLoader](https://github.com/nckstwrt/SecuROMLoader)**.

## Disclaimer

This code is not intended to promote piracy. Prefer buying and running original copies of the games you care about.
