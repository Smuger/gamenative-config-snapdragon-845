### [Gothic 3](https://steamdb.info/app/39500/depots/) on Steam

Make sure you are running [GameNative](https://github.com/utkarshdalal/GameNative/releases) version >= 0.9.0 
Otherwise languages downloaded from steam will not overwrite each other correctly

### This tutorial may not work in a couple of months as the game gets updated on Steam

Gothic 3, downloaded from Steam, will not start on your device as of February 2026. The Steam version is very outdated and needs lots of patches

The following tutorial is the easiest way I found to install Union

**!! SUPER IMPORTANT !!**

If you know your language is missing, drop the localisation files in your game directory before anything else!

**!! SUPER IMPORTANT !!**

1. Before starting GameNative on your phone, download:
- [Union Plus](https://www.nexusmods.com/gothic3/mods/46) You will need a free NexusMods account to download this. This tool is good to have because you can check if the following patches are installed properly
- [Gothic_3_EE_Patch_v1.75.14_Int_Full.exe](https://www.worldofgothic.de/dl/download_478.htm)
- [Gothic_3_EE_v1.75_Int_Update_Pack_v1.04.11.exe](https://www.worldofgothic.de/dl/download_523.htm)
- [G3 UpdatePack v1.05.10 PublicBeta](https://forum.worldofplayers.de/forum/threads/1347969-Release-Gothic-3-v1-75-Update-Pack/page15?p=27014272#post27014272)
- [Gothic_3_Parallel_Universe_Patch_v1.1.1.exe](https://www.worldofgothic.de/dl/download_678.htm)
2. Gothic 2 runs fine on my device with the following config:
- Container Variant: **bionic**
- Wine Version: **proton-10.0-4_x86_64** [My custom Proton](https://github.com/Smuger/proton-wine/releases/tag/build-20260313-1)
- Executable Path: **system/GothicMod.exe**
- Screen Size: **1280x720**
- Audio Driver: **PulseAudio**
- Graphic Driver: **Wrapper**
- Graphic Driver Version: **turnip26.0.0_R8**
- DX Wrapper: **2.6.2-0**
- Max Device Memory: **0 MB**
- Box64 Version: **0.4.0**
- Box64 Preset: **Intermediate**
- Only DirectSound: set to **Builtin (Wine)** the rest **Native (Windows)**
3. In GameNative click Open Container
4. Make sure no files are left in `C:\users\xuser\Documents\gothic3`
5. Install `Gothic_3_EE_Patch_v1.75.14_Int_Full.exe`
6. (Untick `Armor_Fix`) Install `Gothic_3_EE_v1.75_Int_Update_Pack_v1.04.11.exe`
7. Paste `G3 UpdatePack v1.05.10 PublicBeta` game directory
8. Install `Gothic_3_Parallel_Universe_Patch_v1.1.1.exe`
9. Now close the Container
10. In GameNative make sure that your Executable Path is `Gothic3.exe`

If you're missing your translation, please follow the DepotDownloader tutorial [GameNative may not pull your language correctly
](../README.md)