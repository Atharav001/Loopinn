# Original UI and Engineering Blueprint

> Converted from the supplied Word artifact. Original section order retained.

# Unified Productivity App

UI / UX DESIGN SYSTEM  |  FRAMEWORK ARCHITECTURE  |  IMPLEMENTATION & FAILURE-PREVENTION PLAYBOOK

Engineering blueprint v1.0  •  10 November 2026

Release scope: all 51 approved capabilities across macOS and a focused Android companion. Internal milestones are not public releases.

## Document control

| Decision | Approved policy |
| --- | --- |
| Launch | Menu-bar/notch agent at login or app launch; dashboard on demand |
| Scheduling | Only explicit start/end timed tasks create internal calendar blocks automatically |
| External calendar | Explicit approval before Apple/Google publication; approvals scoped to exact changes |
| Android | Tasks, calendar, activity logging, timers and synchronization |
| Release | All 51 features must pass release gates before public availability |
| Architecture | Fresh unified core; reuse existing code only after build, license and contract validation |

Evidence basis: Unified_App_Master_PRD_v1.docx; Aura technical implementation guide; Loopin technical review; Logtrackin technical project analysis. Existing reviews are source-level assessments, not proof of successful runtime builds. All technology and service choices below are proposed design decisions pending repository spikes.

## 1. Product surfaces and interaction design

### 1.1 Navigation and window hierarchy

| Surface | Primary purpose | Open / close / restore behavior |
| --- | --- | --- |
| Menu bar | Persistent command center, quick capture, timer status, prompt-now, sync health | Always accessible while app runs; closes on outside click; defer opening windows until popover dismisses |
| Notch | Compact live state, media, focus, upcoming calendar | Collapsed click-through except hit area; hover/click expansion; display-aware; keyboard alternative |
| Dashboard | Full workspace with sidebar and modular pages | Opened explicitly from menu bar/notch/shortcut; restore previous tab and window bounds |
| Floating panels | To-do, timers, log prompt, utility shelf | Keyed single-instance registry; drag/resize/pin; focus policy per panel |
| Desktop widgets | Task lists and focus status | WidgetKit reads App Group snapshot; AppIntents write through controlled commands |
| Android | Focused companion | Local-first screens with truthful sync state and notification actions |

### 1.2 Dashboard information architecture

Sidebar: Today / Tasks / Calendar / Time Tracking / Focus / Analytics / Dictionary & Rules / Integrations / Settings. Header: global search, Quick Add, date navigation, sync indicator, account, theme. Today: current focus session, next scheduled block, planned-vs-actual summary, task recommendations and upcoming events. Each screen must provide loading, empty, error, offline, permission-denied and success states.

### 1.3 Screen-by-screen UI contracts

| Screen | Layout | Actions | Guardrails |
| --- | --- | --- | --- |
| Tasks | List sidebar + Today/Later/Completed sections + details inspector | Quick add; drag reorder; create/edit/complete/undo; attachments; timed scheduling editor | Do not schedule date-only tasks; confirm destructive list deletion; keyboard-first task capture |
| Calendar | Day/week/month/year switcher, source filters, event inspector | Drag-to-create; move/resize; conflict preview; approval dialog for external publication | Internal blocks visibly distinct from imported events; DST and cross-midnight handling |
| Tracking | Dual planned/logged rails, prompt countdown, quick log | Log/edit/skip, voice transcript preview, classification correction | No inferred activity on skip; overdue gaps explicit; overlap warning |
| Focus | Pomodoro/Deep Work/stopwatch/countdown modes, linked task | Start/pause/resume/reset; presets; repeat alarms; panel/notch handoff | Absolute deadlines, interruption recovery, no double completion |
| Analytics | Date range, category and productivity charts, history | Drill down; filters; export; metric definitions | Clip duration to selected range; distinguish scheduled, logged and timer durations |
| Notch | Collapsed status, expanded tabs, music and live activities | Hover/click/keyboard expansion; media control; focus handoff | Multi-display safe hit testing; fallback if physical notch absent |
| Utilities | Shelf, clipboard, media, system controls, webcam | Explicit enable/permissions; drag-drop; Quick Look; copy/reopen | Disabled capability and permissions state must be truthful |
| Integrations | Accounts, provider status, calendar mapping, sync health | Connect/disconnect; publish approval; retry; inspect sync errors | Never show connected on placeholder IDs; no secrets in UI/logs |
| Settings | Appearance, prompts, quiet hours, privacy, backup, accessibility | Validate changes; restore defaults; export/delete | Immediate persisted feedback; clear consequence of destructive operations |

