# Master Product Requirements Document

> Converted from the supplied Word artifact. Original section order retained.

# Unified Productivity App

MASTER PRODUCT REQUIREMENTS DOCUMENT  |  Version 1.0  |  10 November 2026

Full-scope first public release • macOS primary application • focused Android companion

## 1. Executive definition

Build one integrated, offline-first macOS productivity platform combining Aura’s notch/media/panel experiences, Loopin’s task/focus workflows, and Logtrackin’s calendar/activity analytics. All 51 approved capabilities are required before the first public release. Internal milestones and private testing builds are permitted.

### 1.1 Confirmed decisions

- Hybrid surfaces: menu bar and notch start at login/launch; dashboard opens only on demand.
- A task with an explicit start AND end time creates/updates an internal calendar block automatically. A due date, estimate, or incomplete time does not. Untimed tasks require approval before scheduling.
- Publishing internally scheduled blocks to Apple or Google Calendar requires explicit approval; never silently publish.
- Android is a focused companion for tasks, calendar, activity logging, timers and synchronization; macOS-only notch/media/system utilities need not be replicated.
- All 51 approved features are release-blocking, subject to measurable acceptance criteria.
### 1.2 Scope boundaries

In scope: all 51 features in Sections 4–11. Out of scope by default: Windows/iOS clients, AI cloud inference as a requirement, website blocking, an enterprise collaboration suite, and full Android parity for macOS-specific utilities. Such additions require change control.

## 2. Users, jobs and success measures

Primary persona: an individual macOS user who wants to plan tasks, stay focused, record actual time, and review productivity without leaving the menu bar. Secondary persona: the same user using Android away from the Mac.

- Plan: capture a task, optionally specify a time interval, and see an internal calendar block without duplicate records.
- Execute: launch focus tools from notch/menu bar/widgets and receive reliable completion reminders.
- Reflect: respond to periodic logging prompts, classify time, and compare plan versus actual.
- Continue: edit on Android and safely reconcile changes when connected.
Release success gates: 100% of 51 feature acceptance checks pass; no known P0 data-loss/privacy defect; critical offline/sleep/restart paths pass; authenticated cross-account isolation tests pass; accessibility and permission-denied flows pass; signed/notarized macOS and installable Android builds pass.

## 3. Core behavior contracts

### 3.1 Canonical records

| Entity | Minimum contract |
| --- | --- |
| Task | ID, title, list, state, due date, priority, optional metadata and attachments |
| TaskSchedule | ID, task ID, start/end, timezone, approval state, revision |
| CalendarBlock | ID, source, schedule link (optional), interval, external mappings |
| ActivityLog | ID, start/end, text, input source, classification, skipped/missed status |
| TimerSession | ID, mode, phase, start/deadline, paused remaining, linked task, cycles |
| ClassificationRule | ID, phrase, category, productivity, precedence |
| SyncRecord | Stable ID, owner, version, tombstone, device, server cursor |

### 3.2 Task-to-calendar state machine

- Create task without a complete time interval → task only, no calendar block.
- Set valid start and end time → create exactly one linked internal block for that schedule; display the link on both task and calendar.
- Change interval → update linked block transactionally, not create a duplicate.
- Remove schedule → remove linked internal block after appropriate confirmation; preserve the task.
- Task completion does not automatically create an ActivityLog or assert that planned time was worked.
- External publish → show provider, destination calendar, event title, interval and permissions; only publish after explicit user approval. Editing an approved published event follows a clearly surfaced sync policy; provider disconnection never deletes local tasks.
- Conflicts, overlaps, overnight intervals and timezone changes show understandable validation or conflict resolution; an overlap is not silently discarded.
### 3.3 Global experience

At launch the app runs as a menu-bar utility with notch surface enabled where supported; the dashboard remains closed until opened by the user. Notch fallback works on non-notched displays. All surfaces read the same underlying domain services. Floating windows persist size/location within visible screen bounds. Users can open the dashboard from the menu bar, notch or keyboard shortcut.

### 3.4 Reliability and sync semantics

Local actions commit first; cloud transport runs asynchronously through a durable outbox. Sync supports create/update/delete, retry, pagination, conflict handling, authenticated ownership and status indicators. Timer deadlines are persisted and reconciled after sleep/restart; exact OS delivery is not promised while powered off. All activity analytics clip intervals to selected boundaries and define overlapping time handling.

