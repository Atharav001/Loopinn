# Agent execution plan — phase-by-phase

> Source of truth for implementation sequencing. Scope: 51 features; notch P08 is explicitly optional and last. This plan is proposed, not evidence of current completion.

## Locked product rules
- Launch menu bar first; dashboard on demand.
- Timed tasks create internal blocks only with valid start and end; due-date-only tasks never auto-create blocks.
- External Apple/Google calendar writes require explicit approval.
- Android is focused companion.
- All selected features are intended for the complete public release; P07 allows a stable non-notch checkpoint, but is not a claim that notch features are delivered.
- Existing Boring Notch fork/modifications require code and GPL-3.0 distribution review before P08.

### Mandatory ticket workflow
1. **Discover:** inspect current code, open PRD requirement, identify module owner and dependency IDs; record baseline branch, commit SHA, toolchain versions and known failures.
2. **Specify:** write UI states (loading/empty/success/error), data contract, permission behavior, timeout/retry limits, rollback and acceptance tests. If behavior is ambiguous, mark BLOCKED and ask; do not silently decide.
3. **Test first:** unit/contract tests for happy path and at least one relevant failure; mocks must be clearly separated from production adapters.
4. **Implement:** small vertical slice behind a feature flag where useful; avoid schema changes without versioned migration and backup.
5. **Verify:** clean compile, unit, integration, targeted UI smoke, app relaunch, offline/permission fault tests, package/install check when relevant. Store actual command output and test artifacts.
6. **GitHub:** branch `feat/<ticket-id>-<slug>`, commit, push, open PR, wait for required CI and review; merge only after gates pass. If credentials/remote are unavailable, mark `BLOCKED`, not `DONE`.
7. **Record:** update `STATUS.md`, `FEATURE_MATRIX.md`, `CHANGELOG.md`, evidence links, commit SHA, PR URL, known limitations and next ticket **in the same PR**.

**Definition of DONE:** code merged to protected branch, relevant tests pass on clean runner, packaged runtime verified where required, acceptance criteria evidenced, docs updated, no unacknowledged P0/P1 regression. `Implemented locally` is **IN REVIEW**, not DONE.

## P00 — Baseline, repo audit & decisions

**Entry dependency:** None. **Phase state:** IN PROGRESS (current repository baseline audited; source-reuse audit limited by missing original repositories).

**Tickets:** AUD-01 inventory active source targets and third-party licenses; AUD-02 run clean macOS and Android builds/tests and capture logs; AUD-03 write architecture decision records for data ownership, timer recovery, calendar consent and sync conflicts; AUD-04 establish feature IDs, CI and issue/PR templates.
**Exit gate:** source-level reuse matrix, reproducible commands, verified baseline and approved ADRs.

## P01 — App shell, design system, settings & CI

**Entry dependency:** P00. **Phase state:** NOT STARTED (unverified).

### FR-41 — Menu-bar command center
**Implementation ticket:** `P01-FR41`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Menu bar stays alive without dashboard; actions open exactly one target window.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-42 — Floating panel system
**Implementation ticket:** `P01-FR42`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Panel registry prevents duplicates; position/size persist and off-screen recovery works.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-43 — Themes & customization
**Implementation ticket:** `P01-FR43`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Settings theme/layout/toggles persist and take effect; defaults reset safely.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-46 — Keyboard & quick actions
**Implementation ticket:** `P01-FR46`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Shortcuts and command palette avoid conflicts, support accessibility and route correctly.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-47 — Onboarding & tutorials
**Implementation ticket:** `P01-FR47`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Onboarding permissions are contextual; users can skip and later revisit setup.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-51 — Privacy, backup & restore
**Implementation ticket:** `P01-FR51`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Backup/restore, migrations, secure tokens, delete/export and privacy review pass.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

**Phase exit gate:** all listed tickets DONE with evidence, all earlier-phase regression tests green, rollback documented.

## P02 — Tasks & internal scheduling

**Entry dependency:** P01. **Phase state:** IN PROGRESS (task and planner implementation branch; acceptance pending).

### FR-01 — Multi-list task management
**Implementation ticket:** `P02-FR01`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Create, rename, reorder, complete, delete and restore lists/tasks; verify restart persistence and duplicate IDs.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-02 — Quick task capture
**Implementation ticket:** `P02-FR02`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Capture by keyboard, paste and drag/drop; ensure invalid/empty inputs do not create records.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-03 — Task attachments
**Implementation ticket:** `P02-FR03`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Attach and reopen links/images/files after restart; test missing files, oversized payloads and revoked file access.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-04 — Smart task recommendations
**Implementation ticket:** `P02-FR04`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Recommendation order is deterministic across due dates, importance and ties; explain chosen task.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-05 — Task details & scheduling
**Implementation ticket:** `P02-FR05`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Due date alone never schedules; valid start/end creates exactly one linked internal block and edit/delete reconciles atomically.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-06 — Sticky floating to-do
**Implementation ticket:** `P02-FR06`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Panel opens once, pins/moves/resizes, restores on relaunch and never loses unsaved edits.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-29 — Task and time-block planning
**Implementation ticket:** `P02-FR29`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Scheduling and rescheduling use stable task/block linkage; proposed untimed schedule requires approval.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

