# Implementation changelog

> Append entries only after actual implementation or verified baseline audit.

## 11 November 2026 — floating-window pin controls and Ripple double bell
- Added a visible pin control in the title area of the Tasks, Pomodoro, Ripple Focus and Log Activity windows. Pinning changes each panel's window level, defaults on, and persists independently; the Tasks pin stays in sync with its existing setting.
- Removed fixed content minimums so panels expand with resizing, with practical window minimums to keep their controls accessible.
- Gave Ripple Focus a distinct, louder sharp two-strike bell while retaining the existing sound toggle and the Om sound for other focus alerts.

## 11 November 2026 — menu action responsiveness
- Deferred command execution until the menu-bar popover releases focus, then explicitly brought floating panels and the application window forward. Reopening an existing floating panel now raises it as well.
- Quick task capture now focuses its field for an empty submission and shows storage errors in the menu instead of failing silently.

## 11 November 2026 — focused menu bar actions
- Kept only the actions that open floating windows in the menu bar: Pomodoro, Ripple Focus, To-Do Lists and Log Activity. Open Application is the single route to Today, tasks, calendar, Focus, logbook, timesheet, analytics, utilities and settings.
- Removed the menu scroll area after shortening the action list, so all remaining controls fit in the command center.

## 11 November 2026 — command center visibility and empty workspace repair
- Fixed the menu bar command list collapsing to zero height. The list has a visible scroll area, and Open Application and Settings stay directly accessible below it.
- Added menu links for all implemented sections and timer modes, a Start Here launchpad in Today, and clear actions in empty Today and Analytics views.
- Made the floating Log Activity panel usable without an hourly prompt by allowing an editable time range.

## 11 November 2026 — Aura and Loopin-macOS source adaptation (in review)
- Adapted Aura's menu bar command center layout and quick task entry to Loopinn's single app state. It exposes the floating Pomodoro, Focus, Ripple Focus, tasks, calendar, logbook, timesheet, quick log, settings and application windows.
- Adapted Loopin-macOS's interactive mini month year calendar and planned/logged timesheet rails to Loopinn's existing calendar blocks and activity records. Added direct month-day creation, a logbook month picker, and Loopin-style quick suggestions to the hourly logging panel.
- Kept the existing local store so imported views do not create a second set of tasks or activity logs. No notch code was imported. The unsigned Xcode app build and 50/50 core checks pass; the rebuilt app was relaunched on this Mac. Interactive menu and window acceptance remains pending.

## 11 November 2026 — local app launch check
- Rebuilt the unsigned Xcode app with its embedded task widget, launched `dist/Loopinn.app` on macOS, and observed the Loopinn process running. PR #12 macOS CI passed for `236123a`; interactive window and signed widget acceptance remain pending.

## 11 November 2026 — activity backup and hourly notification (in review)
- Added persisted focus effect controls for dimming, ripple and edge glow intensity. Floating focus respects Reduce Motion; completion remains visible without animation.
- Added a persisted Om-bell sound toggle in Focus. Timer and Ripple edge alerts remain visible when sound is off.
- Extended backup snapshots to include activity logs, file shelf data and focus history while retaining legacy backup readability. Restore writes these stores with rollback to the pre-restore state on failure, and creates a safety backup first.
- Added a local macOS hourly activity notification alongside the always-on-top quick-log window; permission denial still leaves the window available. The unsigned app with widget builds and 50/50 core checks pass; live notification and restore UI acceptance remain pending.

## 11 November 2026 — P05 widgets, media and utilities (in review)
- Added an Xcode project and packaged WidgetKit task extension using an App Group snapshot and task/add deep links. The app still opens as a menu bar accessory by default.
- Added explicit file shelf and clipboard capture, Music/Spotify controls with truthful unavailable states, playback animation honoring Reduce Motion and Low Power Mode, battery/system settings controls, and a consent-gated camera mirror.
- Added completed focus-session records and duration-based insights, plus configurable short/long Pomodoro breaks and optional manual phase advance. Unsigned Xcode app and embedded extension build; 49/49 core checks pass. Signed widget installation and runtime permissions remain unverified.

## 11 November 2026 — permission-gated voice draft (in review)
- Added microphone and speech recognition permission requests, live transcription, and explicit stop. Recognized words fill the editable activity form and never save without user action. The packaged app declares both required usage descriptions.
- Local Swift checks pass; live permission and transcription acceptance pending.

## 11 November 2026 — reviewable time entry (in review)
- Added parsing of explicit AM/PM, noon and midnight activity ranges into the manual log form for review. Ambiguous and overnight text is refused with a manual fallback.
- Local Swift checks pass; packaged and runtime acceptance pending.

## 11 November 2026 — shared alerts and activity rules (in review)
- Shared the generated Om bell and edge glow with focus timer transitions and reminders. Added overnight quiet hours to hourly logging and a user-editable phrase dictionary that leaves unknown activity Uncategorized.
- Local Swift checks pass; runtime sound, overlay and timezone acceptance remain pending.

## 11 November 2026 — hourly logbook and activity insights (in review)
- Added a durable local logbook with hourly prompts, an always-on-top glass quick-log panel, Enter/skip actions, manual create/edit/delete, duplicate interval validation, and a separate day logbook view.
- Added a planned-versus-logged timeline, clipped tracked-time summary, category chart, and CSV/JSON activity export. No planned block is silently counted as actual activity.
- Local Swift build, unsigned app package and 41/41 core checks pass. Runtime prompts, notification permission, UI and large export acceptance remain pending.

