### [Gothic 3](https://steamdb.info/app/39500/depots/) on Steam

### This tutorial may not work in a couple of months as the game gets updated on Steam

Gothic 3, downloaded from Steam, will not start on your device as of February 2026. The Steam version is very outdated and needs lots of patches

The following tutorial is the easiest way I found to install Union

**!! SUPER IMPORTANT !!**

If you know your language is missing. Install the language files before installing anything!

**!! SUPER IMPORTANT !!**

1. Before starting GameNative on your phone, download:
- [Union Plus](https://www.nexusmods.com/gothic3/mods/46) You will need a free NexusMods account to download this. This tool is good to have because you can check if the following patches are installed properly
- [Gothic_3_EE_Patch_v1.75.14_Int_Full.exe](https://www.worldofgothic.de/dl/download_478.htm)
- [Gothic_3_EE_v1.75_Int_Update_Pack_v1.04.11.exe](https://www.worldofgothic.de/dl/download_523.htm)
- [G3 UpdatePack v1.05.10 PublicBeta](https://forum.worldofplayers.de/forum/threads/1347969-Release-Gothic-3-v1-75-Update-Pack/page15?p=27014272#post27014272)
- [Gothic_3_Parallel_Universe_Patch_v1.1.1.exe](https://www.worldofgothic.de/dl/download_678.htm)
2. Gothic 2 runs fine on my device with the following config:
- Container Variant: **bionic**
- Wine Version: **proton-9.0-x86_64**
- Executable Path: **system/GothicMod.exe**
- Screen Size: **1280x720**
- Audio Driver: **PulseAudio**
- Graphic Driver: **Wrapper**
- Graphic Driver Version: **turnip26.0.0_R8**
- DX Wrapper: **2.7.1**
- Max Device Memory: **0 MB**
- Box64 Version: **0.4.0**
- Box64 Preset: **Performance**
- Only DirectSound: set to **Builtin (Wine)** the rest **Native (Windows)**
3. In GameNative click Open Container
4. Patches will not be in GameNative because games are installed in A:\ (Patches need game to be installed in a subdirectory e.g. A:\0\)
5. Go into `A:\` make a directory (call it 0 or something) then move all files from A:\ into that directory. Now your game is in `A:\0\Gothic3.exe`
6. Make sure no files are left in `A:\`
7. Install `Gothic_3_EE_Patch_v1.75.14_Int_Full.exe` into `A:\0\`
8. (Untick `Armor_Fix`) Install `Gothic_3_EE_v1.75_Int_Update_Pack_v1.04.11.exe` into `A:\0\`
9. Paste `G3 UpdatePack v1.05.10 PublicBeta` into `A:\0\`
10. Install `Gothic_3_Parallel_Universe_Patch_v1.1.1.exe` into `A:\0\`
11. Move files back from `A:\0\` to `A:\`
12. Now close the Container
13. In GameNative make sure that your Executable Path is `system/Gothic3.exe`

If you're missing your translation, please follow the DepotDownloader tutorial [GameNative may not pull your language correctly
](../README.md)