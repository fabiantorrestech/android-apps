# 6. Share one debug key across companion apps

Date: 2026-11-05

## Status

Accepted

## Context

AccountabiliBuddy, PixelWatchNotificationGuru and LockMyPhone Extended are signed with debug keys rather than release keys. By November 2026 three different debug keys were in use: AccountabiliBuddy with DESKTOP-0GUCMA2's key (`8b18…`), PixelWatchNotificationGuru and the hub's LockMyPhone APK with `PC_DEBUG` (`72fe…`), whose keystore only survives in a CI secret, and one LockMyPhone install with `b43da7…`, whose keystore can't be found. LockMyPhone's profile sync (LockMyPhone ADR 8) only accepts AccountabiliBuddy when both share a key (`protectionLevel="signature"`), so with mismatched keys the sync silently stops.

## Decision

We will sign AccountabiliBuddy, PixelWatchNotificationGuru and LockMyPhone Extended with one shared debug key, `DEBUG_SHARED` (SHA-256 `8b189caefe2007b3efc0fd1a4b1959fa1b0a438689997aeca62e2ed75ffdc852`, the debug keystore of DESKTOP-0GUCMA2), kept in 1Password per ADR 5 and installed as `~/.android/debug.keystore` on every build PC. We chose it over `72fe…` because it is held now and AccountabiliBuddy already uses it, and over `b43da7…` (the newest install, on the Nothing Phone 3) because that key's keystore isn't available.

## Consequences

AccountabiliBuddy and LockMyPhone can always talk to each other, and any PC builds installable updates for all three apps. Moving PixelWatchNotificationGuru (phone and watch) and LockMyPhone to the new key forces one uninstall on every device that has them (LockMyPhone settings must be exported first), and the `PC_DEBUG` key is retired. Overwriting a PC's own debug key changes the signer of every debug build made on it, so the setup script backs up any different key first. A debug key is weak protection: its password is public, so the keystore file itself must stay private.
