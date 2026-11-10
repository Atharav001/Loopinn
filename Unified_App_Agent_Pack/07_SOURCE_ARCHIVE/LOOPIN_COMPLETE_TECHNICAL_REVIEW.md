# Loopin — Complete Technical Project Review

**Review scope:** complete source and project configuration in the `Loopin` folder, plus repository `PRD.md`, `DESIGN.md`, `IMPLEMENTATION_PLAN.md`, and `backend_schema.sql`.

**Project type:** native macOS menu-bar productivity app built with Swift, SwiftUI, AppKit, WidgetKit, SQLite, and JSON files. The app target declares macOS 14 as its minimum. A macOS desktop task widget is a separate extension target. There is no Android client or implemented web/backend client in this repository.

## 1. Executive assessment

Loopin already contains a broad, usable local macOS app: task capture and management, floating windows, Pomodoro/countdown/stopwatch, interval alarms, interval activity logging, a local rule classifier, timesheet/calendar/reporting screens, speech input, and a desktop task widget. Timesheet entries and classification rules are stored in local SQLite; task lists, settings, and attachment files are stored under Application Support as JSON/files.

The cross-device and Google Calendar screens overstate the implementation. `SyncStore.performSync()` only waits briefly and reloads local stores; `GoogleCalendarSyncEngine` fabricates account/calendar IDs and simulated sync tokens and never makes an OAuth or Calendar API request. `backend_schema.sql` is a schema/policy proposal, not evidence of a connected server. Treat these as prototypes until a real authenticated transport, durable sync protocol, and provider integration are implemented.

The roadmap in `IMPLEMENTATION_PLAN.md` is partly complete and partly stale: local timesheet, logging, classification, reports, animations, and a macOS widget are present, while backend/account sync, actual Google Calendar sync, Android, and deployment are not. The app currently launches directly into the Timesheet window. PRD/DESIGN describe aspirations, not all current behavior.

## 2. Repository and build map

| Path | Responsibility |
|---|---|
| `Loopin/Loopin.xcodeproj/project.pbxproj` | Checked-in Xcode project and target membership. |
| `Loopin/project.yml` | XcodeGen-style project definition for the app and widget. |
| `Loopin/Info.plist` | App metadata, menu-bar app flag, minimum system version, speech and microphone usage descriptions. |
| `Loopin/LoopinWidget/Info.plist` | Widget extension metadata. |
| `Loopin/LoopinApp.swift` | SwiftUI app entry point and AppDelegate adaptor; no normal document/window scene. |
| `Loopin/App/` | App lifecycle, status-bar menu, window/panel creation and shared view model wiring. |
| `Loopin/Models/` | Task, attachment, settings, timer, timesheet, classification, and calendar-link data types. |
| `Loopin/Stores/` | JSON persistence, SQLite access, observable stores, and a simulated sync store. |
| `Loopin/Engines/` | Timer/alarm/reminder logic, attention overlays, voice, local classification, NL parsing, URL metadata, calendar and interval logging. |
| `Loopin/Views/` | Task, timer, settings, timesheet, calendar, reports, prompt, and shared component UI. |
| `Loopin/LoopinWidget/` | WidgetKit task list widget. |
| `Loopin/Resources/` | Asset catalog and user-facing string constants. |
| `Loopin/Tests/TimesheetModuleTests.swift` | Handwritten assertion-based test harness, runnable through the app’s `--run-tests` launch argument. |
| `backend_schema.sql` | Proposed Supabase/Postgres tables and row-level policies. |
| `PRD.md`, `DESIGN.md`, `IMPLEMENTATION_PLAN.md` | Product requirements, visual specification, and phase roadmap. |

Build setup: Swift 5 language mode, macOS 14, automatic signing, hardened runtime enabled, bundle IDs `com.loopin.app` and `com.loopin.app.widget`. The XcodeGen file includes the test source in the app target rather than declaring a separate XCTest target. The checked-in `.xcodeproj` is also present; keep both project representations in sync if XcodeGen is part of the normal workflow.

## 3. Runtime composition and launch flow

