# Implementation changelog

> Append entries only after actual implementation or verified baseline audit.

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