**Phase exit gate:** all listed tickets DONE with evidence, all earlier-phase regression tests green, rollback documented.

## P03 — Calendar & external provider integrations

**Entry dependency:** P02. **Phase state:** IN PROGRESS (calendar views and provider adapters implemented locally; live provider acceptance pending).

### FR-24 — Day/week/month/year calendar
**Implementation ticket:** `P03-FR24`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Day/week/month/year render correct boundaries, navigation, timezone and empty states.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-25 — Interactive weekly planner
**Implementation ticket:** `P03-FR25`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Drag create/move/resize/cancel, snapping, overlaps and keyboard alternatives all pass UI tests.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-26 — Apple Calendar integration
**Implementation ticket:** `P03-FR26`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** EventKit denied/revoked permission is safe; read-only import and consent-gated publish tested.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-27 — Google Calendar integration
**Implementation ticket:** `P03-FR27`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** OAuth PKCE, token refresh, incremental pagination, 429 retry and consent-gated remote mutations tested.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-28 — Calendar filters & holidays
**Implementation ticket:** `P03-FR28`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Filters persist; holiday duplicates and all-day/timezone events are handled.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

**Phase exit gate:** all listed tickets DONE with evidence, all earlier-phase regression tests green, rollback documented.

## P04 — Timers, prompts & logging

**Entry dependency:** P01; P02 for linked activity. **Phase state:** NOT STARTED (unverified).

### FR-08 — Pomodoro timer
**Implementation ticket:** `P04-FR08`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Focus/break phases and cycle count survive pause, sleep and relaunch with persisted deadlines.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-09 — Stopwatch & countdown
**Implementation ticket:** `P04-FR09`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Stopwatch elapsed, laps and countdown expiry remain correct after sleep and clock change.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-10 — Deep Work mode
**Implementation ticket:** `P04-FR10`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Deep Work preset uses same timer engine and records distinct session type without duplicate state.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-11 — Repeating focus alarms
**Implementation ticket:** `P04-FR11`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Recurring alarm schedules against absolute time; sleep/wake and disabled state never flood notifications.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-12 — Focus overlays & effects
**Implementation ticket:** `P04-FR12`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Effects obey Reduce Motion, multiple displays and cancellation; no overlay remains stuck.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-13 — Timer alerts & sounds
**Implementation ticket:** `P04-FR13`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Sound/notification settings honor permission denial, mute, snooze and duplicate delivery.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-14 — Floating focus widgets
**Implementation ticket:** `P04-FR14`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Floating timer and desktop control reflect one session; close/reopen does not reset countdown.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-15 — Automatic activity prompts
**Implementation ticket:** `P04-FR15`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Prompts fire for defined intervals, reconcile missed periods and never invent activity data.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-16 — Floating quick-log panel
**Implementation ticket:** `P04-FR16`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Quick log handles submit/skip/cancel and keyboard focus; no duplicate rows on double submit.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-17 — Voice activity logging
**Implementation ticket:** `P04-FR17`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Voice permission denied/unavailable returns actionable error; no demo transcript can be saved.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-18 — Planned vs actual timeline
**Implementation ticket:** `P04-FR18`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Planned and logged rails show cross-midnight, overlap and empty-state data accurately.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-19 — Manual activity entries
**Implementation ticket:** `P04-FR19`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Create/edit/delete logs persist; invalid duration and duplicate submit are rejected.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-20 — Natural-language time entry
**Implementation ticket:** `P04-FR20`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Natural-language parser handles explicit time, noon, midnight, ambiguity and manual fallback.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-21 — Smart classification
**Implementation ticket:** `P04-FR21`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Classification precedence is deterministic; unknown activity is not silently mislabeled as productive.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-22 — Custom classification dictionary
**Implementation ticket:** `P04-FR22`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Rule CRUD and correction learning persist, handle collisions and import/export safely.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-23 — Quiet hours & skip handling
**Implementation ticket:** `P04-FR23`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Overnight quiet hours and skip/missed policy work through restart and timezone change.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

**Phase exit gate:** all listed tickets DONE with evidence, all earlier-phase regression tests green, rollback documented.