1. `LoopinApp` adapts `AppDelegate`; `LSUIElement=true` makes Loopin an agent/menu-bar app rather than a Dock-first app.
2. `AppDelegate.applicationDidFinishLaunching` creates `SettingsStore`, `TaskStore`, a `TimerSession`, `PanelController`, and `StatusBarController`.
3. The AppDelegate observes timer phase/reminder state to refresh the menu-bar icon; wires `ReminderScheduler`; registers notification actions and requests alert/sound permission.
4. It wires the repeating focus alarm to `AttentionOverlayManager` and sets up `LoggingPanelController` with the shared interval engine and stores.
5. After a short delay it focuses the Timesheet window. This is currently the first visible surface, even though the app is a menu-bar utility.
6. `PanelController` constructs separate floating windows for todo, timer, alarms, settings, timesheet, and reports. `WindowController` persists per-window position and pin state through settings. The menu-bar menu opens each window, exposes “Log Current Activity Now,” and quits.
7. `AppState` is a dependency container for stores and engines, but current launch wiring largely constructs and passes services through `PanelController` and shared singletons; it is not the sole composition root.

## 4. Feature inventory and actual behavior

### 4.1 Task capture and to-do management

- `Task` supports title, completion, creation/due dates, list order, size, framing, first step, importance, color, icon, and link/image/document attachments.
- `TaskStore` loads and saves `tasks.json`, debounces writes, restores deleted items when asked, removes completed tasks, sorts/reorders tasks, and triggers widget refreshes.
- `QuickAddView` accepts typed text, pasted content, file chooser attachments, and drag/drop. `CaptureClassifier` prioritizes image, URL, then date parsing. `LinkMetadataFetcher` asynchronously fetches page HTML title and `/favicon.ico`.
- `TaskListView` separates open tasks into Today/Later and completed sections, supports reorder, edit, complete, delete/undo, clear-completed confirmation, and drops. `TaskRowView` contains the richer row-level edit and attachment interactions.
- `WhatNowSelector` uses a deterministic ladder: due/overdue/no-date quick win, then smallest task due today, then oldest open task. `WhatNowView` is the recommendation UI.
- `TodoWindowView` hosts the capture and task surfaces.
- **Review concern:** document files are copied under a generated UUID filename, but `FileAttachment` stores the original filename and the row uses that as its attachment reference. Verify opening/downloading is wired to the generated stored file; current model as written does not preserve that stored filename.
- **Review concern:** URL metadata performs network requests to arbitrary pasted URLs. Add redirect/size/content-type limits and careful error handling; do not block capture on this work.

### 4.2 Timers, alarms, and attention

- `TimerSession` is observable state for Pomodoro, countdown timer, stopwatch, linked task, completed cycles, and reminder status.
- `TimerEngine` owns ticking, focus/break transitions, timer completion, pause/resume/reset, and a policy that editing a running preset may extend but not shorten the current phase. Stopwatch counts upward.
- `TimerView` presents mode and preset controls, timer settings, progress, controls, linked task context, and a confirmation before discarding active work to switch mode.
- `FocusIntervalAlarmEngine` is an independent repeating 2/3/5/10/15/20/25-minute alarm. It persists only running flag and interval; when restarted, it begins a fresh interval. Its ticking is an in-process `Timer`, so it does not fire while the app process is terminated.
- `ReminderScheduler` implements two-stage timer-end reminders (status-bar pulse, then native notification with Start Focus/Break, Snooze, Dismiss actions). `AppDelegate` handles notification actions.
- `AttentionOverlayManager`, `AttentionSoundPlayer`, and shared views implement attention overlays/sounds and stimulation intensity. `PresenceGlowView`, `BreathingGlowModifier`, `GlowModifier`, `RippleModifier`, `RippleConfirmRing`, and `EdgeSlideNudgeView` provide visual motion primitives.
- **Review concern:** `TimerSession` and elapsed timer state are initialized in memory and are not persisted as a recoverable deadline. A running session is lost across process exit/relaunch. Prefer persisted absolute deadlines plus paused remaining duration over persisting a one-second counter.
- **Review concern:** the interval logging engine starts enabled by default as an in-memory property and is not visibly bound to a persisted user preference in its model. Verify settings switches really control this lifecycle and expose clear controls.
- **Review concern:** speech recognition requests on-device recognition when supported, but framework/device availability can vary. Present the actual recognition capability and permission state and ensure no silent cloud fallback is implied.

### 4.3 Timesheet and activity logging