### 1.4 Design system tokens and responsive behavior

- Typography: semantic text styles (title, section, body, caption) using Dynamic Type-compatible scaling where applicable; minimum 11 pt for sustained desktop UI content; never encode meaning solely by color.
- Spacing: 4-point base grid; 8/12/16/24/32 spacing tokens. Standard controls at least 28-32 pt tall on macOS, larger touch targets on Android. Focus rings and keyboard navigation mandatory.
- Colors: semantic surfaces, accent, positive, warning, danger, planned, logged, productive, neutral and wasteful. Contrast checked in light/dark/high-contrast themes; Reduce Motion disables decorative looping animations.
- Windows: preserve safe frames per display, clamp offscreen windows after display disconnect, and do not force focus from a non-activating logging panel. Define and test minimum dashboard width before shipping.
- Reusable components: AppShell, SidebarItem, SectionHeader, EmptyState, ErrorState, PermissionState, SyncStatus, TimeBlock, TaskRow, TimerDial, ApprovalSheet, ConflictSheet, InlineToast and AccessibleIconButton.
### 1.5 Critical task-to-calendar interaction

State machine: unscheduled -> interval-entered -> internally scheduled -> modified / unscheduled / completed. A complete interval means valid start and end timestamps with end > start; due date alone and duration estimate alone are insufficient. Create exactly one internal CalendarBlock for each TaskSchedule ID, idempotently. When time changes, update that same block; when scheduling is removed, remove or archive the linked internal block according to retention policy. External publication is a separate requested -> approved -> queued -> acknowledged / failed / revoked state machine. Never publish without a new explicit user approval for the exact calendar, account and event change; preview event title, time and destination. A failed external operation must leave the internal block intact and show retry status.

## 2. Engineering framework and repository architecture

### 2.1 Proposed monorepo layout

apps/macos/AppShell, Features, UIComponents, Resources; apps/android/app; packages/Domain (Swift models), Application (use cases), Persistence (SQLite), Integrations (Calendar/Media/Sync), UIContracts, TestFixtures; backend/migrations, functions, policies; docs/adr, design, runbooks; scripts/verify, release, migrate; .github/workflows, CODEOWNERS, pull_request_template.md. Swift modules must not import SwiftUI from Domain; UI talks to application use cases, never directly to SQLite or HTTP.

### 2.2 Dependency boundaries

| Layer | Allowed dependencies | Forbidden coupling |
| --- | --- | --- |
| Domain | Foundation and pure value types | SwiftUI, AppKit, network clients, singleton windows |
| Application | Domain + protocols for persistence/time/auth | Direct UI controls or provider-specific API payloads |
| Adapters | SQLite, EventKit, Google, Supabase, file system | Business rules duplicated in adapters |
| macOS UI | View models + application commands | Direct SQL, OAuth token storage in views |
| Android UI | Kotlin use cases and Room repositories | Direct mutation of server records outside sync engine |
| Widgets | Versioned App Group snapshots + intents | Opening the main SQLite file from extension without coordinated access |

### 2.3 Canonical domain entities

| Entity | Core fields | Invariants |
| --- | --- | --- |
| Task | id, listId, title, dueAt?, priority, status, revision, deletedAt? | Due date != scheduled interval; stable ID |
| TaskSchedule | id, taskId, startAt, endAt, timezone, revision | endAt > startAt; explicit interval only |
| CalendarBlock | id, scheduleId?, source, startAt, endAt, externalLink? | Unique scheduleId for task-linked block |
| ActivityLog | id, startAt, endAt, rawText?, inputMethod, classification, state | No fabricated voice text; skipped/missed represented explicitly |
| TimerSession | id, mode, phase, deadline?, remaining?, taskId?, revision | Single owner for active timer; idempotent completion |
| ClassificationRule | id, phrase, category, productivity, precedence | Deterministic match; correction review |
| ExternalEventLink | provider, accountId, calendarId, eventId, localBlockId, syncCursor | Provider ID set only after server acknowledgement |
| SyncMutation | id, entityId, operation, baseRevision, attemptCount, nextRetryAt | Durable outbox; delete tombstones |
| Attachment | id, taskId, originalName, storedName, mime, size, checksum | Never rely on original filename as stored path |

