# My Android apps

One place to download the newest signed build of each of my Android apps:
**https://fabiantorrestech.github.io/android-apps/**

Installing an APK from here updates the copy already on the phone (same signing key, higher version). Each of my own apps' releases also has a debug build, `<Name>-debug.apk`, which installs as a separate `.debug` app next to the normal one ([ADR 7](doc/adr/0007-publish-a-release-and-a-debug-apk-for-every-app.md)).

### Productivity

| App | Direct link (always the newest build) |
| --- | --- |
| AccountabiliBuddy (phone + watch) | [AccountabiliBuddy-releases, latest](https://github.com/fabiantorrestech/AccountabiliBuddy-releases/releases/latest) |
| Curbox (grayscale patch, unofficial) | [Curbox.apk](https://github.com/fabiantorrestech/android-apps/releases/download/curbox/Curbox.apk) (no debug build, [ADR 8](doc/adr/0008-publish-patched-builds-of-other-peoples-apps.md)) |
| LockMyPhone Extended | [LockMyPhoneExtended.apk](https://github.com/fabiantorrestech/android-apps/releases/download/lockmyphoneextended/LockMyPhoneExtended.apk) |

### Tools

| App | Direct link (always the newest build) |
| --- | --- |
| SleepyGuy | [SleepyGuy.apk](https://github.com/fabiantorrestech/android-apps/releases/download/sleepyguy/SleepyGuy.apk) |
| Shortcut Hub | [ShortcutHub.apk](https://github.com/fabiantorrestech/android-apps/releases/download/shortcuthub/ShortcutHub.apk) |
| MyCalendarWidget | [MyCalendarWidget.apk](https://github.com/fabiantorrestech/android-apps/releases/download/mycalendarwidget/MyCalendarWidget.apk) |
| GrayScaler+ | [GrayScalerPlus.apk](https://github.com/fabiantorrestech/android-apps/releases/download/grayscalerplus/GrayScalerPlus.apk) |
| PixelWatchNotificationGuru (phone + watch) | [phone](https://github.com/fabiantorrestech/android-apps/releases/download/pixelwatchnotificationguru/PixelWatchNotificationGuru-phone.apk) · [watch](https://github.com/fabiantorrestech/android-apps/releases/download/pixelwatchnotificationguru/PixelWatchNotificationGuru-watch.apk) (install with `adb -s <watch> install -r`) |

### E-ink Device Apps

| App | Direct link (always the newest build) |
| --- | --- |
| Touch Light Boost | [TouchLightBoost.apk](https://github.com/fabiantorrestech/android-apps/releases/download/touchlightboost/TouchLightBoost.apk) |
| Touch Wallpaper | [TouchWallpaper.apk](https://github.com/fabiantorrestech/android-apps/releases/download/touchwallpaper/TouchWallpaper.apk) |
| inkOS (search-first patch, unofficial) | [inkOS.apk](https://github.com/fabiantorrestech/android-apps/releases/download/inkos/inkOS.apk) (no debug build, [ADR 8](doc/adr/0008-publish-patched-builds-of-other-peoples-apps.md)) |

## How builds get here

- **Automatically:** each app's GitHub Actions workflow builds a signed release and a debug APK on every push to its main branch and replaces both APKs on that app's release here.
- **From the PC:** `pwsh scripts/publish-local.ps1 -All` (or `-App sleepyguy,shortcuthub`, no spaces). Builds each app from its clone next to this repo, checks the signing key, uploads.

Why it works this way: [`doc/adr/`](doc/adr/README.md).