## 4–11. Functional requirements and acceptance criteria

Every feature below is included in release scope. “Interaction” describes the user-facing action; “Dependency” identifies the principal implementation prerequisite; “Acceptance” is the minimum testable release condition. Detailed UI copy and visual designs are implementation specifications, not yet finalized.

## 4. Tasks & To-Do

### FR-01  Multi-list task management

Requirement / interaction: Create, rename, reorder and delete lists; add, edit, complete, star, move and restore tasks.

Dependencies: TaskStore, persistence.  Acceptance: Tasks and lists survive restart; ordering and undo remain correct.

### FR-02  Quick task capture

Requirement / interaction: Capture text, paste and drag/drop; parse supported metadata without blocking saving.

Dependencies: Task engine, capture UI.  Acceptance: Capture succeeds offline; unsupported content falls back to editable text.

### FR-03  Task attachments

Requirement / interaction: Attach/open/remove links, images and documents with stable stored IDs and metadata.

Dependencies: File storage, sync blobs.  Acceptance: Files reopen after relaunch; missing files show recovery state; no orphan leak.

### FR-04  Smart task recommendations

Requirement / interaction: Suggest a next task using explainable due date, importance and effort rules; allow dismissal.

Dependencies: Task engine, ranking.  Acceptance: Suggestion order is deterministic and never auto-completes or schedules.

### FR-05  Task details & scheduling

Requirement / interaction: Edit due date, priority, first step, estimate, start/end and task appearance.

Dependencies: TaskSchedule, calendar link.  Acceptance: Only complete time intervals create internal blocks; due dates alone do not.

### FR-06  Sticky floating to-do

Requirement / interaction: Open pinned movable task panel with list filters and completion actions.

Dependencies: Window manager, task engine.  Acceptance: Edits instantly appear in dashboard and widget; no duplicate panel instances.

### FR-07  Desktop task widgets

Requirement / interaction: Render tasks in WidgetKit; support permitted completion and quick-compose actions.

Dependencies: App Group, widget extension.  Acceptance: Widget and app show consistent tasks after restart and extension refresh.

## 5. Timers & Focus

### FR-08  Pomodoro timer

Requirement / interaction: Custom focus/short/long breaks, cycles, pause/resume, optional auto-advance.

Dependencies: Timer engine, notifications.  Acceptance: Transitions and remaining time reconcile after restart/sleep.

### FR-09  Stopwatch & countdown

Requirement / interaction: Start, pause, reset, laps for stopwatch; countdown deadline and completion.

Dependencies: Timer engine.  Acceptance: No negative time; laps are ordered; alarm fires once per completion.

### FR-10  Deep Work mode

Requirement / interaction: Launch a configurable long-focus preset and optionally link a task.

Dependencies: Pomodoro, task link.  Acceptance: Linked task is visible; focus mode does not silently log activity.

### FR-11  Repeating focus alarms

Requirement / interaction: Configure recurring interval reminders with enable/disable and snooze.

Dependencies: Scheduler, settings.  Acceptance: No duplicate alarms after app restart or interval change.

### FR-12  Focus overlays & effects

Requirement / interaction: Offer dimming, edge glow, ripple and completion celebration with intensity controls.

Dependencies: Focus state, accessibility.  Acceptance: Effects stop on dismissal and respect Reduce Motion.

### FR-13  Timer alerts & sounds

Requirement / interaction: Provide completion notifications, selected sounds, snooze and dismiss.

Dependencies: Notification permissions.  Acceptance: Denied permissions show fallback; no false notification-success state.

### FR-14  Floating focus widgets

Requirement / interaction: Show movable timer panels and desktop timer widget where supported.

Dependencies: Window manager, App Group.  Acceptance: All timer surfaces display one consistent session and controls.

## 6. Time Tracking & Logging

### FR-15  Automatic activity prompts

Requirement / interaction: Schedule configurable interval questions using absolute time boundaries.

Dependencies: Logging scheduler.  Acceptance: Quiet hours and sleep/wake recovery follow documented missed-prompt policy.

### FR-16  Floating quick-log panel