### 2.4 Storage and migration policy

Use SQLite WAL with a single serialized writer, foreign keys, typed errors, transactions and ordered schema migrations (PRAGMA user_version or a migrations ledger). Keep attachment blobs in managed files; metadata in database. Use App Group versioned snapshots only for widget-facing projections, not as an independent master database. Persist credentials in Keychain (macOS) or Android secure storage. Every migration: preflight disk-space check, backup, transaction where possible, integrity check, downgrade policy, fixture upgrade test and recovery UI.

### 2.5 Background execution and timing

Persist wall-clock deadlines and last processed interval boundaries; reconcile on app launch, sleep/wake, timezone change and process restart. UI tickers update visuals only; they do not define truth. macOS notification delivery and Android Doze/foreground-service behavior are OS-constrained: define supported precision and catch-up behavior rather than promising exact execution while terminated. Use injectable Clock and Scheduler interfaces for deterministic tests.

### 2.6 Cloud synchronization protocol

Offline-first: local transaction -> append durable outbox mutation -> background push -> server acknowledgement -> advance cursor -> pull paginated deltas -> apply in local transaction. Use authenticated owner-scoped row-level security, stable UUIDs, revision/version tokens, idempotency keys, tombstones, bounded retries with jitter and server-driven rate limits. Server timestamps and revision checks avoid relying on device-clock last-write-wins. For conflicting edits show deterministic policy or a user-visible conflict review. Sign-out clears tokens and isolates account-specific caches. No plaintext activity text in telemetry.

### 2.7 Calendar integration contract

EventKit: request permission on demand, query bounded ranges, observe store changes, handle read-only calendars and revoked access. Google: system-browser OAuth authorization code with PKCE and state, secure token lifecycle, pagination, incremental sync tokens, 410 recovery, 401 refresh, 403 permission failures, 429 backoff and quota handling. Local planned blocks must never be interpreted as already externally published. External calendar import is not task creation unless the user explicitly converts an event.

### 2.8 Failure model and timeout budgets

| Operation | Initial policy (tunable) | Recovery |
| --- | --- | --- |
| Local DB write | Transaction; fail fast with typed error | Rollback; preserve input draft; retry after repair |
| Network API | Connect ~10 s, request ~30 s; cancellation supported | Exponential backoff + jitter; honor Retry-After; outbox remains pending |
| OAuth | Explicit user cancellation and expiry states | Discard partial tokens; restart auth; never fake connected |
| Speech | Permission/availability checks; cancellable session | Retain typed draft; show retry; never substitute demo transcript |
| Attachments | Stream and checksum; per-file size policy | Atomic temp write + rename; orphan cleanup |
| Widget action | Idempotent command + snapshot refresh | If app unavailable, persist intent or show failure; never silently lose action |
| Timers | Absolute deadline; idempotent completion key | Reconcile on wake/relaunch; prevent duplicate alarms |
| External publish | Explicit approval + queued mutation | Retain internal event and display failure/retry state |

Timeout values are initial engineering budgets, not guarantees. Measure and adjust from staging telemetry and provider limits. Always distinguish retryable failures (timeouts, 429, 5xx) from permanent failures (invalid data, revoked permission, 403).

## 3. Feature-by-feature implementation contracts

Each FR below specifies the implementation seam, anticipated failure and minimum acceptance test. All 51 remain release-blocking, even when staged later in development.

### Tasks & To-Do

#### FR-01  Multi-list task management

Implementation: TaskRepository + ListRepository; stable IDs, ordered positions, tombstones and undo commands.

Preemptive failure handling: Reorder collisions / stale widget copies. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Create, reorder, complete, undo and relaunch preserve order. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-02  Quick task capture

Implementation: Single CaptureUseCase handles typed, pasted, URL, file and drag/drop inputs; async metadata separate.

Preemptive failure handling: Slow URL fetch blocks capture / malformed paste. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Capture works offline and metadata failure never loses task. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-03  Task attachments

