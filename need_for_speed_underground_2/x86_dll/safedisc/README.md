# SafeDisc integration

Reference implementation: **[nckstwrt/SafeDiscLoader2](https://github.com/nckstwrt/SafeDiscLoader2)** (`src/`).

**SecuROM / Virusek** hooks are not in this folder — see **`../virusek/README.md`** (`securom7_hooks`, `virusekmethod`, `trigger_trace`).

## Files in this folder

| File | Role |
|------|------|
| `secdrv_ioctl.cpp` / `secdrv_ioctl.h` | User-mode emulation of **secdrv** IOCTL `0xEF002407` via `NtDeviceIoControlFile` hook |
| `version_loader.cpp` | Merged SafeDiscLoader2 **`version.cpp`**: hooks (`LoadLibraryA`, temp DLLs, CRC paths, CreateFile SecDrv → NUL, etc.) |
| `safedisc2_decrypt.cpp` | SafeDisc decryption helpers used by the loader |
| `memhack.h` | Memory search / patch helpers used by `version_loader.cpp` |
| `ioctl_codes.h` | IOCTL constants (reference; extend if you wire more device paths) |

Enable **`"SafeDiscSupport": true`** in `version.json` (next to the main `.exe`).

## Need for Speed Underground 2 (upstream note)

[SafeDiscLoader2’s tested-games list](https://github.com/nckstwrt/SafeDiscLoader2/blob/main/README.md) records NFS UG2 as **SafeDisc 3.05.10** with a **missing normal version string**, and adds that the game **still needs CD 2** for a **non–SafeDisc check**: it **looks for `bin.dat` from the disc**. That is the important content requirement—mount **disc 2** (or an equivalent image) so that path resolves; **SafeDiscLoader2 does not say you must place `SD0409.dll` next to `speed2.exe`.**

**Typical layout:** the game may be installed on **`A:\`** while **disc 2** is **`F:\`** (or another letter). **`CDROMDriveLetter`** is only for the **play disc**, not the install drive.

## Locale DLLs (`SD*.dll`)

SafeDisc may **`LoadLibrary`** bare names like **`SD0409.dll`**. Those files are part of the **retail disc layout** (often the CD root), not something you are expected to ship beside the exe. With **`"SafeDiscSupport": true`**, this project retries **`exeDir\SD0409.dll`** then **`CDROMDriveLetter:\SD0409.dll`** (and related **`CreateFile`** redirects in **`version_loader.cpp`**) so a **properly mounted disc or ISO** at the configured letter matches what the original installer media provided—no separate “copy locale DLL next to the game” step is required if **`CDROMDriveLetter`** points at that volume.

## What this does (short)

- Intercepts **Windows API** calls in the **game process** (MinHook) so old SafeDisc-protected games can run without the real `secdrv` driver.
- Fakes **secdrv I/O control** requests the game sends via `NtDeviceIoControlFile` with **in-process math and buffer fill** (no driver, no network).
- Redirects opens of **`\\.\Secdrv`** to a **local dummy handle** (`NUL` / emulated open) so the game stops looking for a kernel driver.
- May **patch game code in RAM** (decrypt tables, CD-check hooks) using addresses in the **loaded game executable and its DLLs** only.
- Optional **`CreateProcess` → inject** path loads **this same `version.dll` from disk** into a child process (local path from `GetModuleFileName`); it does not fetch binaries from the internet.
- **Locale DLLs** (`SD0409.dll`, etc.): bare-name resolution is extended to **`CDROMDriveLetter`** (and optionally exe dir) so it matches **retail disc layout** when the play disc is mounted—same as normal `LoadLibrary` once paths resolve, not a downloader.

## Security / network

- There is **no** use of HTTP/HTTPS clients, sockets, `URLDownloadToFile`, `WinINet`, or similar in this folder: nothing here **downloads** or **phones home**.
- The only `https://` strings are **comments** and this README (attribution). Redump is mentioned in a **comment** in `version_loader.cpp` only.
- **`SDLoader.dll`**: in `version_loader.cpp`, loading it is wrapped in **`#ifdef USE_SDLOADER`**, and `USE_SDLOADER` is **not** defined in the project, so that code is **not compiled** unless you change the build. It would only load a **file already on disk** next to the game, not from the network.

**Caveat:** This is still a **game crack / compatibility shim** (bypasses DRM). It is “safe” in the sense of **no embedded network exfiltration or auto-downloads** in this source tree; it is not a security product, and it **patches and hooks** a running process, so use only with software you are allowed to modify.