Requirement / interaction: Offer prompt text entry, category correction, submit and skip.

Dependencies: Activity service, panels.  Acceptance: Submitting produces exactly one log; skip never fabricates text.

### FR-17  Voice activity logging

Requirement / interaction: Request microphone/speech consent and transcribe with recording/error states.

Dependencies: Speech APIs, logging.  Acceptance: Denied/unavailable recognition never inserts demo or fabricated content.

### FR-18  Planned vs actual timeline

Requirement / interaction: Display planned blocks beside logged intervals with gap/overlap cues.

Dependencies: CalendarBlock, ActivityLog.  Acceptance: Edits refresh both rails; missing actual logs remain visibly unlogged.

### FR-19  Manual activity entries

Requirement / interaction: Create, edit, delete and browse planned/logged entries.

Dependencies: Activity service, DB.  Acceptance: Validation rejects invalid ranges; changes persist and sync.

### FR-20  Natural-language time entry

Requirement / interaction: Parse documented expressions with confirmation and manual fallback.

Dependencies: Parser, calendar.  Acceptance: Ambiguous dates/times require review; no silent wrong schedule.

### FR-21  Smart classification

Requirement / interaction: Apply deterministic rules to activity text and productivity type.

Dependencies: Classifier, taxonomy.  Acceptance: Identical input and rules yield identical category across platforms.

### FR-22  Custom classification dictionary

Requirement / interaction: Create/edit/delete user rules, correction learning and import/export.

Dependencies: Rule store, sync.  Acceptance: Rule precedence is explicit; corrections persist and can be undone.

### FR-23  Quiet hours & skip handling

Requirement / interaction: Configure overnight quiet periods; distinguish skipped, missed and unlogged.

Dependencies: Prompt scheduler.  Acceptance: No automatic prompts in quiet hours; analytics labels states correctly.

## 7. Calendar & Planning

### FR-24  Day/week/month/year calendar

Requirement / interaction: Navigate and edit calendar blocks across four views.

Dependencies: Calendar domain, rendering.  Acceptance: A block appears consistently in every view and across midnight.

### FR-25  Interactive weekly planner

Requirement / interaction: Drag to create; move/resize with snapping, cancel and keyboard alternative.

Dependencies: Grid interactions, schedule service.  Acceptance: Create/move/resize pass overlap, edge, timezone and minimum-width tests.

### FR-26  Apple Calendar integration

Requirement / interaction: Read authorized EventKit calendars; publish approved events and reconcile mappings.

Dependencies: EventKit, permissions.  Acceptance: No external write without approval; revoked permission leaves local data intact.

### FR-27  Google Calendar integration

Requirement / interaction: OAuth PKCE, choose calendars, publish approved events, sync edits/deletes.

Dependencies: OAuth, provider sync.  Acceptance: Retries do not duplicate events; token expiry and remote changes reconcile.

### FR-28  Calendar filters & holidays

Requirement / interaction: Filter source visibility, all-day events and region-specific holiday overlays.

Dependencies: Calendar aggregation.  Acceptance: Visibility filter never deletes data; holiday duplicates suppressed.

### FR-29  Task and time-block planning

Requirement / interaction: Create task-linked and independent time blocks with review for untimed tasks.

Dependencies: TaskSchedule, CalendarBlock.  Acceptance: Scheduled tasks link exactly once; unscheduled tasks never auto-populate calendar.

## 8. Analytics & Reports

### FR-30  Productivity dashboard

Requirement / interaction: Display tracked duration, productive/neutral/unproductive proportions and trends.

Dependencies: Activity logs, aggregation.  Acceptance: Totals match hand-checked datasets and selected date range.

### FR-31  Category charts

Requirement / interaction: Show activity time grouped by category with legend and accessible values.

Dependencies: Classifier, analytics.  Acceptance: Category totals reconcile to counted logged time.

### FR-32  Focus performance insights

Requirement / interaction: Show focus duration, session completion and peak focus periods.

Dependencies: Timer sessions, analytics.  Acceptance: Session metrics distinguish timer duration from logged work.

### FR-33  Historical reports

Requirement / interaction: Filter day/week/custom ranges and browse detailed entries.

Dependencies: Range queries.  Acceptance: Cross-midnight intervals are clipped; filters and totals agree.