Implementation: Managed attachment directory, UUID stored path, metadata, checksum, security-scoped import.

Preemptive failure handling: Missing file / duplicate name / stale bookmark. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Attach, reopen, rename, remove, restart and restore. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-04  Smart task recommendations

Implementation: Pure deterministic recommendation ranking using due, priority, size and age; explain score.

Preemptive failure handling: Unexpected rank / no eligible task. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Golden fixture produces stable suggestions and explanation. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-05  Task details & scheduling

Implementation: Task editor + TaskScheduleUseCase; date-only vs interval validated separately.

Preemptive failure handling: Duplicate calendar block / invalid end time. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Timed task creates exactly one linked internal block; date-only creates none. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-06  Sticky floating to-do

Implementation: PanelRegistry keyed todo panel, shared task view model and persisted geometry.

Preemptive failure handling: Offscreen panel / duplicate panel. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Open-close-reopen, pin, multi-monitor and restore. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-07  Desktop task widgets

Implementation: App Group snapshot + AppIntents and atomic versioned writes.

Preemptive failure handling: Stale widget / entitlement mismatch. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Installed extension reads same tasks and updates without resurrection. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

### Timers & Focus

#### FR-08  Pomodoro timer

Implementation: TimerCoordinator state machine + persisted deadline and phase/cycle.

Preemptive failure handling: Sleep/restart / duplicate completion. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Pause/resume/break and restart reconcile exact state. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-09  Stopwatch & countdown

Implementation: Monotonic elapsed source plus persisted anchors and lap list.

Preemptive failure handling: Clock change / app restart. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Lap totals stable; countdown completion exactly once. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-10  Deep Work mode

Implementation: Preset/profile on shared TimerCoordinator with linked task.

Preemptive failure handling: Mode switch discards running work. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Confirm switch; preserve linked task and configured duration. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-11  Repeating focus alarms

Implementation: Absolute next-fire schedule and quiet-hour policy.

Preemptive failure handling: Missed ticks / app terminated. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Wake/restart catch-up policy and no duplicate alerts. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-12  Focus overlays & effects

Implementation: FocusPresentationController with Reduce Motion and focus state.

Preemptive failure handling: Overlay steals input / animation persists. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Dismissal, accessibility and repeated start-stop tested. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-13  Timer alerts & sounds

Implementation: NotificationActionRouter + sound selection and idempotent action handling.

Preemptive failure handling: Permission denied / duplicate notification actions. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Snooze/dismiss work; muted fallback truthful. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-14  Floating focus widgets

Implementation: PanelRegistry + timer projections + notch handoff.

Preemptive failure handling: Two independent timer states. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Panel and notch display same remaining time. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

### Time Tracking & Logging

#### FR-15  Automatic activity prompts

Implementation: LoggingScheduler persists last interval and computes due boundaries.

Preemptive failure handling: Sleep/wake gaps / timer drift. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Interval fixture and restart tests produce correct prompts. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-16  Floating quick-log panel

Implementation: Nonactivating NSPanel with draft preservation and action router.

Preemptive failure handling: Focus theft / accidental dismissal. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Keyboard submit, skip, cancel and restore draft. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-17  Voice activity logging

Implementation: Speech adapter with permission states, transcript preview and explicit commit.

Preemptive failure handling: Denied mic / fake fallback / unavailable recognizer. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Failed recognition never writes synthetic log. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-18  Planned vs actual timeline

Implementation: Two projections over Schedule and ActivityLog; overlap rendering.

Preemptive failure handling: Cross-midnight / overlapping blocks. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Render two rails and split correctly at day boundary. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-19  Manual activity entries

Implementation: EntryUseCase validates intervals and revisioned edit/delete.

Preemptive failure handling: Overlaps / failed writes. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: CRUD, undo, invalid interval and offline restart. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-20  Natural-language time entry

Implementation: Parser returns structured candidate + confidence + editable preview.

Preemptive failure handling: Ambiguous noon/midnight/DST. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Invalid phrases request clarification; never silently choose unsafe time. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-21  Smart classification

Implementation: Pure rule engine with explicit precedence and default Uncategorized.

Preemptive failure handling: Phrase collision / inconsistent platforms. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Swift and Kotlin fixture parity on same examples. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-22  Custom classification dictionary

