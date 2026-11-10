# Unified Productivity App — Agent Implementation Pack

## Decisions (locked)
- Preserve all 51 selected capabilities; complete all before first **public** release, except the notch is a separately installable/enableable **optional final phase** and must never block shipping the otherwise complete core app.
- Launch as a macOS menu-bar utility; open the dashboard on demand. Notch integration is disabled/absent by default until explicitly authorized.
- Timed tasks with a valid start and end automatically create/update an **internal** calendar block. Due-date-only and untimed tasks never auto-schedule; suggestions require approval.
- Apple/Google Calendar publication always requires an explicit confirmation for each proposed batch/action. No silent remote writes.
- Android is a focused companion: tasks, calendar, activity logs, timers and sync.
- Development: fresh modular core with audited selective reuse from Aura, Loopin and Logtrackin.

## Read in this order
1. `01_PRODUCT/MASTER_PRD.md` — product scope and original feature contracts.
2. `02_DESIGN/PREMIUM_UI_SYSTEM.md` — visual language, layouts, states, accessibility.
3. `02_DESIGN/SETTINGS_AND_TOGGLES.md` — customization and settings contracts.
4. `03_ARCHITECTURE/SYSTEM_DESIGN.md` — boundaries, schemas, interfaces.
5. `04_IMPLEMENTATION/PHASED_EXECUTION.md` — precise sequencing and gates.
6. `05_QUALITY_GITHUB/CI_FAILURE_PLAYBOOK.md` — build verification and GitHub cadence.
7. `06_OPTIONAL_NOTCH/NOTCH_PLUGIN_PLAN.md` — **only after all core gates pass and user explicitly opts in**.
8. `07_SOURCE_ARCHIVE/ORIGINAL_ENGINEERING_BLUEPRINT.md` — preserved original planning artifact.

## Agent operating contract
- Do not claim a feature complete because files compile, a screenshot exists, a mocked response succeeded or an old README says so.
- Before each task: inspect current repository state, identify exact code owners, write tests and failure matrix, then implement minimal change.
- After each task: format/lint, compile relevant targets, unit tests, integration tests, UI smoke tests, run packaged app where possible; commit to branch, push, open PR, wait for green CI, merge only with approval/policy, then tag checkpoint.
- If no authenticated GitHub remote or permissions exist, **do not claim a push occurred**; provide commands and report blocked state.
- A red build is a stop condition. Fix or revert before proceeding; never bypass tests to manufacture green status.
- No guarantees of zero defects: design measurable gates, retry/recovery paths, and honest failure reporting.
