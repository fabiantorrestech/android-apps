# android-apps

Public download hub for my personal Android apps: a GitHub Pages page (`index.html`) plus one rolling release per app holding its newest signed release APK and debug APK. No app code lives here.

## Files
```
apps.json                  categories (page section order) + the app list: category, release repo + tag, release/debug APK patterns, expected signing key, local build info
index.html                 Pages site; reads apps.json + the GitHub releases API in the browser
scripts/setup-signing.ps1  put every signing key on this PC from 1Password (run once per PC)
scripts/publish-local.ps1  build on this PC, check the signer, upload to the app's release
doc/adr/                   why: signing keys (2), versionCode (3), hub layout (4), keys in 1Password (5), shared debug key (6), release + debug APKs (7)
```

## Hard rules
- **Never change an app's signing key.** Install-over needs the same key; a new key forces an uninstall on every phone. Expected key SHA-256s are in `apps.json` → `keys`. (The one deliberate exception was ADR 6.)
- Keystores and their passwords live in the 1Password vault "Android Signing" (ADR 5), one item per key id (`password`, `alias`, file `keystore`). On a PC, `scripts/setup-signing.ps1` copies them to `~/.android-signing/`; CI uses repo secrets. Never commit either.
- Release tag = app id, APK file name fixed: the download URLs must never change.
- Every app publishes a release build as `<Name>.apk` and a debug build as `<Name>-debug.apk` on the same tag (ADR 7). Debug builds use `applicationIdSuffix ".debug"` and the app's release key, so they install next to the release copy. Anything declared globally (provider authorities) must use `${applicationId}`.
- AccountabiliBuddy is not built or copied here; its card reads `AccountabiliBuddy-releases`.

## Signing per app
| App | Key | Gradle properties / CI secrets |
| --- | --- | --- |
| SleepyGuy, Shortcut Hub, GrayScaler+ | `fabiantorrestech-release.jks` | `PERSONAL_KEYSTORE_FILE/_PASSWORD/_ALIAS`; secrets `PERSONAL_KEYSTORE_B64/_PASSWORD/_ALIAS` |
| MyCalendarWidget | `mycalendarwidget_ks` | `MYCALENDARWIDGET_KEYSTORE_*`; secrets `MYCALENDARWIDGET_KEYSTORE_B64/_PASSWORD/_ALIAS` |
| Touch Light Boost | `app/sideload.keystore` committed in its private repo | none |
| Touch Wallpaper (release build signed with the debug key, so it installs over the earlier debug builds on the Hisense) | `DEBUG_SHARED` | none (no CI workflow) |
| AccountabiliBuddy | `DEBUG_SHARED`, installed as `~/.android/debug.keystore` (ADR 6) | none |
| PixelWatchNotificationGuru (phone + watch; release builds signed with the debug key) | `DEBUG_SHARED` (both apps must share it for the Data Layer) | secret `DEBUG_KEYSTORE_B64` (CI puts it at `~/.android/debug.keystore`) |
| LockMyPhone Extended (release build signed with the debug key; must match AccountabiliBuddy for its signature-guarded sync) | `DEBUG_SHARED` | none yet (no CI workflow) |

Every app repo except AccountabiliBuddy also has secret `APP_HUB_TOKEN` (fine-grained PAT, contents read/write on this repo only).

## Builds
- JDK 21 (`~/.gradle/jdks/...21...`): Android Studio's bundled JBR is JDK 25, which Gradle 8.x (Grayscaler, hisense) can't run on. Apps on Gradle 9 can use the JBR: `publish-local.ps1 -JavaHome "C:/Program Files/Android/Android Studio/jbr"`.
- versionCode = `git rev-list --count HEAD` (ADR 3), so CI checks out with `fetch-depth: 0`.

## Adding an app
1. Add the signing + versionCode block and the `.debug` debug build type to its `app/build.gradle.kts` (copy from Shortcut Hub).
2. Add it to `apps.json` with a `category` and `debugAssetPattern`, release spec first in `local.apks` (and the README table).
3. Set its repo secrets, then add the release + debug build and "Publish to the app hub" step to its workflow (copy from Shortcut Hub's `release-apk.yml`).