Implementation: Rule CRUD + conflict checker + import/export.

Preemptive failure handling: Full-sentence overlearning / duplicate phrase. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Correction review, edit, delete and deterministic matches. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-23  Quiet hours & skip handling

Implementation: Time-zone-aware schedule policy; explicit skipped/missed state.

Preemptive failure handling: Overnight boundary / silent invented activity. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: No prompts in quiet hours; skip never records guessed text. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

### Calendar & Planning

#### FR-24  Day/week/month/year calendar

Implementation: CalendarQueryService + reusable event layout and virtualized grids.

Preemptive failure handling: Large event count / timezone offset. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: All four modes, date navigation, permissions and empty states. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-25  Interactive weekly planner

Implementation: Hit-test state machine: create, select, move, top/bottom resize, cancel.

Preemptive failure handling: Drag mis-target / overlap / DST. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Pointer and keyboard tests for move/resize/cross-day. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-26  Apple Calendar integration

Implementation: EventKit adapter with permission and change observation.

Preemptive failure handling: Revocation / read-only calendar. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Import read-only events and approved export without duplicates. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-27  Google Calendar integration

Implementation: OAuth PKCE + event mapping + delta sync and retry queue.

Preemptive failure handling: Expired tokens / 410 / 429 / delete conflicts. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Two-way edit/delete convergence in staging account. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-28  Calendar filters & holidays

Implementation: Source visibility preferences and holiday provider with dedup.

Preemptive failure handling: Duplicate holidays / stale filters. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Filter persists; duplicates removed; timezone correct. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-29  Task and time-block planning

Implementation: TaskSchedule service links task and block; external approval state machine.

Preemptive failure handling: Date-only task auto-publishes / duplicate updates. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Internal auto-create only for valid interval; external requires approval. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

### Analytics & Reports

#### FR-30  Productivity dashboard

Implementation: Materialized/report queries with defined denominator and date clipping.

Preemptive failure handling: Double-counted overlaps / missing logs. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Totals match hand-calculated fixtures. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-31  Category charts

Implementation: Aggregations by category, unknown bucket and timeframe.

Preemptive failure handling: Missing category / empty data. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Category totals reconcile to tracked totals. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-32  Focus performance insights

Implementation: Separate timer focus metrics from activity logs; weighted peak hours.

Preemptive failure handling: Row-count mistaken for duration. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Peak-hour and focus fixtures validated. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-33  Historical reports

Implementation: Paginated date-range query with time-zone boundaries.

Preemptive failure handling: Long histories / midnight spans. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Month/week/day exports match range query. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-34  Data export

Implementation: Streaming CSV/JSON serializer with schema version and privacy filters.

Preemptive failure handling: Large export / incomplete rows. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Re-import sample and verify record counts/checksums. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

### Dynamic Island & Media

#### FR-35  Dynamic Island / notch

Implementation: License-cleared notch host with pass-through hit zones and coordinator.

Preemptive failure handling: GPL reuse risk / blocked clicks. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Notch/no-notch display and hit-test matrix. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-36  Notch live activities

Implementation: Read-only projections from timer/logging/calendar state.

Preemptive failure handling: Stale duplicated state. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Live activity follows shared coordinator after panel handoff. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-37  Music controls

Implementation: Provider adapters for Spotify/Apple Music/Now Playing with permission states.

Preemptive failure handling: Apple Events denied / app absent. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Play/pause/skip states reflect actual provider responses. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-38  Music visualizer

Implementation: Playback-driven rendering with reduced-motion fallback.

Preemptive failure handling: High CPU / stale waveform. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Paused state stops animation; performance budget passes. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-39  Notch calendar

Implementation: Compact bounded EventKit/internal upcoming event projection.

Preemptive failure handling: Permission revoked / long titles. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Upcoming item truncates accessibly and filters apply. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-40  Multi-display notch

Implementation: Per-screen geometry, screen UUID mapping and fallback simulated notch.

Preemptive failure handling: Monitor unplug / full-screen / incorrect hit zone. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Multi-monitor hotplug and screen switching tests. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

### System Utilities & Interface

#### FR-41  Menu-bar command center

Implementation: NSStatusItem lifecycle + action dispatcher and status projection.

Preemptive failure handling: Popover closes before panel action / agent quits. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Actions open exactly one correct window. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-42  Floating panel system

