# Baseline audit — 10 November 2026

## Repository and toolchain

- Repository: `https://github.com/Atharav001/Loopinn` (public); audited `main` at `2aa1509` after PR #3 merged.
- macOS source: Swift package `LoopinnCore` plus `Loopinn` SwiftUI/AppKit executable. Six XCTest cases cover scheduling, ordering, SQLite round trips, legacy JSON import, and attachment copy/cleanup.
- Packaging: `scripts/build-app.sh` creates an unsigned `dist/Loopinn.app`; GitHub Actions runs macOS build, tests and package upload.
- Local toolchain: Apple Swift 6.3.3 and Xcode 26.6. Minimum declared target: macOS 15.
- Direct third-party package dependencies: none. Apple frameworks used: SwiftUI, AppKit, Foundation, UniformTypeIdentifiers and system SQLite3.
- No Android target, widget extension, cloud backend, external calendar adapter or notch source exists in this checkout.
- Aura, Loopin and Logtrackin source repositories were not supplied here. Their archived technical reviews are reference documents only. No source was copied from them, so no reuse license decision is needed for the current code. Any later Boring Notch reuse remains behind the separate licensing gate.

## Reproduced baseline

From a clean Swift package build directory, `swift test --disable-sandbox` passed 6/6 tests. `sh scripts/build-app.sh` produced `dist/Loopinn.app`; `plutil -lint dist/Loopinn.app/Contents/Info.plist` passed. The package was not signed, notarized, installed, launched for a UI smoke test or tested on Android. GitHub PR #3 reported two passing macOS build jobs before merge.

## Current implementation boundaries

Menu bar launch and dashboard opening are coded. Tasks, lists, due dates and internal task-linked blocks persist in SQLite. Attachments copy into application storage. The database currently rewrites the workspace snapshot in one transaction; it does not yet have incremental repositories, migration rollback tooling, backup/restore UI, external sync or conflict resolution. A passing build does not satisfy the PRD's complete feature acceptance gates.

## Decisions and next action

Build the core as fresh code; request source repos only if selective reuse becomes necessary. Keep the notch absent until P07 and explicit opt-in. Next engineering ticket after this audit is `P01-FR41`: complete the menu-bar command center with one shared window routing path and UI smoke evidence.
