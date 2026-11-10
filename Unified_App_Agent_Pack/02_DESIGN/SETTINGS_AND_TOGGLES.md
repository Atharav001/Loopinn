# Settings, Customization & Toggle Contracts

## Settings navigation
General; Appearance; Dashboard & Navigation; Tasks & Scheduling; Timers & Focus; Activity Logging; Calendar Integrations; Notch (only if module installed); Widgets & Panels; Media & Utilities; Notifications & Permissions; Account & Sync; Privacy & Data; Accessibility; Advanced & Diagnostics.

## Setting schema
Each setting has `key`, `type`, `default`, `validation`, `scope` (device/account), `requiresRestart`, `permission`, `dependency`, `helpText`, `migrationVersion`, `changeEvent`. Persist typed values; schema-version changes; never scatter independent raw string keys.

## Required settings and toggles
| Group | Controls | Important rule |
|---|---|---|
| General | Launch at login, Dock icon, menu-bar icon, reopen dashboard, time format, first weekday | Launch as menu-bar utility by default |
| Appearance | System/light/dark, accent, density, transparency, radius preset, motion intensity | Honor OS contrast/Reduce Motion overrides |
| Dashboard | Visible navigation tabs, default page, card visibility/order, inspector, command shortcut | Never hide Settings or essential escape routes |
| Tasks | Default list, quick capture shortcut, reminder preferences, scheduling suggestions | Untimed tasks never auto-create calendar blocks |
| Planning | Snap interval, work hours, conflict warnings, week start, calendar view | Internal timed block creation is automatic; external publishing is not |
| Timers | Focus/break presets, cycles, auto-break, auto-start, completion sound, repeat alarm interval | Persist absolute deadlines and restart policy |
| Logging | Enable prompts, interval, quiet hours, voice opt-in, skip policy, classification behavior | Permission-aware; never fake transcripts |
| Calendar | Apple permission, Google connect/disconnect, visible calendars, external publish policy | Show preview + explicit confirmation for remote writes |
| Widgets/panels | Pin, opacity, always-on-top, position restore, multi-Space, widget visibility | Panel close does not destroy underlying timer/task |
| Media/utilities | Media source, music controls, shelf, clipboard retention, webcam permission | Only enable compiled and permission-granted services |
| Sync/account | Login, device list, auto-sync, offline mode, last success, conflict status | No false connected badge |
| Privacy | Export, import, backup, restore, erase, retention, diagnostics consent | Confirm destructive action; scope local vs cloud |
| Notch (optional) | Enable, display, simulated notch, hover, animation, live activities, music, calendar | Entire group hidden or disabled when module absent |

## Toggle dependency rules
- A toggle may be ON only if capability exists, permission is granted and runtime service confirms active state; otherwise display blocked/needs permission/error.
- Disable voice: stop recording and release microphone; retain previous logs unless deletion requested.
- Disable activity prompts: cancel scheduled notifications and prevent next prompt; do not delete history.
- Disable cloud sync: preserve local outbox and allow re-enable; never mark pending records synced.
- Disable calendar integration: stop future external writes and polling; offer explicit choice for previously published events.
- Disable notch: tear down windows/observers, stop notch-specific polling, leave timers/tasks/media state intact.

## Settings acceptance tests
Test default values, migration, invalid input, permission denial, concurrent change, app restart, offline, account switch, disabled capability, accessibility and reset-to-default. A setting is complete only when UI, persisted value and actual service behavior agree.