Implementation: Keyed PanelRegistry, frame clamp, pin and Space behavior.

Preemptive failure handling: Duplicate panels / offscreen restore. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Resize/pin/multi-space and monitor change tested. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-43  Themes & customization

Implementation: Semantic token system with persisted settings and migrations.

Preemptive failure handling: Mixed settings stores / low contrast. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Theme switches live, persists and meets contrast checks. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-44  File shelf & clipboard

Implementation: Explicitly enabled file/clipboard adapters; security bookmarks and retention.

Preemptive failure handling: Unbounded clipboard collection / stale file paths. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Permission, retention, reopen, cleanup and opt-out verified. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-45  System controls & webcam

Implementation: Capability-gated volume/brightness/battery/camera adapters.

Preemptive failure handling: Unavailable API / unauthorized camera. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Unavailable control disabled; no fake success; permissions tested. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-46  Keyboard & quick actions

Implementation: Central command registry, deep links and keyboard bindings.

Preemptive failure handling: Shortcut conflicts / invalid URL route. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Every shortcut has accessible menu equivalent. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-47  Onboarding & tutorials

Implementation: Progressive permissions with feature-specific explanation and recovery.

Preemptive failure handling: Permission denied / setup skipped. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Clean install can complete or defer setup safely. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

### Accounts, Sync & Platforms

#### FR-48  Cloud account & synchronization

Implementation: Auth/session manager, RLS, durable outbox, paginated delta pull.

Preemptive failure handling: Cross-user leak / partial sync / offline edits. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Two-account isolation and offline conflict suite passes. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-49  Android companion

Implementation: Kotlin Compose/Room feature slice with same API contract.

Preemptive failure handling: Doze / service policy / migration mismatch. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Tasks/calendar/logging/timers work offline and sync. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-50  Cross-device task/timer sharing

Implementation: Revisioned task sync and timer snapshot protocol with single owner.

Preemptive failure handling: Two active timers / clock skew. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Concurrent device fixture resolves deterministically. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

#### FR-51  Privacy, backup & restore

Implementation: Keychain, retention, encryption policy, backup manifest and verified restore.

Preemptive failure handling: Corrupt backup / secret exposure / incomplete delete. Detect through typed errors, explicit UI state and structured tests; preserve user data and provide retry/recovery where applicable.

Acceptance gate: Backup->wipe->restore integrity; delete/export verified. Unit tests plus integration/UI tests must pass on supported targets; no mock success state in production.

## 4. Build-by-build delivery and GitHub protocol

### 4.1 Branch and merge policy

Protected main is always releasable at its current internal milestone. Create one branch per small vertical slice: feat/FR-XX-short-name, fix/issue-id, chore/tooling. Every branch includes code, tests, migration (if needed), documentation and a proof artifact. Commit locally after each coherent change; push after verification; open a PR; merge only after CI and review. Never force-push main. Tag internal integration checkpoints and maintain a changelog. GitHub updates require an authenticated repository connection and are not performed by this document.

### 4.2 Definition of Done for every implementation step

- Requirements ID and UI states linked to issue; design review completed.
- Domain/API/schema contract specified before view wiring.
- Failure modes, permission paths, timeout and retry policy documented.
- Focused unit tests added first; deterministic fixtures and fake clock/network used.
- Debug build and release build compile with warnings-as-errors for owned code where practical.
- Relevant unit, integration, UI and migration tests pass on clean runner.
- No simulated production success, no secrets in source/logs, no silent data loss.
- Manual smoke test on installed signed app where OS integration is involved.
- PR has screenshots/video, test output, rollback notes and reviewer approval.
- Merge to protected main only after required CI; tag milestone and update docs.
### 4.3 Recommended CI workflow

| Job | Trigger | Required checks |
| --- | --- | --- |
| Static validation | Every PR | Formatting, SwiftLint/ktlint, dependency audit, secret scan, docs links |
| macOS build | Every PR on macOS runner | swift package resolve, xcodebuild/SwiftPM debug + release, signed-bundle smoke where configured |
| macOS tests | Every PR | XCTest unit + integration, schema migration fixtures, view-model tests |
| Android build | Every Android/backend PR | Gradle wrapper verification, assembleDebug, lint, unit tests |
| Backend validation | Every migration/API PR | SQL migration apply from empty + previous schema; RLS tests with two users |
| End-to-end staging | Before milestone merge/release | Calendar provider sandbox, offline sync, multi-device and permissions |
| Release candidate | Before public release | Notarization/signing, packaged widget install, Android AAB, SBOM and backup restore |

