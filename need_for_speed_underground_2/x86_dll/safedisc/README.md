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

## SafeDisc 3 “single-file” architecture (late-era static linking)

By the **SafeDisc 3** era (~2004 onward), many titles **stopped relying on a separate SafeDisc helper DLL** on disc. Instead, the **protection shim**, **decryption**, and a **VM-style** execution layer are **linked into the main `.exe`**: one large “container” executable whose entry/stub unpacks or decrypts the real game body and talks to **`secdrv.sys`** for drive/sectors/key material.

In this repo, **`secdrv_ioctl.cpp`** + **`NtDeviceIoControlFile`** hooks in **`version_loader.cpp`** approximate what the real kernel driver did, so the game can run **without** installing **`secdrv`** on modern Windows or under Wine.

### Identifying SafeDisc in the binary

References often cite the full ASCII chain **`BoG_ *90.0&!! Yy>`** as a fingerprint. In **later revisions of SafeDisc 3.05.10**, Macrovision **obfuscated** that footprint: the **`BoG_`** prefix may remain visible, while the rest is **XOR’d, shifted, or folded** so simple string scanners and early automated tools no longer see one contiguous plaintext “flag.”

For **`need_for_speed_underground_2/speed2.exe`** (about **5.7 MB** on disk—typical of a fat protected wrapper):

| Observation | Meaning |
|----------------|--------|
| **`BoG_`** at offset **`0xFFC`** | Strong SafeDisc marker |
| **No** contiguous **`BoG_ *90.0&!! Yy>`** in cleartext | Consistent with **newer 3.05.10 builds** that hide the tail of the signature |
| Bytes **after** **`BoG_`** are opaque | Not a readable global **`3.05.10`** text block next to the marker |

### PE sections and the “envelope” (`speed2.exe` sample)

Ballpark geometry: unprotected game code for a title like NFS UG2 is often on the order of **~3 MB**; a **~5.7 MB** exe leaves **multiple megabytes** of extra PE bulk—the **SafeDisc envelope** (stub, VM tables, encrypted payloads), not a separate **`SD0409.dll`** on disk.

Inspected **in-repo** `speed2.exe` (7 sections). Notable names:

| Section | Virtual size (approx.) | Notes |
|---------|-------------------------|--------|
| **`.text`** | ~3.5 MB | Dominant section; **Shannon entropy ~8.0** on raw bytes in this sample—typical of **heavy mixing** of code, encrypted blobs, and padding. |
| **`.rdata`**, **`.data`** | large | **`.data`** also shows **very high entropy** here—consistent with encrypted or opaque runtime state, not only plain RW globals. |
| **`.rsrc`** | ~230 KB | Lower entropy (~3.2 here)—**resources** and metadata still tend to look structured. Version branding may live here or only appear **after** stub decryption. |
| **`stxt774`**, **`stxt371`** | small | **SafeDisc-style** auxiliary sections (same family as historic **`.stext` / `.sdata`** naming). |
| **8× space** (`"        "`) | ~240 KB | **Non-standard / obfuscated** section name—also seen when vendors hide intent from PE viewers. |

Tools such as **PE-browse**, **CFF Explorer**, or a hex + PE header parse can reproduce the above. **Entropy ~8.0** on a section’s bytes usually means **compressed or encrypted bulk**, i.e. where inlined protection logic and tables often live.

### Why the loader’s “version string” scan differs

For **3.05.10**, the literal text **`3.05.10`** is often **not** a single global ASCII string beside **`BoG_`**. It may be stored in **resources**, **split across initialization**, or **encoded** in the stub. That is why **SafeDiscLoader2-style** code searches for **multiple patterns** (e.g. **`Version String`** and **`Version String v2`** in **`version_loader.cpp`**): the **protection version** and the **marketing build** string are discovered indirectly.

### Execution model (conceptual)

Think of a **nested** flow: **outer PE entry** runs the SafeDisc **stub** → sets up the **VM / interpreter** → validates **`secdrv`** (real hardware path) or equivalent IOCTL traffic → derives keys (historically tied to **weak / fingerprint sectors** on pressed discs) → **decrypts** the real game image in memory → transfers control to the **actual game entry**. This repo does **not** reimplement the vendor VM; it **hooks** APIs and **emulates** enough **`secdrv`** behavior for the title to proceed on modern systems.

### Intended behaviour (same idea as [SafeDiscLoader2](https://github.com/nckstwrt/SafeDiscLoader2))

The loader does **not** “replace” a missing **`SD0409.dll`** file on disk. It intercepts what **inlined SafeDisc code inside `speed2.exe`** does at runtime: that blob eventually talks to the OS the same way the old standalone stack would have—**device IOCTLs**, **`CreateFile`**, drive queries, etc. The proxy **`version.dll`** sits in the middle and **answers** those calls so the container can finish its checks and decrypt/run the game.

