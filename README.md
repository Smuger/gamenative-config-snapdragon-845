# gamenative-config-snapdragon-845
Device Spec:
- Name: **Poco F1 (beryllium)**
- ROM: **[LineageOS](https://wiki.lineageos.org/devices/beryllium/) 22.1 (Android 15)**
- RAM: 6 GB


## GameNative may not pull your language correctly
The easiest way I found to pull the translation you need is to follow Valve's Source on Android documentation 

https://developer.valvesoftware.com/wiki/Source_on_Android

1. Install [Termux](https://github.com/termux/termux-app/releases) app on your phone 
2. Install DepotDownloader using [TermuxDepotDownloader](https://github.com/TheKingFireS/TermuxDepotDownloader) installer (Official Valve docs point to it, so I guess it's legit)
```bash
bash <(curl -sSL "https://raw.githubusercontent.com/TheKingFireS/TermuxDepotDownloader/alpine/installproot.sh")
```
3. Find the language depot you need. In this example, we will be installing the Polish translation for Gothic 1
- Find your depot in [steamdb.info](https://steamdb.info/app/65540/depots/)
- Find the App ID (For Gothic, it will be: 65540)
- Scroll down to Depots and find the Depot ID (For Polish translation, it will be 65544)

4. Start Termux on your Android device and download the Depot with the details from the step above
e.g.
```bash
 depotdownloader -username <your-username> -app 65540 -depot 65544
```

5. Now the translation will be saved in your Download folder. All you have to do to install it, is to replace the equivalent files you have in A:\ directory installed in GameHub