# 4. Publish every app to one public hub repo

Date: 2026-10-30

## Status

Accepted

## Context

The newest APK of each app was scattered across each repo's own releases, under changing tag and file names, and two of the repos (SleepyGuy, hisense-touch-light) are private, so their APKs only download when signed in to GitHub. The goal is one place on the phone that always offers the newest build of every app, updated automatically.

## Decision

We will publish to the public repo `fabiantorrestech/android-apps`: one rolling release per app (tag = app id, for example `sleepyguy`) whose single APK, under a fixed file name, is replaced on every publish, so its download URL never changes. A static GitHub Pages page reads `apps.json` and the GitHub releases API in the browser and shows one card per app. Each app repo's GitHub Actions workflow uploads its release APK on every push to its main branch, using a fine-grained token (`APP_HUB_TOKEN`) limited to this repo; `scripts/publish-local.ps1` does the same from this PC. AccountabiliBuddy is not copied: its card reads the latest release of `AccountabiliBuddy-releases`, where that project already publishes its APKs.

We chose this over linking each repo's own releases (private repos would need sign-in) and over a store app such as Obtainium as the only entry point (it can still point at these stable URLs later).

## Consequences

One bookmark gives the newest build of every app, with no commits needed in this repo to publish. APKs of the private apps are public; their source is not, but an APK can be decompiled. Only the newest build of each app is kept here, so rolling back means rebuilding an older commit. Every app repo holds a copy of the hub token and must be updated when it expires. The page depends on the unauthenticated GitHub API (60 requests an hour per IP, about 6 per page load).
