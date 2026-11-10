# Optional Notch Integration — Final Phase Only

## Provenance and license gate
Aura used the GitHub **Boring Notch** project with local modifications. The supplied Aura technical review identifies vendored Boring Notch as GPL-3.0 and notes excluded/shimmed components. Before any reuse: inspect exact upstream repository, pinned commit, license, local diff, attribution and distribution obligations with appropriate legal review. Do not assume slightly modified code is license-free or that it can be embedded in a proprietary distribution without obligations.

## Hard architectural isolation
- Core app launches from menu bar and opens dashboard on demand with notch module completely absent.
- Notch is a separate target/package behind `NotchSurfaceAdapter` protocol: `start(configuration, stateFeed)`, `stop()`, `update(state)`, `handle(command)`.
- Adapter receives read-only snapshots of timer, tasks, media and calendar; actions invoke validated core service commands. No notch-owned SQLite tables, auth tokens, timer engines or authoritative stores.
- Feature flag defaults OFF; absence of package or license approval must not break compilation, startup or UI.

## Implementation steps after explicit authorization
1. Freeze/tag `core-complete` and record clean build + regression results.
2. Audit upstream Boring Notch and Aura modifications; produce patch inventory and choose compliant reuse vs clean-room reimplementation.
3. Create isolated adapter target; ensure core app compiles with it excluded.
4. Implement screen geometry, physical/simulated notch, hover hit testing, click-through, full-screen and multi-display behavior.
5. Add live activities for timers/stopwatch, music metadata and controls, upcoming calendar; use existing core state and permissions.
6. Add optional Notch Settings page: enable, display selection, simulated notch, hover delay, animation, visibility, live activity ordering and media source.
7. Test activation/deactivation, sleep/wake, display hot-plug, resolution change, accessibility, reduced motion, full-screen, focus, permissions and stale state.
8. Run entire **core** CI suite with notch absent, disabled and enabled; run adapter-specific UI snapshots; package both supported variants if required.
9. Merge behind disabled-by-default flag; enable only after opt-in. Provide one-click rollback toggle and documented uninstall path.

## Non-negotiable acceptance
- Core build passes with notch source removed from checkout.
- Enabling/disabling notch never changes task/calendar/logging data or timer deadlines.
- All commands accessible without notch; no accidental interaction capture outside notch region.
- License, attribution, signing, entitlements and redistribution conditions documented.
- If implementation is paused indefinitely, the core product remains complete and maintainable; future addition is a bounded adapter task, not a rewrite.
