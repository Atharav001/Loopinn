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
| FR-02 | P02 | Quick task capture | IN REVIEW | PR #8 | Text, multi-line paste/drop and supported metadata tokens compile; UI smoke pending. |
| FR-03 | P02 | Task attachments | IN REVIEW | PR #3; PR #8 | Managed files and web links supported, 100 MB limit; revoked-access and UI checks pending. |
| FR-04 | P02 | Smart task recommendations | IN REVIEW | PR #8 | Deterministic due/importance/effort ranking, reason and dismissal; UI acceptance pending. |
| FR-05 | P02 | Task details & scheduling | IN REVIEW | PR #1; PR #8 | Due-only and linked-block invariants, first step, estimate and appearance compile; UI smoke pending. |
| FR-06 | P02 | Sticky floating to-do | IN REVIEW | PR #8 | Keyed always-on-top glass panel, list filter and quick add/complete compile; multi-display UI check pending. |
| FR-29 | P02 | Task and time-block planning | IN REVIEW | PR #8 | Linked and independent blocks persist; drag and editor paths compile; approval UX and edge checks pending. |
| FR-24 | P03 | Day/week/month/year calendar | IN REVIEW | PR #8 | Four views and cross-midnight day filtering compile; UI/timezone checks pending. |
| FR-25 | P03 | Interactive weekly planner | IN REVIEW | PR #8 | Weekly drag create/move/resize plus date editor compile; gesture/overlap UI checks pending. |
| FR-26 | P03 | Apple Calendar integration | IN REVIEW | PR #8 | EventKit permission read and per-block confirmed publish/remove to writable calendars compile; live permission/revocation tests pending. |
| FR-27 | P03 | Google Calendar integration | IN REVIEW | PR #8 | Desktop OAuth PKCE, Keychain, calendar listing, bounded API reads/publish/remove to writable calendars compile; client ID/live acceptance pending. |
| FR-28 | P03 | Calendar filters & holidays | IN REVIEW | PR #8 | Persisted source filters, all-day labels and subscribed regional holiday calendar deduplication; live region acceptance pending. |
| FR-08 | P04 | Pomodoro timer | IN REVIEW | PR #8 | Persisted deadline, pause/resume, focus/break recovery and cycle tests pass; runtime alert/UI acceptance pending. |
| FR-09 | P04 | Stopwatch & countdown | IN REVIEW | P04 timer branch | Persisted stopwatch with ordered laps and countdown deadline with single completion transition compile; clock-change and runtime alert acceptance pending. |
| FR-10 | P04 | Deep Work mode | IN REVIEW | P04 Deep Work branch | Configurable long-focus preset shares Pomodoro state, optional linked task is visible in dashboard and floating timer, and completion does not create an activity log; runtime UI acceptance pending. |
| FR-11 | P04 | Repeating focus alarms | IN REVIEW | P04 alarm branch | Saved interval deadline, enable/disable, snooze and missed-interval collapse compile; runtime alert and permission behavior pending. |
| FR-12 | P04 | Focus overlays & effects | IN REVIEW | PR #12 branch | Floating timer and Ripple edge glow compile; multi-display and Reduce Motion acceptance pending. |
| FR-13 | P04 | Timer alerts & sounds | IN REVIEW | PR #12 branch | Generated 1.5-second Om bell is shared by Ripple, timer completion and reminders; mute and permission acceptance pending. |
| FR-14 | P04 | Floating focus widgets | IN REVIEW | PR #8 | Shared timer state in always-on-top glass panel; runtime handoff and display acceptance pending. |
| FR-15 | P04 | Automatic activity prompts | IN REVIEW | PR #12 branch | Hour-boundary prompts for the previous hour persist their last prompted interval; runtime notification acceptance pending. |
| FR-16 | P04 | Floating quick-log panel | IN REVIEW | PR #12 branch | Glass always-on-top entry window accepts Enter, save and skip; runtime keyboard acceptance pending. |
| FR-17 | P04 | Voice activity logging | IN REVIEW | PR #12 branch | Microphone and speech consent gate live dictation; transcript fills an editable form and is never auto-saved; denial and runtime acceptance pending. |
| FR-18 | P04 | Planned vs actual timeline | IN REVIEW | PR #12 branch | Separate planned and logged rails show day intervals without inferring logs from plans; overlap UI acceptance pending. |
| FR-19 | P04 | Manual activity entries | IN REVIEW | PR #12 branch | Create, edit and delete persist; invalid and duplicate intervals are rejected; UI acceptance pending. |
| FR-20 | P04 | Natural-language time entry | IN REVIEW | PR #12 branch | Explicit AM/PM, noon and midnight ranges fill a reviewable manual form; ambiguous and overnight ranges fall back to manual entry; broader language acceptance pending. |
| FR-21 | P04 | Smart classification | IN REVIEW | PR #12 branch | Longest matching user rule categorizes logs; unknown remains Uncategorized; correction acceptance pending. |
| FR-22 | P04 | Custom classification dictionary | IN REVIEW | PR #12 branch | Rule add/remove persists with the logbook; edit/import acceptance pending. |
| FR-23 | P04 | Quiet hours & skip handling | IN REVIEW | PR #12 branch | Overnight quiet hours and skipped hourly prompts compile; timezone and runtime acceptance pending. |
| FR-07 | P05 | Desktop task widgets | IN REVIEW | PR #12 branch | WidgetKit extension, App Group snapshot, task completion and add-task deep links compile and package; signed installation and action acceptance pending. |
| FR-30 | P05 | Productivity dashboard | IN REVIEW | PR #12 branch | Tracked time and entry totals use saved activity logs; full dashboard acceptance pending. |
| FR-31 | P05 | Category charts | IN REVIEW | PR #12 branch | Category bars use clipped log durations; overlap policy and UI acceptance pending. |
| FR-32 | P05 | Focus performance insights | IN REVIEW | PR #12 branch | Completed focus records include active duration and feed period insights; boundary attribution and runtime acceptance pending. |
| FR-33 | P05 | Historical reports | IN REVIEW | PR #12 branch | Day/week/month/year activity period selection compiles; report details and UI acceptance pending. |
| FR-34 | P05 | Data export | IN REVIEW | PR #12 branch | CSV and JSON activity export compile; large-data and round-trip acceptance pending. |
| FR-37 | P05 | Music controls | IN REVIEW | PR #12 branch | Player-specific Music/Spotify controls show real unavailable or permission state; live player acceptance pending. |
| FR-38 | P05 | Music visualizer | IN REVIEW | PR #12 branch | Optional playback animation stops while paused and honors Reduce Motion/Low Power Mode; live media acceptance pending. |
| FR-44 | P05 | File shelf & clipboard | IN REVIEW | PR #12 branch | Opt-in bookmarked file shelf and manual bounded clipboard capture, pin and cleanup compile; runtime permission acceptance pending. |
| FR-45 | P05 | System controls & webcam | IN REVIEW | PR #12 branch | Battery status, system settings routes and consent-gated camera mirror compile; hardware/permission acceptance pending. |
| FR-48 | P06 | Cloud account & synchronization | UNVERIFIED | — | — |
| FR-49 | P06 | Android companion | UNVERIFIED | — | — |
| FR-50 | P06 | Cross-device task/timer sharing | UNVERIFIED | — | — |
| FR-35 | P08 | Dynamic Island / notch | UNVERIFIED | — | — |
| FR-36 | P08 | Notch live activities | UNVERIFIED | — | — |
| FR-39 | P08 | Notch calendar | UNVERIFIED | — | — |
| FR-40 | P08 | Multi-display notch | UNVERIFIED | — | — |
