# Loopinn

Loopinn is an offline-first productivity app for macOS. It brings tasks, planning, focus, activity logging, and reflection into one product. The supplied product and architecture documents are in `Unified_App_Agent_Pack/`.

## Current implementation

The current development slice includes a menu bar launch, an on-demand dashboard, local task capture and completion, task lists, task details, and task-linked internal calendar blocks. Tasks support notes, due dates, priorities, stars, ordering, moving between lists, and one-step undo. Scheduling needs both start and end times; changing a schedule updates its existing block. No external calendar write occurs from these actions.

Focus, analytics, integrations, widgets, and the Android companion remain planned work. The notch is a separate optional final phase and has no implementation in this repository.

## Run locally

Requires macOS 15 or later and Swift 6 / Xcode 26.

```sh
swift run --disable-sandbox Loopinn
```

Local data is stored at `~/Library/Application Support/Loopinn/workspace.json`.

To build a macOS app bundle for local use, run `sh scripts/build-app.sh`. The output is `dist/Loopinn.app`. This development bundle is unsigned and has not been notarized.
