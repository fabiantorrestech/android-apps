# 1. Record architecture decisions

Date: 2026-10-30

## Status

Accepted

## Context

This repo ties several Android app repos together: how their APKs are signed, versioned and published. Those choices are expensive to undo (a lost or changed signing key forces every phone to uninstall the app), so the reasons behind them need to outlive the conversation in which they were made.

## Decision

We will keep Architecture Decision Records in `doc/adr/`, as described by Michael Nygard in "Documenting Architecture Decisions" (2011): one short record per significant decision, numbered, append-only, superseded rather than edited.

## Consequences

Anyone adding an app or changing the release flow can read why it works the way it does. The cost is writing a record whenever a choice is costly to reverse, and keeping the index in `doc/adr/README.md` regenerated.
