# SafeDisc integration (partial)

Upstream reference implementation: **[nckstwrt/SafeDiscLoader2](https://github.com/nckstwrt/SafeDiscLoader2)** (`src/`).

## Integrated in this repo

| Piece | Source file | Role |
|-------|-------------|------|
| `secdrv_ioctl.cpp` | `SafeDiscLoader2/src/secdrv_ioctl.cpp` | User-mode emulation of **secdrv** IOCTL `0xEF002407` via `NtDeviceIoControlFile` hook |
| SecDrv **CreateFile** | Same pattern as upstream `CheckForSecDrv` in `version.cpp` | Opens **`NUL`** when the game opens **`\\.\Secdrv`** / **`\\.\Global\SecDrv`** |

Enable with **`"SafeDiscSupport": true`** in `version.json` (next to the main `.exe`).

## Not merged (yet)

The full SafeDiscLoader2 **`version.cpp`** is ~2000 lines: **`LoadLibraryA`** hooks on temp DLLs (`~df394b.tmp`, AuthServ), CRC/key patches, and version-specific paths (**SafeDisc 2.6 / 2.7–2.8 / 3.x**). That logic is **not** duplicated here. Games that still fail after IOCTL + SecDrv stubs may need that layer — compare upstream **`Load()`** / **`LoadLibraryA_Hook`** or run their standalone **`version.dll`** for SafeDisc-only testing.

Optional reference sources to port next: `SafeDisc2Decrypt.cpp`, remainder of `version.cpp` hooks.
