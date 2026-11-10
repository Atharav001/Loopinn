# Feature completion matrix
> Initial state is **UNVERIFIED**, not zero actual work. Update from GitHub evidence after repository audit.

| ID | Phase | Feature | Status | PR / merged SHA | Evidence |
|---|---|---|---|---|---|
| FR-41 | P01 | Menu-bar command center | IN REVIEW | PR #5 merged; P01 shell branch | Quick capture, next-task completion, routes and Settings access compile; runtime UI smoke and future feature actions pending. |
| FR-42 | P01 | Floating panel system | IN REVIEW | PR #7 | Keyed floating tasks panel, pinned setting, saved frame and visible-screen recovery compile; more panel types and runtime smoke pending. |
| FR-43 | P01 | Themes & customization | IN REVIEW | PR #6 merged; PR #7 | Theme, accent, compact layout, Dock icon and Today plan visibility persist and apply; accessibility and runtime appearance checks pending. |
| FR-46 | P01 | Keyboard & quick actions | IN REVIEW | PR #7 | Command palette routes and task actions, ⌘K, ⌘N, ⌘1–3, ⌘, and undo compile; global shortcuts and deeper action coverage pending. |
| FR-47 | P01 | Onboarding & tutorials | IN REVIEW | P01 shell branch | Skippable first-run welcome and reopen action compile; runtime first-run smoke pending. |
| FR-51 | P01 | Privacy, backup & restore | IN REVIEW | PR #7 | Local backup/export with attachments, validated restore and confirmed erase; 4 backup tests pass. Runtime import/export and migration review pending. |
| FR-01 | P02 | Multi-list task management | IN REVIEW | PR #1, `93a4e63` | CRUD, ordering and one-step undo tested; relaunch UI evidence pending. |
| FR-02 | P02 | Quick task capture | IN REVIEW | P02/P03 branch | Text, multi-line paste and text drop compile; metadata parsing and UI smoke pending. |
| FR-03 | P02 | Task attachments | IN REVIEW | PR #3; P02/P03 branch | Managed files and web links supported, 100 MB limit; revoked-access and UI checks pending. |
| FR-04 | P02 | Smart task recommendations | IN REVIEW | P02/P03 branch | Deterministic due/importance/effort ranking, reason and dismissal; UI acceptance pending. |
| FR-05 | P02 | Task details & scheduling | IN REVIEW | PR #1; P02/P03 branch | Due-only and linked-block invariants, first step, estimate and appearance compile; UI smoke pending. |
| FR-06 | P02 | Sticky floating to-do | IN REVIEW | P02/P03 branch | Keyed always-on-top glass panel, list filter and quick add/complete compile; multi-display UI check pending. |
| FR-29 | P02 | Task and time-block planning | IN REVIEW | P02/P03 branch | Linked and independent blocks persist; drag and editor paths compile; approval UX and edge checks pending. |
| FR-24 | P03 | Day/week/month/year calendar | IN REVIEW | P02/P03 branch | Four views and cross-midnight day filtering compile; UI/timezone checks pending. |
| FR-25 | P03 | Interactive weekly planner | IN REVIEW | P02/P03 branch | Weekly drag create/move/resize plus date editor compile; gesture/overlap UI checks pending. |
| FR-26 | P03 | Apple Calendar integration | IN REVIEW | P02/P03 branch | EventKit permission read and per-block confirmed publish compile; live permission/revocation tests pending. |
| FR-27 | P03 | Google Calendar integration | IN REVIEW | P02/P03 branch | Desktop OAuth PKCE, Keychain, calendar listing, bounded API reads/publish compile; client ID/live acceptance pending. |
| FR-28 | P03 | Calendar filters & holidays | IN REVIEW | P02/P03 branch | Persisted source filters, all-day labels and Apple holiday calendar badges; region/dedup acceptance pending. |
| FR-08 | P04 | Pomodoro timer | IN REVIEW | P02/P03 branch | Persisted deadline, pause/resume, focus/break recovery and cycle tests pass; runtime alert/UI acceptance pending. |
| FR-09 | P04 | Stopwatch & countdown | UNVERIFIED | — | — |
| FR-10 | P04 | Deep Work mode | UNVERIFIED | — | — |
| FR-11 | P04 | Repeating focus alarms | UNVERIFIED | — | — |
| FR-12 | P04 | Focus overlays & effects | UNVERIFIED | — | — |
| FR-13 | P04 | Timer alerts & sounds | UNVERIFIED | — | — |
| FR-14 | P04 | Floating focus widgets | IN REVIEW | P02/P03 branch | Shared timer state in always-on-top glass panel; runtime handoff and display acceptance pending. |
| FR-15 | P04 | Automatic activity prompts | UNVERIFIED | — | — |
| FR-16 | P04 | Floating quick-log panel | UNVERIFIED | — | — |
| FR-17 | P04 | Voice activity logging | UNVERIFIED | — | — |
| FR-18 | P04 | Planned vs actual timeline | UNVERIFIED | — | — |
| FR-19 | P04 | Manual activity entries | UNVERIFIED | — | — |
| FR-20 | P04 | Natural-language time entry | UNVERIFIED | — | — |
| FR-21 | P04 | Smart classification | UNVERIFIED | — | — |
| FR-22 | P04 | Custom classification dictionary | UNVERIFIED | — | — |
| FR-23 | P04 | Quiet hours & skip handling | UNVERIFIED | — | — |
| FR-07 | P05 | Desktop task widgets | UNVERIFIED | — | — |
| FR-30 | P05 | Productivity dashboard | UNVERIFIED | — | — |
| FR-31 | P05 | Category charts | UNVERIFIED | — | — |
| FR-32 | P05 | Focus performance insights | UNVERIFIED | — | — |
| FR-33 | P05 | Historical reports | UNVERIFIED | — | — |
| FR-34 | P05 | Data export | UNVERIFIED | — | — |
| FR-37 | P05 | Music controls | UNVERIFIED | — | — |
| FR-38 | P05 | Music visualizer | UNVERIFIED | — | — |
| FR-44 | P05 | File shelf & clipboard | UNVERIFIED | — | — |
| FR-45 | P05 | System controls & webcam | UNVERIFIED | — | — |
| FR-48 | P06 | Cloud account & synchronization | UNVERIFIED | — | — |
| FR-49 | P06 | Android companion | UNVERIFIED | — | — |
| FR-50 | P06 | Cross-device task/timer sharing | UNVERIFIED | — | — |
| FR-35 | P08 | Dynamic Island / notch | UNVERIFIED | — | — |
| FR-36 | P08 | Notch live activities | UNVERIFIED | — | — |
| FR-39 | P08 | Notch calendar | UNVERIFIED | — | — |
| FR-40 | P08 | Multi-display notch | UNVERIFIED | — | — |
