# Premium macOS UI/UX System — 2026 Design Specification

## Design principles
Native-first, quiet luxury, high information clarity, responsive feedback, refined micro-interactions. Avoid gratuitous gradients, fake glass everywhere, neon outlines and dense dashboard clutter. Use system typography (SF Pro/SF Mono), semantic colors, restrained translucency, consistent 4/8-point spacing, large clickable targets and robust keyboard navigation. Support macOS light/dark, increased contrast, Reduce Motion, Dynamic Type where available and VoiceOver.

## Design tokens (initial proposal; validate in UI prototype)
| Token | Specification |
|---|---|
| Spacing | 4, 8, 12, 16, 24, 32 px |
| Radius | 10 px controls, 14 px cards, 18 px panels |
| Layout | Sidebar 240–280 pt, inspector 280–340 pt, content fluid; minimum dashboard 1050×700 pt, test smaller window fallbacks |
| Typography | SF Pro, 12–13 secondary, 14–15 body, 20 section, 28 page title; SF Mono for durations |
| Color | Semantic macOS backgrounds/text; one configurable accent; distinct accessible category palette |
| Motion | 120–220 ms ease for hover/state, 220–320 ms for panel transitions; instant alternatives for Reduce Motion |
| Elevation | 1–2 subtle shadow levels; clear boundaries; no stacked blur that hurts contrast |

## Information architecture
- Menu bar: quick capture, start/pause timer, log now, next task, open dashboard, settings, connection status.
- Main dashboard: sidebar **Today, Tasks, Planner, Timeline, Focus, Analytics, Calendar, History, Utilities, Settings**; persistent top command/search bar; optional right inspector.
- Dashboard default Today: next recommended task, current timer, today schedule, planned-vs-actual progress, one-click log, upcoming events. Empty states teach first action.
- Tasks: lists sidebar; keyboard-first quick add; Today/Later; detail inspector with due date vs scheduled interval, attachments, priority, first step; drag reorder; undo delete.
- Planner: day/week/month/year views; time gutter; click/drag to create; resize and move with explicit snapping; conflict preview; accessible keyboard alternative.
- Timeline: two aligned rails, Planned and Logged; overlaps visible, gaps distinct; edit from either rail; never infer actual activity from a plan.
- Focus: large timer, task link, cycles, focus mode, alarms, audio and visual effect controls.
- Analytics: date selector, summary cards, accessible charts, category breakdown, comparison, export; state exact metric definitions.
- Calendar: local plan vs Apple/Google event source badges, source toggles, explicit publish action and confirmation preview.
- Utilities: file shelf, clipboard, audio/system controls only when capabilities and permissions are verified.

## Surface contracts
1. Floating panels use a shared panel manager (stable ID, restore position, snap, pin, all-Spaces policy, keyboard focus, escape/close, no duplicate instance).
2. Desktop widgets read versioned App Group snapshots; widget actions dispatch through validated intents/deep links; never directly mutate stale independent copies.
3. Notifications are actionable but unobtrusive, never misrepresent an activity as logged.
4. On app launch show menu bar only; dashboard opens on command; restore last dashboard view when subsequently opened.
5. Notch is **not** part of base navigation or base app startup. All important actions remain accessible through menu bar/dashboard/panels.

## Component library
Button (primary/secondary/quiet/destructive), icon button, split button, segmented control, search/command field, token picker, date-time interval picker, confirmation dialog, permission card, offline banner, status chip, timer dial, task row, calendar block, dual rail row, metric card, chart legend, empty/loading/error/success state, toast, sheet, inspector and settings toggle.

## Every component must implement
- Default, hover, focus, pressed, disabled, loading, empty/error states where relevant.
- Keyboard path, VoiceOver label/value/action, contrast test, Reduce Motion behavior.
- Long text, localization, screen resize, no permission, offline and stale-data behavior.
- Screenshot snapshot at light/dark, normal/increased contrast, compact/full width.

## UI quality acceptance
- No clipped controls at supported window sizes; no interaction depends on color alone.
- Input feedback within 100 ms for local actions; long operations show progress and cancellation.
- Every destructive action offers confirmation or undo; every network state reports real status.
- Main dashboard remains fully functional with notch module never installed.