- `TimesheetEntry` carries planned/logged kind, interval, text, input method, category/subcategory, productivity, Calendar event ID, update timestamp, and device ID. Skips are explicit logged rows.
- `TimesheetStore` loads the selected day/week and exposes create/update/delete, quick-add planned/logged, skip, and sample-day helpers.
- `TimesheetWindowView` contains Dual Rails, Week Calendar, Analytics & Reports, Dictionary, and Focus & Prompts tabs, direct prompt action, plan quick-add, and sample data controls.
- `TimesheetQuickAddView` supports natural-language planned blocks and quick manual entries. `TimesheetNLPParser` uses `NSDataDetector` to extract one date/time and defaults to a 30-minute duration.
- `TimesheetCalendarView` and `TimesheetTimelineView` provide calendar/timeline browsing and planned/logged visualization. The actual layout is the code; compare it with DESIGN.md before treating every specified overlay detail as complete.
- `IntervalLoggingEngine` counts down in-process, opens a prompt, tracks a one-minute overdue state, logs typed/voice input or explicit skipped entry, then restarts its interval. `LoggingPanelController` creates a floating full-screen auxiliary `NSPanel`; `LoggingPromptPanel` owns the UI.
- `ClassificationEditorView` allows correction; `TimesheetStore` persists updated entries; report charts aggregate logged rows.
- **Review concern:** interval boundaries are reconstructed as `now - interval` at the prompt, and interval restarts after responding. Delayed prompts, system sleep, app suspension, and long unanswered periods do not reconstruct actual wall-clock intervals. Persist scheduled/actual boundaries and define missed-interval catch-up policy.
- **Review concern:** the prompt view’s complete action and category/classifier integration should be traced in future edits; engine-level `completePrompt` trusts passed category/productivity, so the caller must classify and honor user corrections.
- **Review concern:** `TimesheetNLPParser` detects only a single date match and falls back to now; it does not parse arbitrary duration phrases robustly. Label the supported syntax and validate past/future and duration cases.

### 4.4 Classification and reports

- `ClassificationRule.defaultStarterRules` seeds local phrases across Deep Work, Meetings, Learning, Admin, Exercise, Meals, Commute, Rest, Social Scrolling, Binge Watching, Movie Watching, YouTube Watching, Gaming, and Other Unproductive.
- `LocalClassifier` normalizes case/whitespace; prioritizes user-defined rules and longer phrases; uses escaped regex word-boundary matching; unmatched text is Uncategorized.
- `ClassificationStore.learnCorrection` saves the complete corrected raw phrase as a user rule. Import/export of rules as JSON exists.
- `ReportsView` presents period filters, duration totals, productive/neutral/wasteful ratio, categories, peak focus hours, and a “Coming Soon” AI slot. It uses local SQLite reads.
- **Review concern:** rules learned from a full raw sentence can be overly broad/specific; add phrase extraction/editor flow and deterministic precedence tests. Ensure punctuation and non-Latin token boundaries work as expected.
- **Review concern:** reports’ “Deep Work” number is all productive time, not strictly Deep Work; relabel to Productive or calculate category-specific time. “Total Tracked” excludes neutral/wasteful? Code sums productive+neutral+wasteful, while skipped and uncategorized rows are excluded; clearly define what total means.
- **Review concern:** for Today, `ReportsView` reads `TimesheetStore.entries`, which are for `selectedDate`, not necessarily today. Other ranges use current wall clock. Align the selected date and period semantics.
- **Review concern:** peak focus currently counts rows, not minutes, and only plots hours 06–23. Consider duration-weighted totals and explicit timezone/day boundary policy.

### 4.5 Settings and widget

- `SettingsView` exposes settings tabs, app/timer/reminder/stimulation configuration, speech status, and Sync & Calendar cards. `SettingsStore` persists `settings.json` atomically with a 400 ms debounce and has a legacy window-frame migration.
- `LoopinWidget` is a read-only WidgetKit task widget displaying up to five open tasks, refreshing on a 15-minute policy and `WidgetCenter` reload from task writes.
- **Review concern:** the widget target reads `JSONStore` in its own extension process. App and extension need a shared App Group container for reliable shared files; current config shows no App Group entitlement/container, so the extension may look in its own Application Support sandbox and not see app tasks. Verify on-device and implement App Group storage if needed.

## 5. Data and persistence architecture

### Local JSON/files

`JSONStore.directory` is `~/Library/Application Support/Loopin` (resolved via FileManager). It migrates contents from a legacy `Focus` directory without overwriting target files. It persists `tasks.json` and `settings.json`, with `Images/` and `Documents/` subdirectories. JSON uses ISO-8601 dates, sorted/pretty output, atomic writes.

