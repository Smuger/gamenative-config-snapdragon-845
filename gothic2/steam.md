
### [Gothic 2](https://steamdb.info/app/39510/depots/) on steam

Make sure you are running [GameNative](https://github.com/utkarshdalal/GameNative/releases) version >= 0.9.0 
Otherwise languages downloaded from steam will not overwrite each other correctly

### This tutorial may not work in a few months when the game gets updated

1. Before starting GameNative on your phone, download [Spine](https://clockwork-origins.com/spine/)

**SUPER IMPORTANT!** 

2. in GameNative environment tab for Gothic II disable **WINEESYNC** (otherwise Union patch will fail)

3. Gothic 2 runs fine on my device wit the following config:
- Container Variant: **bionic**
- Wine Version: **proton-9.0-x86_64**
- Executable Path: **system/Gothic2.exe**
- Screen Size: **1366x768**
- Audio Driver: **PulseAudio**
- Graphic Driver: **Wrapper**
- Graphic Driver Version: **turnip26.0.0_R8**
- DX Wrapper: **2.7.1**
- Max Device Memory: **0 MB**
- Box64 Version: **0.4.0**
- Box64 Preset: **Intermediate**

**ALSO IMPORTANT**
- Set every component to **Native (Windows)**. You should **NOT** use **Builtin (Wine)** for anything

4. In GameNative click **Open Container**
5. In A:/ move all files from **system** to **System**
6. In A:/ delete the empty directory **system**
7. In D:/ drive find your Spine and install it
8. In Spine, go to Databases and find Union (it will be under tools, and Gothic I & II) and install it
9. In Spine, go to Library, find "Gothic 2" and "Night of the Raven"  unclick SystemPack, then click Union
10. Finally leave Spine and go to A:\system

**ALSO ALSO IMPORTANT**

11. In system find file `SystemPack.ini`
12. In SystemPack.ini find
```bash
BorderlessWindow=0
```
and change it to
```bash
BorderlessWindow=1
```

If you miss this step game will hang when you try to see Load Save page in Main Menu

13. Now you can leave the container
14. In GameNative make sure that your Executable Path is `system/Gothic2.exe`
15. Start the Game (Don't panic if the Main Menu doesn't load immediately)

If you're missing your translation, please follow the DepotDownloader tutorial [GameNative may not pull your language correctly
](../README.md)