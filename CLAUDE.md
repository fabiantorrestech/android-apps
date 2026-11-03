# android-apps

Public download hub for my personal Android apps: a GitHub Pages page (`index.html`) plus one rolling release per app holding its newest signed APK. No app code lives here.

## Files
```
apps.json                  the app list: release repo + tag, APK name, expected signing key, local build info
index.html                 Pages site; reads apps.json + the GitHub releases API in the browser
scripts/publish-local.ps1  build on this PC, check the signer, upload to the app's release
doc/adr/                   why: signing keys (2), versionCode (3), hub layout (4)
```

## Hard rules
- **Never change an app's signing key.** Install-over needs the same key; a new key forces an uninstall on every phone. Expected key SHA-256s are in `apps.json` → `keys`.
- Keystores live in `../Android_Keystores` (OneDrive). Passwords live only in `~/.gradle/gradle.properties` (PC) and repo secrets (CI). Never commit either.
- Release tag = app id, APK file name fixed: the download URLs must never change.
- AccountabiliBuddy is not built or copied here; its card reads `AccountabiliBuddy-releases`.

## Signing per app
| App | Key | Gradle properties / CI secrets |
| --- | --- | --- |
| SleepyGuy, Shortcut Hub, GrayScaler+ (GrayScaler+ debug builds too) | `fabiantorrestech-release.jks` | `PERSONAL_KEYSTORE_FILE/_PASSWORD/_ALIAS`; secrets `PERSONAL_KEYSTORE_B64/_PASSWORD/_ALIAS` |
| MyCalendarWidget | `mycalendarwidget_ks` | `MYCALENDARWIDGET_KEYSTORE_*`; secrets `MYCALENDARWIDGET_KEYSTORE_B64/_PASSWORD/_ALIAS` |
| Touch Light Boost | `app/sideload.keystore` committed in its private repo | none |
| AccountabiliBuddy | this PC's `~/.android/debug.keystore` | none |
| PixelWatchNotificationGuru (phone + watch, debug builds) | this PC's `~/.android/debug.keystore` (both apps must share it for the Data Layer) | secret `DEBUG_KEYSTORE_B64` (CI puts it at `~/.android/debug.keystore`) |
| LockMyPhone-Extended (release build signed with the debug key) | this PC's `~/.android/debug.keystore` | secret `DEBUG_KEYSTORE_B64` |

Every app repo except AccountabiliBuddy also has secret `APP_HUB_TOKEN` (fine-grained PAT, contents read/write on this repo only).

## Builds
- JDK 21 (`~/.gradle/jdks/...21...`): Android Studio's bundled JBR is JDK 25, which Gradle 8.x (Grayscaler, hisense) can't run on.
- versionCode = `git rev-list --count HEAD` (ADR 3), so CI checks out with `fetch-depth: 0`.

## Adding an app
1. Add the signing + versionCode block to its `app/build.gradle.kts` (copy from Shortcut Hub).
2. Add it to `apps.json` (and the README table).
3. Set its repo secrets, then add the "Publish to the app hub" step to its workflow (copy from Shortcut Hub's `release-apk.yml`).
