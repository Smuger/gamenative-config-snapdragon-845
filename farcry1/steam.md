### [Far Cry 1](https://steamdb.info/app/13520/depots/) on Steam

### This tutorial may not work in a couple of months as the game gets updated on Steam

Far Cry 1, downloaded from Steam, will not start on your device as of April 2026. The Steam version is very outdated and needs lots of patches

The following tutorial is the easiest way I found to install Union

**!! SUPER IMPORTANT !!**

If you know your language is missing, drop the localisation files in your game directory before anything else!

**!! SUPER IMPORTANT !!**

1. Before starting GameNative on your phone, download:
- [Far Cry 1 x64](https://www.moddb.com/games/far-cry/downloads/far-cry-fix-64-bit)
- [.Reg fix](https://github.com/Smuger/gamenative-config-snapdragon-845/blob/main/farcry1/fix_msvcr71.reg)
2. Far Cry 1 runs fine on my device with the following config:
- Container Variant: **bionic**
- Wine Version: **proton-10.0-4_x86_64** [My custom Proton](https://github.com/Smuger/proton-wine/releases/tag/build-20260313-1)
- Screen Size: **960x540**
- Audio Driver: **PulseAudio**
- Graphic Driver: **Wrapper**
- Graphic Driver Version: **turnip26.0.0_R8**
- DX Wrapper: **2.7.1**
- Max Device Memory: **0 MB**
- Box64 Version: **0.4.0**
- Box64 Preset: **Performance**
- Only DirectSound: set to **Builtin (Wine)** the rest **Native (Windows)**
3. In GameNative click Open Container
4. Unpack downloaded x64 patch in game root `A:\`
5. Install **fix_msvcr71.reg** by double clicking on it
6. Now close the Container
7. In GameNative make sure that your Executable Path is `Bin64`

If you're missing your translation, please follow the DepotDownloader tutorial [GameNative may not pull your language correctly
](../README.md)