### FR-34  Data export

Requirement / interaction: Export task/log/report/rule data as documented CSV/JSON with user control.

Dependencies: Data layer, privacy.  Acceptance: Export round-trip and escaping tests pass; secrets excluded.

## 9. Dynamic Island & Media

### FR-35  Dynamic Island / notch

Requirement / interaction: Support compact/expanded notch, hover, gestures and non-notch fallback.

Dependencies: Notch host, window geometry.  Acceptance: Closed hit region passes through clicks; external screens work.

### FR-36  Notch live activities

Requirement / interaction: Display and control active timers and other approved status activities.

Dependencies: Notch, timer state.  Acceptance: Notch and panels remain synchronized during handoff.

### FR-37  Music controls

Requirement / interaction: Show Now Playing and control supported Spotify/Apple Music actions.

Dependencies: Media permissions, controllers.  Acceptance: Unavailable/denied sources show truthful states; controls target correct player.

### FR-38  Music visualizer

Requirement / interaction: Display optional responsive music animation/artwork.

Dependencies: Playback metadata, motion.  Acceptance: Pausing stops activity; Reduce Motion and low-power settings respected.

### FR-39  Notch calendar

Requirement / interaction: Show upcoming and selected-day events in notch surface.

Dependencies: Calendar aggregation.  Acceptance: Event titles/times agree with dashboard; privacy visibility control works.

### FR-40  Multi-display notch

Requirement / interaction: Select physical or simulated notch placement per display.

Dependencies: Screen geometry, host.  Acceptance: Hot-plug, full-screen and display changes do not trap input.

## 10. System Utilities & Interface

### FR-41  Menu-bar command center

Requirement / interaction: Provide navigation and quick actions for all major features.

Dependencies: App shell, routing.  Acceptance: App remains usable with dashboard closed and Dock icon hidden.

### FR-42  Floating panel system

Requirement / interaction: Keyed resizable/draggable/pinnable panels with restore and snap.

Dependencies: AppKit window manager.  Acceptance: No duplicates; positions restore within visible display bounds.

### FR-43  Themes & customization

Requirement / interaction: Light/dark themes, materials, colors and animation preferences.

Dependencies: Settings, theme tokens.  Acceptance: Settings persist and apply consistently across surfaces.

### FR-44  File shelf & clipboard

Requirement / interaction: Provide opt-in shelf/clipboard capture, pin, preview and cleanup.

Dependencies: File permissions, local storage.  Acceptance: Only authorized content retained; files remain accessible or show errors.

### FR-45  System controls & webcam

Requirement / interaction: Expose supported battery/volume/brightness/mirror utilities with permission-aware fallbacks.

Dependencies: System APIs, device access.  Acceptance: Unsupported or denied actions are disabled with explanation.

### FR-46  Keyboard & quick actions

Requirement / interaction: Define shortcuts, deep links, widget intents and context actions.

Dependencies: Command routing.  Acceptance: Shortcuts do not collide; actions operate on current records.

### FR-47  Onboarding & tutorials

Requirement / interaction: Explain permissions, app surfaces, calendar approval and first-use flows.

Dependencies: Settings, permissions.  Acceptance: User can skip/revisit setup; denied permission paths remain usable.

## 11. Accounts, Sync & Platforms

### FR-48  Cloud account & synchronization

Requirement / interaction: Authenticated account lifecycle, offline queue, bidirectional sync and conflicts.

Dependencies: Backend, auth, RLS.  Acceptance: Two-account isolation and offline edit/delete tests pass.

### FR-49  Android companion

Requirement / interaction: Provide tasks, calendar, logging, timers, sync and notification actions.

Dependencies: Shared API, Room, scheduler.  Acceptance: Core companion flows work offline and sync after reconnect.

### FR-50  Cross-device task/timer sharing

Requirement / interaction: Sync task state and timer snapshots with deterministic ownership/conflict rules.

Dependencies: Cloud sync, timer schema.  Acceptance: No duplicate timers or stale task resurrection after simultaneous edits.

### FR-51  Privacy, backup & restore

Requirement / interaction: Secure tokens, scoped permissions, export/delete, versioned migrations and backups.

