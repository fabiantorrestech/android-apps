# 3. Use the git commit count as the version code

Date: 2026-10-30

## Status

Accepted

## Context

Android refuses to install an APK whose versionCode is lower than the installed one. Shortcut Hub, MyCalendarWidget and GrayScaler+ had a fixed, hand-edited versionCode that was rarely bumped, and SleepyGuy used the GitHub Actions run number, which a PC build cannot know (it fell back to 1, a downgrade). Builds from this PC and from CI need versionCodes that agree and only go up.

## Decision

We will set versionCode to `git rev-list --count HEAD` in SleepyGuy, Shortcut Hub, MyCalendarWidget and GrayScaler+, read at build time through Gradle's `providers.exec`. CI checks out the full history (`fetch-depth: 0`) so it counts the same commits as the PC. versionName stays hand-written. Touch Light Boost keeps its hand-written versionCode, which its tag-driven releases already bump, and AccountabiliBuddy is out of scope.

## Consequences

Each new commit on the main branch is automatically a higher version, from either machine, with nothing to remember. The number only grows along one branch: a build from a side branch with fewer commits looks like a downgrade, and rewriting history on main (squash, rebase) can make the count drop. Builds need git and the repo's history; a shallow clone or a source zip fails to configure.