## P05 — Analytics, widgets, media & utilities

**Entry dependency:** P01–P04. **Phase state:** NOT STARTED (unverified).

### FR-07 — Desktop task widgets
**Implementation ticket:** `P05-FR07`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Widget reads App Group data and actions propagate once to app; test installed extension independently.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-30 — Productivity dashboard
**Implementation ticket:** `P05-FR30`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Dashboard totals match reference fixtures and explain tracked/untracked time.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-31 — Category charts
**Implementation ticket:** `P05-FR31`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Category charts reconcile to underlying logs with no double count.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-32 — Focus performance insights
**Implementation ticket:** `P05-FR32`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Focus insight calculations use duration, not entry count; test clipped periods.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-33 — Historical reports
**Implementation ticket:** `P05-FR33`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** History filters and boundary queries include crossing entries and correct totals.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-34 — Data export
**Implementation ticket:** `P05-FR34`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** CSV/JSON exports round-trip with Unicode, timezone and large datasets.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-37 — Music controls
**Implementation ticket:** `P05-FR37`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Media control failure/permission denial does not show false playback success.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-38 — Music visualizer
**Implementation ticket:** `P05-FR38`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Visualizer respects paused media, battery usage and Reduce Motion.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-44 — File shelf & clipboard
**Implementation ticket:** `P05-FR44`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Clipboard retention and file shelf respect permissions, cleanup and sensitive-content controls.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-45 — System controls & webcam
**Implementation ticket:** `P05-FR45`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Unsupported system controls are disabled truthfully; webcam/mic permissions handled.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

**Phase exit gate:** all listed tickets DONE with evidence, all earlier-phase regression tests green, rollback documented.

## P06 — Cloud & Android

**Entry dependency:** P02–P05 and stable data contracts. **Phase state:** NOT STARTED (unverified).

### FR-48 — Cloud account & synchronization
**Implementation ticket:** `P06-FR48`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Auth, RLS, pagination, tombstones, retry/backoff and account isolation pass two-user tests.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-49 — Android companion
**Implementation ticket:** `P06-FR49`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Android tasks/calendar/logging/timers work offline and sync after reconnect; notification constraints documented.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-50 — Cross-device task/timer sharing
**Implementation ticket:** `P06-FR50`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Concurrent device edits converge under documented conflict policy; duplicate delivery is idempotent.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

**Phase exit gate:** all listed tickets DONE with evidence, all earlier-phase regression tests green, rollback documented.

## P07 — Full core regression & pause checkpoint

**Entry dependency:** P00–P06. **Phase state:** NOT STARTED (unverified).

**Tickets:** REL-01 end-to-end macOS regression; REL-02 Android/cloud offline and two-user isolation tests; REL-03 signed package and clean-install/upgrade/restore; REL-04 accessibility/privacy/security review; REL-05 tag `core-complete` with known gaps and obtain explicit pause/continue decision.
**Exit gate:** every P00–P06 feature verified, no critical regression, installable core release candidate; P08 remains NOT STARTED until authorized.

## P08 — Optional notch integration — LAST

**Entry dependency:** P07 plus explicit user opt-in and license approval. **Phase state:** NOT STARTED (unverified).

### FR-35 — Dynamic Island / notch
**Implementation ticket:** `P08-FR35`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Notch can be enabled/disabled without core schema changes; no core dependency on notch.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-36 — Notch live activities
**Implementation ticket:** `P08-FR36`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Live activities mirror shared timer/media state; close and restart recover correctly.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-39 — Notch calendar
**Implementation ticket:** `P08-FR39`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Notch calendar uses read-only event projections and never publishes events silently.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

### FR-40 — Multi-display notch
**Implementation ticket:** `P08-FR40`. **Technical path:** define domain contract and UI states; implement service/repository with typed errors; bind relevant SwiftUI/AppKit or Android surface; add settings/toggles and migration only where required. **Specific verification:** Notch hit testing and geometry work on physical/simulated notch and external monitors.
**Evidence:** tests, screenshots or screen recording where UI is involved, clean build log, PR URL, merged SHA.

**Phase exit gate:** all listed tickets DONE with evidence, all earlier-phase regression tests green, rollback documented.

## Critical cross-feature sequencing
- P01 shell and shared settings before any floating/notch surfaces.
- P02 TaskSchedule/CalendarBlock linkage before P03 external providers.
- P04 one timer state machine before widgets and live activities.
- P05 media controls and visualizer must work in a non-notch surface; P08 only adds notch presentation.
- P06 sync after migrations, stable IDs and conflict policy.
- P08 must never modify P01–P07 data contracts just to display notch content.