## 11 November 2026 — repeating focus reminders (in review)
- Added a persisted focus reminder interval with enable/disable and ten-minute snooze. After sleep or relaunch, missed intervals collapse into one alert and schedule the next interval from delivery; the app never floods alerts.
- Added Focus screen controls and a dismissible check-in banner. Local Swift build, unsigned app package and 37/37 core checks pass; runtime alert behavior remains pending.

## 11 November 2026 — Deep Work mode (in review)
- Added a configurable long-focus session with an optional task link, displayed in the dashboard and floating timer. It uses the existing persisted Pomodoro timer state, completes without a break, and does not create an activity log.
- Preserved decoding of older saved Pomodoro sessions. Local Swift build, unsigned app package and 34/34 core checks pass; runtime UI acceptance remains pending.

## 11 November 2026 — stopwatch and countdown (in review)
- Added a saved stopwatch with pause/resume and ordered laps, plus a configurable countdown with a persisted deadline and one-time completion state. Both controls appear in the Focus screen, and countdown expiry sounds once during an active session.
- Local Swift build, unsigned app package and 32/32 core checks pass. Clock-change handling, runtime sound behavior and interactive UI acceptance remain pending.

## 11 November 2026 — provider state hardening (in review)
- Made task rows easier to scan with material-backed cards and kept the full task details form reachable in a bounded scrolling sheet. The local app package builds and all 27 core checks pass; GitHub CI for this polish is pending.
- Cleared cached calendar ranges after permission loss or disconnect, refreshed events immediately after explicit publish, and made Google Keychain updates preserve the existing token if a write fails.
- Expanded the Google Desktop client setup guide for the OAuth consent screen, test users and required scopes. Local Swift build and 27/27 checks pass; live Google sign-in still awaits a Desktop client ID.
- Guarded OAuth randomness and listener cancellation, limited publish choices to calendars that allow writes, and kept the publish preview tied to the saved block so unsaved edits cannot change the approved event. The unsigned app package builds with these changes; interactive UI inspection is still unavailable.

## 10 November 2026 — P02/P03 macOS feature build and floating focus (in review)
- Added multi-line paste/drop task capture with documented `!high`, `@tomorrow` and `#ListName` metadata, explainable next-task ranking, first-step/estimate/appearance fields, link attachments, a filtered glass task panel, and independent planner blocks with a backed-up SQLite v2 migration.
- Added day/week/month/year calendar views, weekly drag create/move/resize, overlap warnings, Apple EventKit read and confirmed publish/remove, Google Desktop OAuth PKCE with Keychain tokens and Calendar API read/publish/remove, source filters, regional holiday calendar display/deduplication, and bounded calendar refresh ranges. Google live connection requires a user-provided Desktop client ID.
- Added a persisted Pomodoro cycle with a glass always-on-top timer panel. Both extra panels animate into view while honoring Reduce Motion. The notch remains absent.
- Local build, unsigned app package and 27/27 core checks pass, including the v1→v2 migration backup, capture parser, recommendation ranking and published-link removal checks. Provider permission, OAuth, full UI, multi-display, holiday-region, and packaged runtime acceptance remain pending. Rollback: revert branch and restore the pre-v2 SQLite backup if needed.
- PR #8 macOS CI found a stricter Swift concurrency check around EventKit's async permission API. Switched to its completion callback wrapped in a continuation and guarded an early Google OAuth callback. The latest CI build passed on `8240010`.

## 10 November 2026 — P00 source inventory and issue intake (in review)
- Added an explicit no-reuse matrix for the available source and an issue template for feature acceptance. The archived reference projects have no source trees in this checkout; Android has no target to build.

## 10 November 2026 — P01 app shell, panels and local data controls (in review)
- Added a native Today surface with summary cards, a single floating task panel with pin/position settings, a command palette, ⌘K/⌘N and direct navigation shortcuts, and a skippable welcome flow.
- Added persistent compact layout, Today plan visibility, panel pinning and Dock icon preferences. Added local backup export/restore containing attachments and settings, validation before restore, a safety backup, and confirmed local erase.
- Local Swift build, unsigned app package and 13/13 checks pass. The packaged app launched and stayed running on macOS. Interactive UI, accessibility, multi-display panel behavior and import/export through macOS dialogs remain pending. Rollback: revert this branch; existing workspace schema is unchanged.

## 10 November 2026 — P01-FR43 appearance settings (in review)
- Added typed, versioned theme and accent settings with immediate dashboard/menu application and reset controls.
- Settings persist across store instances; corrupt data is surfaced instead of silently overwritten. Local Swift build and 8/8 checks pass; unsigned app bundle builds.
- Full FR-43 acceptance still needs broader controls and runtime UI checks. Rollback: revert this branch; task data is untouched.

## 10 November 2026 — P01-FR41 menu command center (in review)
- Added direct menu routes to Today, Tasks and Planner, plus completion of the next open task and a truthful local-only status label.
- Local Swift build and 6/6 checks passed; unsigned app bundle built. Runtime UI inspection timed out, so full FR-41 acceptance remains IN REVIEW.
- Rollback: revert the P01-FR41 commit; no schema or data migration was added.

## 10 November 2026 — baseline audit and tracker reconciliation
- Inspected public repository through merged PR #3 (`2aa1509`), source targets, direct dependencies and current feature boundaries.
- Reproduced clean macOS build and 6/6 tests; produced unsigned app bundle and validated its Info.plist. UI launch and signed distribution remain unverified.
- Added baseline audit, data/calendar/timer/sync ADRs and a PR evidence template. Feature statuses remain below DONE until full acceptance evidence exists.
- Original Aura, Loopin and Logtrackin source repositories are absent; no code was reused from them. Notch remains untouched.