### Local SQLite

`SQLiteManager` opens `loopin_timesheet.sqlite` under Application Support, enables WAL, `synchronous=NORMAL`, foreign keys, and serializes operations on a dispatch queue. It creates:

- `timesheet_entries`: entry values, `gcal_event_id`, `updated_at`, `device_id`, soft-delete flag; indexes by start/kind and update timestamp.
- `classification_rules`: phrase unique key and classification metadata.
- `calendar_links`: local provider/account/calendar IDs/sync token/last-sync/enabled state.

CRUD uses prepared statements for user data and a soft-delete path. No migration version table or structured migration runner is visible; schema evolution currently depends on `CREATE TABLE IF NOT EXISTS`. Add explicit migration versions before shipping schema changes.

### Proposed remote schema

`backend_schema.sql` defines Postgres tables for entries, classification rules, and Calendar links with `auth.users` ownership, indexes, soft delete, and owner policies. It does not configure a client, auth, endpoint, secrets, account lifecycle, migration tooling, or deployment. The entry sync timestamp is client supplied; policy review must consider authenticated user identity, privileged service-role exposure, anonymous roles, and all CRUD paths. The SQL uses unconditional `CREATE POLICY`, which will fail if rerun after policy creation; make migration application repeatable or explicitly version it. The remote tables do not store task JSON, settings, or attachments, so “sync all app data” is not defined.

## 6. Architecture at a glance

```text
SwiftUI screens ──observe──> Observable stores / TimerSession
       │                           │
       │ actions                   ├── TaskStore ──> JSONStore ──> tasks/settings JSON + attachment files
       │                           ├── TimesheetStore ──> SQLiteManager ──> local SQLite
       └── controllers             ├── ClassificationStore ──> SQLiteManager + LocalClassifier
           ├── WindowController    ├── SyncStore ──> local reload simulation only
           ├── LoggingPanel        └── GoogleCalendarSyncEngine ──> simulated operations only
           └── StatusBarController

TimerEngine / alarm / logging engines ──> AppKit timers, notifications, floating panels
SpeechRecognitionService ──> Speech + AVFoundation microphone pipeline
LoopinWidget extension ──> JSONStore read (shared-container setup needs verification)
```

## 7. Important implementation findings and risks

Prioritize these before describing the product as cloud-connected or relying on unattended logging:

1. **Cloud sync is a placeholder.** Implement auth, configuration, remote client, upload/download, dirty queue, retry/backoff, conflict handling, tombstones, account isolation, logout, and status only after actual successful calls.
2. **Google Calendar is a placeholder.** Replace fabricated account/calendar IDs and tokens with OAuth authorization, secure token storage, Calendar API calendar creation, event insert/update/delete, incremental syncToken pull, pagination, 410 full-sync recovery, recurrence handling policy, and remote-change reconciliation. Webhooks require a deployed public backend endpoint; desktop-only code cannot receive Google push notifications directly in a robust way.
3. **RLS needs a deliberate review.** Test policies using two user identities, verify no anon reads/writes, restrict OAuth token secrets, and avoid service-role credentials in clients. Decide whether deleting rows is physical or tombstone based for replication.
4. **Time boundaries / DST.** Current entry queries filter on start time only. Entries overlapping midnight/week boundaries can be omitted from a day report. Use overlap condition `start_at < rangeEnd AND end_at > rangeStart`, and compute durations clipped to report range where appropriate. Test timezone and daylight-saving boundaries.
5. **SQLite safety and migrations.** The manager is marked `@unchecked Sendable`; it serializes most operations, but database open/close/error paths and statement failures need consistent handling. Add migration versions, transactional migration, backup/export, and corruption recovery.
6. **Widget data sharing.** Configure App Group entitlements for app and widget and put shared task storage there, or use an approved shared data mechanism. Ensure icon and file assets resolve from the shared container.
7. **Task attachment data integrity.** Store the generated attachment filename alongside its display/original name; implement read/open/delete and orphan cleanup. Security-scope bookmarks may be required if referencing external files instead of copying.
8. **Scheduled work and app lifecycle.** In-process `Timer` does not guarantee prompts while the app is suspended/terminated. Decide whether to use UserNotifications/local notifications and reconcile due intervals on wake, while preserving explicit skipped/missed records.
9. **Timer/report terminology and behavior.** Correct productive vs Deep Work labels; align selected date and report periods; use correct interval overlap math.
10. **Privacy and network boundaries.** Document speech processing behavior, retention, data deletion/export, and network use for link metadata, Google OAuth, and future sync. Request microphone/speech only when the user chooses voice capture.
11. **Accessibility and motion.** DESIGN.md requires reduced-motion fallbacks. Verify each looping animation checks macOS Reduce Motion and stops when idle; add keyboard/focus/VoiceOver states for floating prompts.
12. **Project reproducibility.** Record how the project is generated, build configuration, app/widget entitlements, and test invocation. Keep `.xcodeproj` and `project.yml` synchronized.

