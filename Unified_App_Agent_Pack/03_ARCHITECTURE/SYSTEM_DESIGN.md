# System Architecture and Framework Plan

## Architectural decision
New modular SwiftUI/AppKit macOS shell with reusable audited components; no wholesale copy of three AppDelegates, databases or timer loops. Keep notch behind an optional adapter boundary.

## Suggested repository tree
```text
UnifiedApp/
  Apps/macOS/                 # SwiftUI app, AppDelegate, menus, dashboard
  Apps/Android/               # Kotlin/Compose companion
  Packages/Domain/            # Task, Schedule, Activity, Timer, Rule contracts
  Packages/Persistence/       # SQLite migrations, repositories, backup
  Packages/Services/          # Task, Scheduler, Timer, Classifier, Logging, Analytics
  Packages/Integrations/      # EventKit, Google, Supabase, speech, media
  Packages/UIComponents/      # design system and shared macOS views
  Packages/Windowing/         # floating panels and window state
  Packages/WidgetBridge/      # App Group snapshots and intents
  Optional/NotchAdapter/      # not imported by core targets
  Tests/{Unit,Integration,UI,Contract,FaultInjection}/
  docs/                       # these specifications, ADRs, runbooks
  .github/workflows/          # macOS and Android CI
```

## Domain invariants
- `Task(id, title, listID, dueAt?, priority, completedAt?, metadata)` is not a calendar event.
- `TaskSchedule(id, taskID, startAt, endAt, timezone, state)` exists only with valid `endAt > startAt` and explicit interval; create/update linked `CalendarBlock` transactionally.
- `CalendarBlock(id, source, taskScheduleID?, externalLinks[], startAt, endAt)` stores local canonical state.
- `ActivityLog(id, startAt, endAt, rawText, category?, inputMethod, skipped, updatedAt)` represents actual activity only.
- `TimerSession(id, mode, phase, endDeadline?, remainingOnPause, linkedTaskID?, version)` uses persisted deadlines.
- `ExternalPublishRequest(id, calendarProvider, targetCalendar, blockIDs, previewHash, consentAt?, status)` is explicit authorization boundary; never infer consent from task creation.
- `OutboxRecord(id, entityType, entityID, operation, revision, retryAfter, attempts)` makes sync durable; deletes use tombstones.

## Persistence & transaction policy
SQLite WAL with migrations and `PRAGMA user_version`, FK constraints, uniqueness, transaction boundaries and backup before schema changes. Separate App Group versioned read snapshots for widgets. Store tokens in Keychain; attachments in controlled local directory, remote per-user object storage only when opted in. Avoid raw activity content in logs/telemetry.

## Services and interfaces
`TaskService.create/update`, `ScheduleService.assignInterval/removeInterval`, `CalendarRepository.upsertBlock`, `ExternalCalendarPublisher.preview/confirm/publish`, `TimerService.start/pause/resume/reconcile`, `PromptScheduler.nextDue/reconcile`, `ActivityService.log/skip`, `Classifier.classify/correct`, `AnalyticsService.aggregate`, `SyncEngine.push/pull`, `NotchSurfaceAdapter.start/stop`.
All public async operations return typed results with explicit `cancelled`, `permissionDenied`, `offline`, `timeout`, `conflict`, `invalidInput`, `unauthorized`, `rateLimited`, `serverError` outcomes.

## Sync contract
Authenticated per-user records; server-enforced ownership/RLS; stable UUIDs, per-record revisions, idempotency keys, incremental cursors, paginated pulls, retry/backoff+jitter, tombstones and explicit conflict UI. On account switch, isolate cached records and credentials. Android uses matching JSON schema contract, not shared Swift code.

## Calendar integration
EventKit read/write permission separately; Google OAuth Authorization Code + PKCE and token refresh; secure token storage. Local block changes are immediate; external writes queue only after preview confirmation. Provide per-operation progress, partial-success report, deduplication, retry and explicit recovery for 401/403/404/409/410/429/5xx.

## Timer/notification resilience
Persist absolute deadlines and schedule metadata. Reconcile on wake, timezone change, restart, app termination and permission changes. Define missed prompt policy (default: one catch-up prompt with explicit missed gap; never fabricate a log). On Android account for Doze, reboot and notification permission constraints.

## Dependency boundary
Core domain, persistence, services, dashboard, widgets, Android and integrations must compile/test with `NotchAdapter` absent. Notch consumes read-only observable state and sends validated commands through public service interfaces; it owns no canonical data.
