# 7. Publish a release and a debug APK for every app

Date: 2026-11-06

## Status

Accepted

## Context

Until November 2026 the hub (ADR 4) offered one APK per app, and for some apps that APK was a debug build: Touch Light Boost (its release build failed lint on targetSdk 22) and PixelWatchNotificationGuru (phone and watch), with Touch Wallpaper about to join the same way. Debug builds are slower and clunkier than release builds, which R8 can shrink and optimize, so the owner wants every app's main download to be a release build. A debug build is still needed now and then to debug an app remotely on a device, and it should be possible to have it without giving up the release copy already on the phone.

## Decision

We will publish two APKs per app on the app's rolling release tag. The release build keeps the existing fixed name (`<Name>.apk`, so no download URL changes) and is the card's main download. The debug build is published next to it as `<Name>-debug.apk` and is listed under a collapsed "Debug builds" section on the card. Debug builds use `applicationIdSuffix ".debug"` and are signed with the same key as the app's release build, so they install as a separate app beside the release copy instead of replacing it. `apps.json` gives each app a `debugAssetPattern`, and `local.apks` lists the release specs first, then the debug ones, so `publish-local.ps1` builds, checks and uploads both without changes. We chose a separate `.debug` app over a debug build with the release app's id, which would replace the release copy and its data each time it was installed.

## Consequences

Every app now has a fast release build as its main download, and a debug build is one tap away for remote debugging without disturbing the installed release. Each CI workflow and local build takes longer because it builds both variants. The debug app starts with its own empty data and permissions (Shizuku, accessibility, wallpaper access), carries the same launcher label as the release app, and is outside the AccountabiliBuddy ↔ LockMyPhone signature-guarded sync, which knows only the release package. Anything an app declares globally must be per-package, or the debug app fails to install next to the release one: LockMyPhone's profiles provider authority became `${applicationId}.profiles` (the release value is unchanged). Implicit broadcasts with fixed action names now reach both copies when both are installed. GrayScaler+'s own CI test builds, which used to install over its release, are now the separate `.debug` app. Touch Wallpaper's release build falls back to a screen flash for e-ink refreshes, because the ROM blocks `forceClear()` for release builds; its debug build keeps it.