## 8. Comprehensive implementation process

This is the recommended sequence from the current codebase to a reliable release. Keep local macOS value independent from cloud and calendar dependencies.

### Phase A — Establish a safe baseline

1. Record current app and widget targets, signing team, macOS deployment target, and generation/build procedure. Compare Xcode project target membership with `Loopin/project.yml`.
2. Create a release checklist covering local data backup, migration, permission prompts, supported macOS versions, accessibility, and recovery.
3. Turn `TimesheetModuleTests.runAllTests()` into a proper XCTest target and separate unit/integration/UI coverage. Add coverage for current intended behavior before refactoring.
4. Add a debug-only diagnostics surface for app version, storage paths, schema version, notification permission, speech permission, and sync-provider state without exposing secrets.

### Phase B — Correct local persistence and task reliability

1. Introduce a versioned SQLite migration table and transactional ordered migrations; migrate legacy data without destructive replacement.
2. Make every SQLite operation check prepare/bind/step results, return typed errors, and report failures in UI instead of silently printing/ignoring them.
3. Implement range-overlap queries and report duration clipping. Add tests for midnight, week boundaries, timezone changes, and DST.
4. Fix attachment metadata so stored UUID path and user-facing filename/type are distinct; implement open, remove, missing-file recovery, and orphan cleanup.
5. If app/widget shared tasks are required, add App Group entitlement to both targets, resolve shared container URL, migrate existing app-support files, then test the extension independently.
6. Persist timer sessions as mode, phase, pause state, absolute deadline/remaining duration, linked task ID, and cycle count. On launch, reconcile deadlines and do not assume timers ticked while asleep.
7. Add explicit error/empty states and settings export/import/backup before changing storage formats.

### Phase C — Finish interval logging and classification

1. Persist logging enabled state, allowed interval, timezone, and last completed interval boundary. Validate interval choices in the model, not only UI.
2. Replace decrement-only wall-clock counters with date-based scheduling. On launch/wake, detect due intervals; define whether overdue intervals create one catch-up prompt, multiple missed markers, or a summarized gap.
3. Make prompt submit classify text through `ClassificationStore`; allow review/edit before commit. Ensure skip creates the documented explicit marker and never stores guessed content.
4. Make mic authorization and recognition errors actionable; use on-device recognition when available and clearly disclose device-dependent behavior. Stop audio cleanly on dismiss, app deactivation, or error.
5. Improve correction learning: allow users to choose a phrase/keyword, detect duplicate/overlapping rules, preserve a deterministic tie-break, and support editing/deleting rules.
6. Add fixtures for empty text, punctuation, multiword phrases, overlapping rules, multilingual text, skipped logs, permission denial, sleep/wake, and late submission.

### Phase D — Complete the product’s local macOS experience

1. Audit every screen against PRD and DESIGN: dual planned/logged view, week calendar, log editing, reports, settings, keyboard access, empty/error states, and reduced motion.
2. Fix reports: user-facing labels, selected-date semantics, inclusive/exclusive range rules, uncategorized treatment, skipped-time treatment, and duration-weighted peak hours.
3. Validate natural language quick-add, clearly constrain accepted expressions, and test ambiguous/past dates and default durations. Provide manual start/end editing as a reliable fallback.
4. Validate all windows across displays/full-screen spaces and after display-resolution changes; persist restored frames safely within a visible screen.
5. Validate notifications and overlay behavior under Do Not Disturb, permissions denied, app hidden, full-screen apps, and app restart.
6. Add VoiceOver labels, keyboard focus paths, high contrast checks, Reduce Motion behavior, and non-color-only category cues.
7. Do not ship “Coming Soon” integrations as working controls; show “not connected” until provider setup is real.

