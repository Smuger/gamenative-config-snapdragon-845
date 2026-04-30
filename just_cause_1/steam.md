### [Just Cause 1](https://steamdb.info/app/6880/depots/) on Steam

### This tutorial may not work in a couple of months as the game gets updated on Steam

Just Cause 1, downloaded from Steam, will not start using default settings on your device as of April 2026.

The most important thing is to use the correct Graphic Driver. Otherwise game will not load and will be stuck in infinite load loop

1. Far Cry 1 runs fine on my device with the following config:
- Container Variant: **bionic**
- Wine Version: **proton-9.0-x86_64**
- Screen Size: **800x600**
- Audio Driver: **PulseAudio**
- Graphic Driver: **Wrapper**
- Graphic Driver Version: **turnip_v24.3.0-R12** <-- This bit is important
- DX Wrapper: **2.6.1-gplasync**
- Max Device Memory: **0 MB**
- Box64 Version: **0.4.0**
- Box64 Preset: **Performance**

Components:
- Direct3D (Windows)
- DirectSound (Wine)
- DirectMusic (Wine)
- DirectShow (Windows)
- DirectPlay (Wine)
- Virtual C++ 2010 (Windows)
- Windows Media Decoder (Windows)
- OpenGL (Wine)

If you're missing your translation, please follow the DepotDownloader tutorial [GameNative may not pull your language correctly
](../README.md)