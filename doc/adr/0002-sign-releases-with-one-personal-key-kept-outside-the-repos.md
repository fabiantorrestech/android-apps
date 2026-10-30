# 2. Sign releases with one personal key kept outside the repos

Date: 2026-10-30

## Status

Accepted

## Context

Android only installs an update over an existing app when both are signed with the same key. In October 2026 the apps were signed inconsistently: Shortcut Hub and GrayScaler+ 2.0 with keys that were since lost, SleepyGuy and the GrayScaler+ test builds with a throwaway debug key generated fresh on every CI run, MyCalendarWidget with a key that still exists (`Android_Keystores/mycalendarwidget_ks`), Touch Light Boost with a keystore committed to its private repo, and the AccountabiliBuddy phone and watch apps with this PC's debug key. Builds must come out identical from this PC and from GitHub Actions, and passwords must never be committed.

## Decision

We will sign SleepyGuy, Shortcut Hub and GrayScaler+ with one new personal key, `Android_Keystores/fabiantorrestech-release.jks` (alias `release`), and keep the existing keys where a phone already has an app signed with them: MyCalendarWidget keeps its own key, Touch Light Boost its committed sideload key and AccountabiliBuddy this PC's debug key. Each app's Gradle file reads the keystore path, password and alias from Gradle properties (`PERSONAL_KEYSTORE_*`, `MYCALENDARWIDGET_KEYSTORE_*`). On this PC they live in the user-level `~/.gradle/gradle.properties`; in CI they come from repository secrets passed as `ORG_GRADLE_PROJECT_*` environment variables, with the keystore stored base64-encoded. A build without the properties falls back to the debug key with a warning. `apps.json` records the SHA-256 of each app's expected signing certificate, and the local publish script refuses to upload an APK signed with anything else.

We chose one shared key over one key per app because these are sideloaded personal apps: one keystore and one set of secrets is far easier to keep safe and backed up than five.

## Consequences

Every future build from either machine installs over the last one. Switching SleepyGuy, Shortcut Hub and GrayScaler+ to the new key forces one uninstall on each phone (settings must be exported first). The keystore in OneDrive is now critical: losing it repeats this whole problem, and a leak of it (or of its password, which is short) lets someone sign updates for three apps at once. Moving an app to a different key later costs another uninstall on every device, unless APK Signature Scheme v3 key rotation is set up.