Dependencies: Security, persistence.  Acceptance: Backup restore succeeds; deletion and sign-out isolate accounts.

## 12. Cross-feature interaction requirements

- Creating a timed task creates an internal calendar block; rescheduling updates it; external publishing is separately approved.
- A task-linked Pomodoro shows task context, but actual time is logged only by explicit log action or confirmed logging prompt.
- Voice and typed activity logs use the same classifier, validation and persistence pathway.
- Dashboard, notch, menu bar, floating panels, widgets and Android operate on shared IDs and consistent state.
- Analytics distinguishes planned time, logged activity time and timer session time; they are not interchangeable.
- Calendar provider edits are reconciled with local mappings and conflict states rather than overwriting silently.
- All destructive operations provide confirmation or recoverability appropriate to the action.
## 13. Non-functional requirements

- Performance: App launches menu-bar/notch without opening dashboard; interactions remain responsive with large local histories; define measurable latency budgets during engineering spike.
- Offline: Core tasks, timer, calendar planning and logging remain functional without network; queued writes are durable.
- Security: Keychain and secure Android credential storage; least privilege; server-enforced user isolation; no service-role keys in clients.
- Privacy: Microphone, calendar, clipboard, automation and webcam access are opt-in and disclosed; no silent background capture.
- Accessibility: Keyboard and VoiceOver coverage; contrast; scalable content; Reduce Motion; non-color-only status indicators.
- Data integrity: Versioned migrations, transaction boundaries, stable IDs, backups, tombstones, retry idempotency and corruption recovery.
- Observability: Local privacy-safe diagnostics and truthful connection/permission status; no secrets or raw activity text in logs.
- Compatibility: macOS 14+ baseline; Android OS/API support range to be fixed during engineering validation; display and sleep/wake testing required.
## 14. Delivery stages and release gates

| Stage | Deliverable / exit gate |
| --- | --- |
| A. Architecture | Repository build audits; licensing decision; canonical models; data migration and test harness. |
| B. Productivity | Tasks, schedule linkage, calendars and planner; no silent external publication. |
| C. Focus and logging | Unified timers, prompts, voice, classification and timeline; sleep/wake tests. |
| D. macOS experience | Notch, media, panels, desktop widgets, utilities and accessibility. |
| E. Connected ecosystem | Auth, provider sync, Android focused companion, cross-device conflict tests. |
| F. Full release validation | All 51 acceptance tests, privacy/security review, packaged build and upgrade verification. |

No stage is a public release. The first public release requires the entire approved scope. Internal builds can be distributed to testers under controlled conditions.

## 15. Engineering decision register

- DEC-01 (confirmed): menu-bar/notch at launch; dashboard on demand.
- DEC-02 (confirmed): complete start/end times automatically create internal blocks; untimed tasks require explicit scheduling approval.
- DEC-03 (confirmed): external Apple/Google publishing requires explicit approval.
- DEC-04 (confirmed): focused Android companion, not full macOS feature parity.
- DEC-05 (confirmed): all 51 features before first public release.
- DEC-06 (recommended): new canonical core with selective module adaptation after repository build/QA audit.
- DEC-07 (open technical validation): reuse or independently implement GPL-licensed notch components.
- DEC-08 (open technical design): precise external event update approval semantics, provider conflict precedence and recurring-event scope.
- DEC-09 (open technical design): overdue logging prompt recovery policy and timer session cross-device authority.
- DEC-10 (open technical design): Android minimum supported API, performance budgets and release deployment targets.
## 16. Traceability and source notes

Functional scope is derived from the approved 51-item feature inventory and three uploaded project technical reviews: LOOPIN_COMPLETE_TECHNICAL_REVIEW.md, Logtrackin_Technical_Project_Analysis_and_Implementation_Guide.md, and COMPLETE_TECHNICAL_IMPLEMENTATION_GUIDE.md (Aura). Confirmed product decisions come from the subsequent user approvals. New domain models, release gates and architecture contracts are recommendations to be validated against the actual repositories.

Existing source-level caveats: Loopin cloud/Google integrations are simulated; Logtrackin sync, Android scheduling and some voice paths are incomplete; Aura includes excluded/shimmed utility modules and GPL-3.0 Boring Notch code. This PRD specifies target behavior and does not certify those features as already implemented.
