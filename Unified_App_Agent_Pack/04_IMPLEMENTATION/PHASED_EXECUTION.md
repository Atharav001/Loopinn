# Complete Implementation Sequence — Core First, Notch Last

## Rules for each implementation ticket
**Before:** link PRD feature ID; identify source files; record expected behavior, state transitions, dependencies, permission matrix, timeout budget, fallback and rollback. Write failing unit/contract test first where practical. **Implement:** smallest independently testable vertical slice, no speculative copy/paste. **Verify:** formatting, compilation, unit/integration/UI, fault injection, packaged runtime. **Deliver:** screenshots or logs, migration notes, changelog, PR, green CI and merge checkpoint. Do not start dependent ticket while gate red.

## Phase 0 — Repository audit and licensing gate
- Inventory three repos, active targets, excluded code, package locks, app entitlements, bundle IDs and GPL Boring Notch obligations.
- Run each original project clean build and tests on supported macOS/Android toolchains; capture exact compiler versions, failures and reusable APIs. No guessed reuse.
- Create ADRs for licensing, local persistence, calendar ownership, timer recovery and sync conflict policy.
- **Exit:** reproducible baseline and explicit reuse/no-reuse decisions.

## Phase 1 — Skeleton, design system, CI and database
- Create new Swift project/workspace with modular packages and launch-as-agent app; menu bar opens empty dashboard.
- Implement tokenized premium UI component library and settings infrastructure before feature screens.
- Create SQLite schema, ordered transactional migrations, typed repository APIs, test fixtures and backup/restore.
- CI: clean macOS build, static checks, unit tests, Android skeleton build, secret scan, artifact packaging smoke.
- **Exit:** cold clean install, upgrade test, settings persist, no notch references in core.

## Phase 2 — Tasks and scheduling
- Implement multi-list CRUD, capture, keyboard shortcuts, undo, attachments with durable stored path, metadata fetching with bounded redirects/content size, smart recommendation deterministic algorithm.
- Implement TaskSchedule only for complete time intervals; in one transaction write schedule + internal calendar block; update/delete link by stable ID; due date alone creates no block.
- Add scheduling suggestions with explicit accept; test DST, midnight, overlap, duplicate action, crash between writes and restart recovery.
- **Exit:** all task features and internal scheduling tests pass.

## Phase 3 — Calendar, planner and external providers
- Implement day/week/month/year and interactive week grid with create/move/resize/cancel, snapping, overlap columns and keyboard alternatives.
- EventKit read and provider availability; Google OAuth PKCE and incremental fetch. External publish requires preview and per-action/batch confirmation, including edits/deletions; durable queue only after consent.
- Handle revoked permission, rate limit, offline, duplicate event, partial batch, conflict and deleted remote calendar.
- **Exit:** no external event written without recorded consent; reconciliation and retry tested.

## Phase 4 — Timers, focus and activity logging
- One timer state machine for Pomodoro, Deep Work, countdown and stopwatch; persistent deadlines, restart/wake reconciliation, notification and sound effects.
- Floating timer/logging panels; repeating alarms and quiet hours; scheduled prompts with explicit missed interval policy.
- Typed/voice logging with real permission/errors; classification dictionary and correction precedence; planned/logged rails.
- **Exit:** sleep/wake, process kill/restart, permission denial and no-fake-log tests pass.

## Phase 5 — Analytics, widgets, utilities and premium polish
- Define reporting math (range clipping, overlap policy, productive/neutral/wasteful, skipped, peak focus weighted by duration). Implement dashboard, charts, history and export.
- Desktop WidgetKit App Group snapshots + AppIntents; test extension process and app separately.
- Media controls, file shelf, clipboard retention, webcam/system controls only with verified compiled functionality and permissions.
- Finish settings/toggle screens, command palette, onboarding, themes, panel placement, accessibility, reduced motion and snapshot tests.
- **Exit:** all core macOS features except optional notch are working, packaged and documented.

## Phase 6 — Cloud and focused Android companion
- Supabase/Postgres migrations + RLS tests; auth, secure token lifecycle, outbox, pagination, tombstones, conflict handling and account isolation.
- Android Kotlin/Compose/Room tasks, calendar, logging, timers and sync; permission-aware notification actions and OS scheduling limitations.
- Fault-test offline edits, concurrent updates, duplicate delivery, expired token, 429/5xx, partial success, background restrictions, logout and device swap.
- **Exit:** end-to-end two-device sync and account isolation proven; all 51 feature categories supported across intended platforms except notch optional module.

## Phase 7 — Core product release candidate / pause checkpoint
- Full regression matrix, migration upgrade, signed macOS packaging, Android release packaging, privacy and accessibility review.
- Publish `core-complete` tag and immutable release candidate; core menu bar + dashboard + widgets + panels remain fully usable.
- **User choice:** STOP here and maintain core product, OR explicitly authorize Phase 8 notch work. Do not silently continue.

## Phase 8 — OPTIONAL LAST: Notch adapter
- Only after user opt-in and licensing approval; follow `06_OPTIONAL_NOTCH/NOTCH_PLUGIN_PLAN.md`.
- No changes to domain schema required; no dependency from core into notch target.
- **Exit:** notch enabled and disabled both pass identical core regression; uninstall/disable returns to core without data loss.

## Release gate nuance
User chose all 51 before first public release, but also wants to pause notch. Treat `core-complete` as a fully functional **internal/private or separately scoped release candidate**, not as a claim that all 51 including notch are delivered. Public full-scope release waits for authorized notch completion; if user permanently defers notch, explicitly approve a revised release scope/version.