1. **Entry / DLL load ([upstream `dllmain.cpp`](https://github.com/nckstwrt/SafeDiscLoader2/blob/main/src/dllmain.cpp)).**  
   **`speed2.exe`** pulls in **`version.dll`** early (application-directory DLL search order for the **`version`** API set). Our **`version/dllmain.cpp`** calls **`Load`** on attach (same pattern as SDL2), which loads system **`version.dll`** for forwarded exports and runs **`SecuROMLoader`** so **MinHook** can install before most disc/driver checks.

2. **Intercepting driver-style IOCTL traffic (the important MitM).**  
   Embedded SafeDisc logic still reaches toward **`secdrv.sys`** via the normal Win32/NT stack. User-mode **`DeviceIoControl`** ultimately goes through **`NtDeviceIoControlFile`** in **`ntdll.dll`**. This project hooks **`NtDeviceIoControlFile`** in **`version_loader.cpp`** and handles recognized **control codes** in **`secdrv_ioctl.cpp`**: when the open handle corresponds to the SafeDisc driver path, **instead of failing** with no kernel driver, the hook can set **`STATUS_SUCCESS`** (and fill **output buffers**) so the inlined logic gets the **responses** it expects from a real **`secdrv`** handshake (e.g. weak-sector / geometry style payloads where implemented).

3. **Other APIs.**  
   Hooks on **`CreateFile`**, **`LoadLibrary`**, **`GetDriveType`**, **`GetVolumeInformation`**, etc. cover **`\\.\SecDrv` → `NUL`**, **`LoadLibrary`** retries for **system** DLLs when SafeDisc unpack dirs use wrong paths, and **`CDROMDriveLetter`** / **`CDROMVolumeName`** from **`version.json`**. There is **no** special-case resolution for bare-name **`SD*.dll`** files—the inlined container does not rely on this loader to supply them. These are **export-level** hooks (MinHook), not a separate “IAT scanner.”

4. **Why the loader source rarely mentions `SD0409.dll`.**  
   The filename is a **toolchain / probe** detail. What matters is **which syscalls and IOCTLs** the embedded **container** issues. The loader waits for that traffic—especially **`NtDeviceIoControlFile`** with SafeDisc-related codes—and supplies the **echo** (success **NTSTATUS**, buffers, opens) so the DRM thinks the driver/disc path validated.

5. **`bin.dat` (NFS UG2).**  
   After SafeDisc-style IOCTL paths, the **game** may still **`CreateFile`** **`bin.dat`**. Configure **`CDROMDriveLetter`** (and optional **`fileMappings`**) so that path resolves to **real** mounted content unless you deliberately remap it.

### Reference: “textbook” SafeDiscLoader2 MitM (what many write-ups describe)

In a **stock** Windows install, **`LoadLibraryA("SD0409.dll")`** usually returns **NULL** (no file), and **`CreateFile`** for disc-only paths fails without media. Tutorials for **[SafeDiscLoader2](https://github.com/nckstwrt/SafeDiscLoader2)** often summarize the loader as a **guard at the edge** of **`kernel32`/`ntdll`** exports: DRM calls never hit the real kernel unchanged.

| Idea | Typical story |
|------|----------------|
| **`LoadLibrary` spoof** | Some builds might treat **`SD0409.dll`** / **`secdrv`** names specially and return a **non-null module** (e.g. self-module / exe) so legacy probes don’t see failure. |
| **`CreateFile` / `bin.dat`** | Some forks sketch **`CreateFile`** hooks that detect **`bin.dat`** and return a **dummy handle** or redirect to a local file instead of **`NOT_FOUND`**. |
| **`DeviceIoControl` / driver** | DRM talks to **`\\.\SecDrv`** / **`secdrv.sys`**. On modern Windows the driver is gone; loaders **short-circuit** IOCTL paths and **fill output buffers** with success-shaped data so the embedded logic thinks the driver replied. |
| **`version.dll` proxy** | The fake **`version.dll`** forwards **`GetFileVersionInfo*`** etc. to **`%SystemRoot%\System32\version.dll`** so normal imports keep working while hooks run. |

Under the hood, **`DeviceIoControl`** in user mode typically ends up in **`NtDeviceIoControlFile`**; implementations often hook **that** **NTSTATUS** path rather than returning raw **`BOOL`** from **`DeviceIoControl`** directly.

### This fork (`version_loader.cpp`) — what actually ships here

| Topic | Behavior in **this** tree |
|-------|----------------------------|
| **`LoadLibrary` / `SD0409.dll`** | **No** fake **`HMODULE`** for bare **`SD0409.dll`**. **`LoadLibrary`** hooks only help **system DLLs** when SafeDisc unpack dirs reference **`kernel32`/`user32`** by wrong paths (temp-folder retry). |
| **`CreateFile` / `bin.dat`** | **No** built-in “open dummy **`bin.dat`**” stub. **`CreateFile`** hooks handle **`\\.\SecDrv`**, **`fileMappings`**, and **`\\.\X:` → NUL** for the configured CD letter; use a **mounted image** or **`fileMappings`** so **`bin.dat`** opens if the game requires it. |
| **IOCTL / `secdrv`** | **`NtDeviceIoControlFile`** hook + **`secdrv_ioctl.cpp`**: recognized SafeDisc IOCTLs get **`STATUS_SUCCESS`** and filled buffers where implemented — this is the main driver handshake MitM. |
| **`version.dll` proxy** | **`version/version.cpp`** loads system **`version.dll`** and forwards exports — same proxy idea as upstream. |

### Disc handshake vs inlined code

Even when **all** SafeDisc **logic** lives in **`speed2.exe`**, retail **disc 2** can still participate in checks:

- **`bin.dat`**: file-level / layout checks (see upstream NFS UG2 note below).
- **Physical-media quirks**: original pressed discs used **intentional weak / ambiguous reads** in certain sector ranges; consumer drives report outcomes that **ISO / virtual drives** do not replicate bit-for-bit. Loaders therefore combine **`secdrv`** IOCTL emulation, **`CDROMDriveLetter`** spoofing, and **in-memory patches** so the title does not depend on a real **`secdrv`** driver or a perfect optical simulation.

This project **does not** claim to emulate **every** low-level optical edge case—only what the hooked **`secdrv`** path and game code require in practice.

## Need for Speed Underground 2 (upstream note)

[SafeDiscLoader2’s tested-games list](https://github.com/nckstwrt/SafeDiscLoader2/blob/main/README.md) records NFS UG2 as **SafeDisc 3.05.10** with a **missing normal version string**, and adds that the game **still needs CD 2** for a **non–SafeDisc check**: it **looks for `bin.dat` from the disc**. That is the important content requirement—mount **disc 2** (or an equivalent image) so that path resolves; **SafeDiscLoader2 does not say you must place `SD0409.dll` next to `speed2.exe`.**

**Typical layout:** the game may be installed on **`A:\`** while **disc 2** is **`F:\`** (or another letter). **`CDROMDriveLetter`** is only for the **play disc**, not the install drive.

## What `SD0409.dll` means in SafeDisc (often **not** a real file)

Names like **`SD0409.dll`**, **`SD0401.dll`**, or legacy **`dplayerx.dll`** are **version / locale slot identifiers** in the SafeDisc toolchain—not proof that a standalone DLL exists next to the game.

For **SafeDisc 3.x**, Macrovision often **stopped shipping** a separate locale DLL and instead **embedded** the protection logic (encrypted blobs, VM bytecode, checks) **inside the main executable**. You still see **`BoG_`** (ASCII) near the stub/version area of the PE; you often **do not** see a cleartext **`SD0409.dll`** string in that same exe.

During startup, code unpacked into **temp modules** (e.g. AuthServ / SecServ in `~e5…` dirs) may still call **`CreateFile`** / **`LoadLibrary`** on the **canonical name** `SD0409.dll` as a **probe**: success if an optional external package exists; **failure (`INVALID_HANDLE_VALUE`)** is **normal** when protection is fully inlined—there is nothing on disc to mount.

### Checked in-repo: `need_for_speed_underground_2/speed2.exe`

| Check | Result |
|--------|--------|
| ASCII **`BoG_`** (SafeDisc marker) | **Present** (e.g. offset `0xFFC` in this build) |
| Cleartext **`SD0409`**, **`SD0401`**, **`dplayerx`**, **`.icd`** | **Not present** as literal strings in the main exe |

So treating **`CreateFile` … `SD0409.dll` … `FFFFFFFF`** as “you must find that file on the CD” is **wrong** for this title: the log line reflects the runtime probe, not a missing retail file.

**`bin.dat`** on disc 2 (NFS UG2) remains a **separate** game check—configure **`CDROMDriveLetter`** / **`fileMappings`** so that path resolves when needed.

## What this does (short)

- Intercepts **Windows API** calls in the **game process** (MinHook) so old SafeDisc-protected games can run without the real `secdrv` driver.
- Fakes **secdrv I/O control** requests the game sends via `NtDeviceIoControlFile` with **in-process math and buffer fill** (no driver, no network).
- Redirects opens of **`\\.\Secdrv`** to a **local dummy handle** (`NUL` / emulated open) so the game stops looking for a kernel driver.
- May **patch game code in RAM** (decrypt tables, CD-check hooks) using addresses in the **loaded game executable and its DLLs** only.
- Optional **`CreateProcess` → inject** path loads **this same `version.dll` from disk** into a child process (local path from `GetModuleFileName`); it does not fetch binaries from the internet.

## Security / network

- There is **no** use of HTTP/HTTPS clients, sockets, `URLDownloadToFile`, `WinINet`, or similar in this folder: nothing here **downloads** or **phones home**.
- The only `https://` strings are **comments** and this README (attribution). Redump is mentioned in a **comment** in `version_loader.cpp` only.
- **`SDLoader.dll`**: in `version_loader.cpp`, loading it is wrapped in **`#ifdef USE_SDLOADER`**, and `USE_SDLOADER` is **not** defined in the project, so that code is **not compiled** unless you change the build. It would only load a **file already on disk** next to the game, not from the network.

**Caveat:** This is still a **game crack / compatibility shim** (bypasses DRM). It is “safe” in the sense of **no embedded network exfiltration or auto-downloads** in this source tree; it is not a security product, and it **patches and hooks** a running process, so use only with software you are allowed to modify.
