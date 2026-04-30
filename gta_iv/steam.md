### [GTA IV](https://steamdb.info/depot/12213/) on Steam

### This tutorial may not work in a couple of months as the game gets updated on Steam

GTA IV, downloaded from Steam, will not start on your device as of February 2026. The Steam version requires **Rockstar Game Launcher** to work which I've never seen running in GameNative 

**!! SUPER IMPORTANT !!**

If you know your language is missing, drop the localisation files in your game directory before anything else!

**!! SUPER IMPORTANT !!**

1. Before starting GameNative on your phone, download:
- [GTAIVDowngrader by ClonkAndre](https://github.com/ClonkAndre/GTAIVDowngrader/releases)
- [VisualCppRedist-AIO](https://github.com/vonsilke/VisualCppRedist-AIO/releases)
- [XLivelessAddon](https://github.com/GTAmodding/XLivelessAddon/releases)
- [FusionFix](https://github.com/ThirteenAG/GTAIV.EFLC.FusionFix/releases)
- [FusionFixLegacyAddon](https://github.com/ThirteenAG/GTAIV.EFLC.FusionFix/releases/latest/download/GTAIV.EFLC.FusionFixLegacyAddon.zip)

2. GTA IV runs fine on my device with the following config:
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
4. Unpack GTAIVDowngrader and run THE **OFFILINE** INSTALLER
5. Run FusionFix
6. Paste FusionFix LegacyAddon into game directory
7. Paste XLivelessAddon into game directory
8. In GameNative make sure that your Executable Path is `GTAIV/GTAIV.exe`



If you're missing your translation, please follow the DepotDownloader tutorial [GameNative may not pull your language correctly
](../README.md)