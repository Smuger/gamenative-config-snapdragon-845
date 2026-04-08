### [Gothic 1](https://steamdb.info/app/65540/depots/) on Steam

Make sure you are running [GameNative](https://github.com/utkarshdalal/GameNative/releases) version >= 0.9.0 
Otherwise languages downloaded from steam will not overwrite each other correctly

### This tutorial may not work in a couple of months as the game gets updated on Steam

Gothic 1 downloaded from Steam will, as of February 2026, will not start on your device. I think the reason is that Steam did not include **Union** in its release 

The following tutorial is the easiest way I found to install Union

1. Before starting GameNative on your phone, download [Spine](https://clockwork-origins.com/spine/)
2. Now in GameNative, download Gothic 1 and select the following config:
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

Components:
- Direct3D (Windows)
- DirectSound (Wine)
- DirectMusic (Wine)
- DirectShow (Windows)
- DirectPlay (Wine)
- Virtual C++ 2010 (Windows)
- Windows Media Decoder (Windows)
- OpenGL (Wine)

3. In GameNative click **Open Container**
4. In D:/ drive find your Spine and install it
5. In Spine, go to Databases and find Union (it will be under tools, and Gothic I & II) and install it
6. In Spine, go to Library, unclick SystemPack, then click Union
7. Finally leave Spine and go to A:\system
8. In system find file `SystemPack.ini`
9. In SystemPack.ini find
```bash
BorderlessWindow=0
```
and change it to
```bash
BorderlessWindow=1
```
10. Also, in the system directory, open the `GOTHIC.INI` file and make sure that the video settings matching the resolution you selected
```
[VIDEO]
zVidResFullscreenX=1280
zVidResFullscreenY=720
zVidResFullscreenBPP=32
```
11. Now you can leave the container
12. In GameNative make sure that your Executable Path is `system/GothicMod.exe`
13. Start the Game (Don't panic if the Main Menu doesn't load immediately)


If you're missing your translation, please follow the DepotDownloader tutorial [GameNative may not pull your language correctly
](../README.md)