Sample shell gates: swift test; swift build -c release; xcodebuild -project <verified-project> -scheme <verified-scheme> test; ./gradlew test lint assembleDebug; backend migration smoke suite. Exact commands must be determined from the actual checked-in project, not guessed. Lock toolchain versions, Gradle wrapper, Swift package resolution and reproducible runner images.

### 4.4 Failure and rollback runbook

If a step fails: (1) capture command, environment, exit code and logs; (2) classify compile, test, permission, provider, schema, runtime or flaky infrastructure failure; (3) reproduce on clean runner; (4) fix root cause with a regression test; (5) rerun full affected dependency graph; (6) do not merge red CI; (7) revert feature flag or commit if regression persists. Never bypass a failing gate by deleting tests or converting errors into silent success. For schema changes, use forward-fix migrations plus backup restore drills; destructive rollback is not assumed safe.

### 4.5 CI anti-false-positive rules

- Test doubles only under test/previews; staging secrets separate from production; test asserts provider request/response rather than sleeping arbitrary durations.
- Fail CI when tests are skipped unexpectedly, generated widget extension is absent, or packaged bundle lacks required entitlements.
- Verify the installed .app/.appex, not only swift build executable; verify Android foreground service on physical devices.
- Use contract tests against real staging provider APIs for OAuth, calendar and sync; retain deterministic offline mock tests for edge cases.
- Run migration tests from every supported old schema with seeded real-shape fixtures and validate record counts after upgrade.
- Pin dependencies and check licenses; scan for hard-coded credentials, demo statuses and mock sync identifiers.
## 5. Detailed execution sequence and dependencies

| Stage | Implementation focus | Exit criteria |
| --- | --- | --- |
| Gate 0: repository audit and feasibility | Inventory all three repositories, compile each independently, record exact active targets, licenses, tests and entitlements; spike notch reuse and signed widgets. | Clean builds or documented blockers; signed widget/notch proof; license decision ADR. |
| Gate 1: unified core | Create monorepo, Domain/Application/Adapters packages, CI, logging/error taxonomy, SQLite migrations, App Group contract and shared UI tokens. | Empty app launches menu bar/notch, opens dashboard on demand; persistence upgrade fixture passes. |
| Gate 2: tasks + calendar invariants | Implement task lists/capture/attachments/schedules and internal calendar block projection; external publish approval UI before external adapters. | FR-01..07, FR-24/25/29 core acceptance; date-only task never creates block. |
| Gate 3: timer and logging engine | Implement timer coordinator, notifications, prompt scheduler, activity records, classifier and voice; run sleep/wake/clock test matrix. | FR-08..23 tested with fake clock and real permissions; no duplicate timer completion. |
| Gate 4: calendar providers and analytics | Add EventKit/Google OAuth, reconciliation and report queries; establish deterministic export and analytics fixtures. | FR-26..34 verified; external publish only after explicit approval and acknowledgement. |
| Gate 5: Aura surfaces and utilities | Integrate notch, music, widgets, panel registry, themes, clipboard/shelf and system controls after license/permission gates. | FR-35..47; packaged extension and multi-monitor test matrix passes. |
| Gate 6: backend + Android | Deploy versioned RLS backend, outbox/delta sync, Android Room companion and cross-device timer contract. | FR-48..51; two-account and two-device offline conflict tests pass. |
| Gate 7: full release hardening | End-to-end feature matrix, privacy/accessibility, upgrade/restore, performance, notarization, Android policy, RC soak. | All 51 FR rows green with evidence; no P0/P1 defects; signed distributables verified. |

### 5.1 Critical path and parallelism

Core model and database contracts precede all UI feature merges. TaskSchedule/CalendarBlock rules precede external calendar adapters. Timer/Logging clocks precede analytics. App Group snapshot schema precedes widgets. Auth/RLS and sync protocol precede Android cloud behavior. UI design, media controls and isolated visual components may proceed in parallel behind stable interfaces. Avoid parallel schema modifications without an agreed owner and migration sequencing.

