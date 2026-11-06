# 5. Keep signing keys in 1Password

Date: 2026-11-05

## Status

Accepted

## Context

ADR 2 keeps keystores in a OneDrive folder and their passwords in each PC's `~/.gradle/gradle.properties`. In November 2026 that had drifted: this PC (DESKTOP-0GUCMA2) had no OneDrive sync, no `gradle.properties` and none of the release keystores, so it could correctly build only 2 of the 8 hub apps, and the debug keystore behind `PC_DEBUG` existed only on another PC and inside one CI secret that GitHub won't reveal. A third debug key (`b43da7…`) signs a LockMyPhone install whose keystore nobody can locate. The owner wants every key reachable from any of their PCs by script, without committing keys to any repository, private ones included: git history can't be cleaned after a leak, and debug keystores use the public password `android`.

## Decision

We will keep every signing keystore as a document item in a 1Password vault named "Android Signing", with its alias and password as fields of the same item, and read them with the 1Password CLI (`op`). `scripts/setup-signing.ps1` copies the keystores to `~/.android-signing/` on a PC, and `scripts/publish-local.ps1` runs Gradle through `op run`, which passes the passwords as `ORG_GRADLE_PROJECT_*` environment variables, so no password file is written to disk. CI keeps its repository secrets. This replaces how ADR 2 stores keys; ADR 2's choice of keys still holds.

## Consequences

A new or rebuilt PC gets every key by signing in to 1Password and running one script, and a key can no longer exist on only one machine. Building release APKs now needs the 1Password desktop app and CLI with app integration on, and builds prompt for approval in 1Password. The 1Password account becomes the single point whose compromise leaks every key, so it needs a strong password and 2FA. Keys are small (a few KB each, against a 1 GB file allowance), so storage isn't a constraint. CI secrets are still separate copies that have to be updated by hand when a key changes.
