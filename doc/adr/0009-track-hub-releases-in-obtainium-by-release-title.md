# 9. Track hub releases in Obtainium by release title

Date: 2026-11-16

## Status

Accepted

## Context

The owner wants people who install apps from the hub to get update notifications through Obtainium or its fork ObtainX, which watch GitHub releases and install new APKs. Both apps read a GitHub release's tag as its version by default. The hub's tags never change (each app has one rolling release whose tag is the app id, ADR 4), and neither do its APK file names, so with default settings Obtainium would never see a new build. The hub repo also holds every app's release, while Obtainium reads one repo per entry and, without extra settings, stops at the newest release in the repo, which usually belongs to another app. What does change on every build is the release title, which `publish-local.ps1` and the CI workflows set to `<apps.json name> <versionName> (<versionCode>)`. Obtainium and ObtainX both accept an `obtainium://app/<json>` link that imports one app with all its settings.

## Decision

We will have each hub app tracked by its release title. Its Obtainium settings use the title as the version string, filter release titles by `^<apps.json name>\s` with fallback to older releases on, filter APKs by the app's release asset pattern (so debug builds are skipped), and turn version detection off, because a title never equals the app's own versionName. The hub page generates these settings from `apps.json` and shows them on every card as a one-tap `obtainium://app/` link and as copyable manual steps. Each app in `apps.json` gains `packageId`, because the link must carry the real package name. `obtainiumApkPattern` picks the phone APK for phone and watch apps, and `official` names the upstream app for builds that replace someone else's app. We chose this over per-app version tags because those would change the download URLs, which must stay fixed.

## Consequences

Adding an app to Obtainium takes one tap and no manual regex, and new builds show up as updates in Obtainium and ObtainX without any change to the app repos or the publish pipeline. The release title format and each app's `apps.json` `name` are now a public interface: renaming an app, or publishing a release whose title does not start with its name and a space, silently stops updates for everyone who added it, and their only fix is to remove and re-add the app. Because version detection is off, Obtainium shows any title change as an update, including a re-publish of the same build. AccountabiliBuddy's releases repo follows the desktop version, so its desktop-only releases also appear as phone updates. Two points come from reading the Obtainium and ObtainX source, not from testing on a device: that ObtainX applies an imported `releaseTitleAsVersion`, and that a track-only entry for an official app can sit beside the installed patched build with the same package name.