### Phase E — Implement actual cross-device backend sync

1. Define scope: which records sync (tasks, timesheet entries, classification rules, settings, attachment blobs), account deletion/export, device identity, and supported offline behavior.
2. Choose and configure backend (the SQL suggests Supabase/Postgres). Add versioned migrations, auth setup, staging and production environments, and secret management. Never put service-role credentials in the macOS app.
3. Review and test every RLS policy with owner A, owner B, unauthenticated, expired token, and all CRUD operations. Decide whether client may set `user_id`, `updated_at`, and `is_deleted`; enforce identity server-side where appropriate.
4. Add a client auth lifecycle: sign in/out, refresh, revoke, account deletion, secure token storage in Keychain, and no data cross-contamination after account switches.
5. Design a sync protocol: local outbox/dirty flags, stable IDs, page cursors, idempotent upserts, server timestamps or version fields, tombstones, retry/backoff, network reachability, and conflict resolution. Last-write-wins alone needs clock-skew strategy and deterministic tie-breaking.
6. Implement pull and push in batches, commit server cursors only after successful local transaction, and ensure offline UI continues working. Surface pending/error/last-success state honestly.
7. Implement attachment upload/download with size limits, content types, per-user object paths, signed access if needed, deletion propagation, and backup/restore.
8. Test two local profiles/devices, offline edits, duplicate retries, simultaneous edits, deleted rows, expired auth, large histories, and app upgrade while sync is queued.
9. Replace `SyncStore` simulation only after the complete adapter has working success/error semantics; never report “synced” after a local reload.

### Phase F — Implement real Google Calendar integration

1. Create Google Cloud project, OAuth consent configuration, client IDs, privacy/verification requirements, and least-privilege scope. Keep client secret server-side if required; use system browser authorization and OAuth PKCE where supported.
2. Store refresh/access tokens securely in Keychain; implement connect, revoke, disconnect, account-change handling, and token refresh.
3. On connection, list/create “Loopin Planned” and “Loopin Logged” calendars via Calendar API; save real IDs only after API success.
4. Map local create/update/delete to event insert/patch/delete; save returned event IDs in SQLite. Make operations idempotent and define mapping for skipped logs, category, timezone, all-day entries, and daylight saving.
5. Pull using `events.list` with `syncToken`, page through results, handle deletions/cancellations, and recover expired tokens with a full sync. Prevent sync echo loops with origin/version metadata.
6. Define remote-edit conflict behavior and apply changes transactionally. Handle rate limits, 401 refresh, 403 scope/configuration, network loss, and quota errors.
7. If push notifications are required, deploy an authenticated HTTPS webhook receiver, channel renewal/expiration handling, and server-side account mapping; otherwise use a documented foreground/background incremental sync strategy.
8. Test calendar edits from web/mobile, app edits, recurring events policy, timezone changes, token revocation, duplicate delivery, deleted calendars, and offline reconciliation.
9. Only then mark calendar connected in settings or display a successful sync timestamp.

### Phase G — Android client (separate project, later milestone)

1. Create a native Kotlin/Compose app and a shared API/data contract; do not imply Android exists in this macOS repo.
2. Implement Room local cache, auth, sync/outbox, rule import/export, and matching time/category semantics.
3. Build home timeline, planned/logged calendar, reporting, and edit flows with accessibility parity.
4. Implement foreground service/notifications only for a clearly justified ongoing logging use case; use notification inline reply/voice/skip actions and Android permission/policy declarations.
5. Validate delivery with screen off, Doze, OEM battery restrictions, notification denial, reboot, timezone/DST, and Play Console policy requirements.

### Phase H — Release and operations

1. Configure Developer ID signing, hardened runtime entitlements, notarization, versioning, and update distribution; verify microphone/speech/notification permission strings.
2. Build a clean-install and upgrade test matrix across supported macOS versions and Intel/Apple Silicon if both are supported.
3. Verify widget extension, menu-bar lifecycle, full-screen overlays, sleep/wake timers, migrations, backup restore, and uninstall/data-retention behavior.
4. Publish a privacy policy describing local data, speech processing, URLs fetched for metadata, Google Calendar, backend sync, retention, deletion, and diagnostics.
5. Add privacy-safe diagnostics/crash reporting only with consent and data minimization. Define support and migration rollback procedures.

## 9. Suggested acceptance criteria

