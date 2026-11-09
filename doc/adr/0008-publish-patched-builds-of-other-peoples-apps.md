# 8. Publish patched builds of other people's apps

Date: 2026-11-09

## Status

Accepted

## Context

The owner runs Curbox, an open source screen time manager by another developer (GPL-3.0, `curbox-app/curbox-android`), with one personal patch: Curbox's grayscale feature switched the system grayscale filter off whenever it did not want it on, overriding GrayScaler+. The patch makes Curbox switch off only a filter it switched on itself. The owner wants each new Curbox release with that patch applied, installable from the hub like the owner's own apps. The hub's existing rules were written for apps the owner develops: the version code is the app repo's commit count (ADR 3), every app also ships a debug build (ADR 7), and builds come from the app's own repo. None of that fits an app whose code is someone else's and only receives a small patch on each upstream release.

## Decision

We will build patched apps in a separate public patcher repo per app (`fabiantorrestech/curbox-patcher`) rather than in a long-lived fork. Its GitHub Actions workflow takes an upstream release, applies the patch kept as one commit (exported to `patches/grayscale.patch`), runs the patch's tests, builds the upstream release variant (Curbox's fdroid flavor), and signs it with the PERSONAL key (ADR 2). It refuses to publish if the signer differs from `keys.PERSONAL` in `apps.json`. The workflow runs daily and on demand, publishes `<version>-grayscale` releases in the patcher repo, and replaces `Curbox.apk` on the hub's `curbox` tag only when it built the newest upstream release. The app keeps upstream's version code instead of a commit count, so its numbering matches official releases and still rises with each one. Patched apps publish a release APK only. The owner wants debug builds for their own apps, not for forks of existing apps unless they ask for one. The app keeps upstream's application id, so the patched build replaces the official app instead of running beside it.

## Consequences

New upstream releases become installable from the hub and from Obtainium without manual work, as long as the patch still applies. When it does not, the run fails with the conflicting files listed, and `scripts/refresh-patch.sh` moves the patch onto the new release. Keeping the upstream file change to a few lines keeps such conflicts rare. Switching from the official app (or from the first patched build, which used a separate key) needs one backup, uninstall and restore, because the signing keys differ. The patcher repo must be public for free Actions minutes and to publish the GPL source of the modified build, and GitHub pauses its daily schedule after 60 days without repository activity. The hub page shows no debug build for Curbox, and `publish-local.ps1` skips it (`local: null`). The patcher repo also needs its own `APP_HUB_TOKEN` secret; without it, builds still publish in the patcher repo and the hub step is skipped with a warning.