### 5.2 Release quality gates

- Feature coverage: all 51 IDs have linked PRs, screenshots, tests and acceptance evidence.
- Data safety: migration from every supported version, interrupted upgrade recovery and backup/restore pass.
- Security: two-user RLS isolation, OAuth PKCE, secure token storage and dependency/license review pass.
- Reliability: timer sleep/wake/relaunch, calendar conflicts, offline queues, provider timeouts and retries pass.
- Platform: packaged macOS app/notch/widget and Android companion tested on supported OS versions and representative devices.
- UX: keyboard navigation, VoiceOver, contrast, Reduce Motion, empty/error states and permission recovery pass.
- Operations: signed/notarized macOS installer, Android release artifact, rollback runbook, privacy documentation and diagnostics ready.
## 6. Test matrix and fault injection

| Fault injection | Expected behavior | Automated evidence |
| --- | --- | --- |
| App killed during timer | Reconcile deadline once; no duplicate completion | Fake clock + restart integration test |
| Sleep during logging interval | Apply documented missed-period policy; no fabricated text | Clock advance and resume fixture |
| SQLite write fails / disk full | Rollback and preserve unsaved draft | Fault-injected repository test |
| Google 401 / 403 / 429 / 410 | Refresh / show permission / backoff / full resync respectively | HTTP contract fixtures + staging smoke |
| Network drops after server accepts write | Idempotent retry, no duplicate event | Ack-loss outbox test |
| Two devices edit same task | Deterministic revision conflict policy | Multi-client integration test |
| Task loses scheduled interval | Linked internal block updated/removed; external removal needs approval | TaskSchedule state machine test |
| Widget extension stale cache | No deleted task resurrection; refresh after write | App Group timestamp/revision fixture |
| Display unplugged | Panel moves onscreen; notch reselects display | Manual multi-display UI suite |
| Speech permission revoked | Stop capture and retain draft; no fake transcript | Permission state machine test |
| Android Doze/reboot | Best-effort scheduled notifications with explicit missed prompt recovery | Physical device matrix |
| Backup corrupt / partial | Restore rejected atomically; existing data intact | Checksum and restore rollback test |

## 7. Engineering decisions requiring ADRs

- ADR-001: notch code licensing and independent implementation fallback.
- ADR-002: SQLite library, migrations, single-writer concurrency and backup format.
- ADR-003: internal calendar ownership and approval semantics for external create/update/delete.
- ADR-004: task-to-schedule cardinality (recommend multiple sessions per task, one block per session).
- ADR-005: sync revision/conflict semantics and timer ownership across devices.
- ADR-006: logging missed-interval and skip semantics.
- ADR-007: external provider permission scopes, OAuth redirect and token storage.
- ADR-008: Android notification precision and OS policy.
- ADR-009: clipboard retention/consent and system-control capability matrix.
- ADR-010: target macOS versions, distribution channels and minimum supported hardware.
## 8. Implementation issue and PR template

Issue: [FR-ID] user outcome; screen states; domain contract; API/schema changes; edge cases; permission model; failure table; tests; feature flag; rollout/rollback. PR: linked issue/ADR; changed files; local commands + exit codes; CI run link; screenshots; migration/entitlement checks; security review; smoke steps; release note. A feature is not marked complete until the GitHub PR is merged and its acceptance evidence is recorded.

## 9. Source-to-new-system migration strategy

Do not copy source folders blindly. For each candidate module: verify it is included in the active target, inspect dependencies and license, compile a standalone adapter, write characterization tests against current behavior, then replace persistence/state coupling with new protocols. Aura priority: notch/media/window/widget; Loopin priority: task capture/recommendation/timers; Logtrackin priority: calendar/rails/classification/Android. Mock sync implementations, hard-coded voice strings, static connected badges, destructive startup migrations and partial OAuth must not be imported into production paths.

## 10. Final engineering assurance statement

The process is designed to prevent false-positive builds and reduce regressions, but no document can eliminate all failures, external outages, OS constraints or unexpected defects. Reliability comes from strict evidence-based gates, clean builds, realistic integration tests, fault injection, protected GitHub merges, staged validation and rollback readiness. Production success must always be based on actual acknowledgement and observable behavior.