- Task capture works offline, attachments reopen after restart, and widget displays the same task store.
- Timer survives sleep/restart according to documented rules and reports accurate remaining time.
- Every logging interval is accurately represented after sleep/wake, including explicit skipped/missed behavior.
- Classification is deterministic, editable, local, and has no per-entry model/API dependency.
- Reports match hand-calculated fixtures, including entries crossing date boundaries and skipped/uncategorized logs.
- Cross-device status only says synced after authenticated server acknowledgement; two users cannot read or mutate each other’s data.
- Calendar events created in either direction converge without duplicates, and provider errors never become false success.
- Motion respects Reduce Motion; all core flows are keyboard and VoiceOver usable.
- A clean install and a previous-version upgrade preserve or safely migrate user data.

## 10. Source file guide

### App and window orchestration

- `Loopin/LoopinApp.swift` — app entry and AppDelegate adaptor.
- `Loopin/App/AppDelegate.swift` — service setup, notifications, initial window.
- `Loopin/App/AppState.swift` — shared dependency container.
- `Loopin/App/StatusBarController.swift` — menu bar and window shortcuts.
- `Loopin/App/PanelController.swift` — constructs/coordinates windows and shared environments.
- `Loopin/App/WindowController.swift` — per-window frame/pin lifecycle.
- `Loopin/App/FloatingPanel.swift`, `PanelBridge.swift`, `LoggingPanelController.swift` — native panel behavior and view bridge.

### Models and stores

- `Loopin/Models/Task.swift`, `Attachment.swift` — task domain and attachment references.
- `Loopin/Models/AppSettings.swift`, `TimerPreset.swift`, `TimerSession.swift` — settings and timer state.
- `Loopin/Models/TimesheetEntry.swift`, `ClassificationRule.swift`, `CalendarLink.swift` — log and future sync models.
- `Loopin/Stores/JSONStore.swift` — app-support JSON and file data.
- `Loopin/Stores/TaskStore.swift`, `SettingsStore.swift` — observable JSON-backed stores.
- `Loopin/Stores/SQLiteManager.swift` — SQLite connection/schema/CRUD.
- `Loopin/Stores/TimesheetStore.swift`, `ClassificationStore.swift` — observable local domain stores.
- `Loopin/Stores/SyncStore.swift` — current local sync simulation.

### Engines

- `TimerEngine.swift`, `FocusIntervalAlarmEngine.swift`, `IntervalLoggingEngine.swift` — timer and interval state machines.
- `ReminderScheduler.swift`, `AttentionOverlayManager.swift`, `AttentionSoundPlayer.swift` — attention and alerts.
- `SpeechRecognitionService.swift` — Speech/AVFoundation input.
- `LocalClassifier.swift`, `TimesheetNLPParser.swift`, `CaptureClassifier.swift`, `WhatNowSelector.swift` — local parsing/selection.
- `GoogleCalendarSyncEngine.swift` — current mocked Calendar adapter.
- `LinkMetadataFetcher.swift` — URL metadata requests.

### Views

- `TaskListView.swift`, `TaskRowView.swift`, `QuickAddView.swift`, `WhatNowView.swift`, `TodoWindowView.swift` — task capture and management.
- `TimerView.swift`, `TimerWindowView.swift`, `IntervalAlarmsView.swift`, `AlarmsWindowView.swift` — timing surfaces.
- `TimesheetWindowView.swift`, `TimesheetQuickAddView.swift`, `TimesheetTimelineView.swift`, `TimesheetCalendarView.swift`, `LoggingPromptPanel.swift`, `ClassificationEditorView.swift` — logging, planning, calendar, and classification.
- `ReportsView.swift`, `CategoryBreakdownChart.swift`, `ProductiveRatioBar.swift`, `ReportsWindowView.swift` — analytics.
- `SettingsView.swift`, `SettingsWindowView.swift` — preferences and integration status UI.
- `Views/Components/` — theme, header, color conversion, glow, ripple, nudge, and presence components.
- `Loopin/LoopinWidget/LoopinWidget.swift` — WidgetKit extension UI/provider.

## 11. Documentation caveat

This review is a source-level assessment of the repository state. It does not claim that every runtime path has been exercised on a real Mac, that Google/Supabase credentials exist elsewhere, or that backend RLS policies have been security-tested. The codebase itself contains a custom assertion test harness, but this review did not run builds or tests. Treat external-provider status as unimplemented unless separate deployment evidence is available.

