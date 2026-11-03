# My Android apps

One place to download the newest signed build of each of my Android apps:
**https://fabiantorrestech.github.io/android-apps/**

Installing an APK from here updates the copy already on the phone (same signing key, higher version).

| App | Direct link (always the newest build) |
| --- | --- |
| AccountabiliBuddy (phone + watch) | [AccountabiliBuddy-releases, latest](https://github.com/fabiantorrestech/AccountabiliBuddy-releases/releases/latest) |
| SleepyGuy | [SleepyGuy.apk](https://github.com/fabiantorrestech/android-apps/releases/download/sleepyguy/SleepyGuy.apk) |
| Touch Light Boost | [TouchLightBoost.apk](https://github.com/fabiantorrestech/android-apps/releases/download/touchlightboost/TouchLightBoost.apk) |
| Shortcut Hub | [ShortcutHub.apk](https://github.com/fabiantorrestech/android-apps/releases/download/shortcuthub/ShortcutHub.apk) |
| MyCalendarWidget | [MyCalendarWidget.apk](https://github.com/fabiantorrestech/android-apps/releases/download/mycalendarwidget/MyCalendarWidget.apk) |
| GrayScaler+ | [GrayScalerPlus.apk](https://github.com/fabiantorrestech/android-apps/releases/download/grayscalerplus/GrayScalerPlus.apk) |
| PixelWatchNotificationGuru (phone + watch) | [phone](https://github.com/fabiantorrestech/android-apps/releases/download/pixelwatchnotificationguru/PixelWatchNotificationGuru-phone.apk) · [watch](https://github.com/fabiantorrestech/android-apps/releases/download/pixelwatchnotificationguru/PixelWatchNotificationGuru-watch.apk) (install with `adb -s <watch> install -r`) |
| LockMyPhone Extended | [LockMyPhoneExtended.apk](https://github.com/fabiantorrestech/android-apps/releases/download/lockmyphoneextended/LockMyPhoneExtended.apk) |

## How builds get here

- **Automatically:** each app's GitHub Actions workflow builds a signed release on every push to its main branch and replaces the APK on that app's release here.
- **From the PC:** `pwsh scripts/publish-local.ps1 -All` (or `-App sleepyguy,shortcuthub`, no spaces). Builds each app from its clone next to this repo, checks the signing key, uploads.

Why it works this way: [`doc/adr/`](doc/adr/README.md).
