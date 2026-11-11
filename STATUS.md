# Build status dashboard

**Last verified update:** 11 November 2026, P02/P03 PR #8  
**Repository:** [Atharav001/Loopinn](https://github.com/Atharav001/Loopinn), public  
**Baseline SHA:** `3170cc6` on `main`; current branch `codex/import-aura-loopin`, stacked on P04/P05 PR #12
**CI status:** PR #12 macOS build passed for `236123a`; launch-evidence documentation update pending CI
**Latest packaged build:** unsigned `dist/Loopinn.app` rebuilt with imported Aura/Loopin views and embedded WidgetKit extension, then freshly launched on this Mac; process observed running. Signed installation and interactive UI acceptance pending
**Current ticket:** P03/P04 calendar and timesheet UI on `codex/import-aura-loopin`; 53/53 core checks and unsigned Xcode app/extension build passed
**Current UI repair:** `codex/import-aura-loopin` now fixes the collapsed command center and adds empty-workspace entry points; visual acceptance of the rebuilt menu remains pending.
**Floating window update:** Tasks, Pomodoro, Ripple Focus and Log Activity have per-window pin controls and flexible sizing; Ripple Focus uses a separate double bell. Runtime interaction and sound acceptance remain pending.
**Window persistence repair:** NSPanel hide-on-deactivate is disabled, so a floating window remains visible when another app is clicked. Pinned panels join all spaces; visual acceptance remains pending.
**Calendar/timesheet update:** Month events and day/week hourly grids now share Loopinn's block and connected-event data. Timesheet overlap lanes have focused tests; live calendar/provider UI checks remain pending. Floating panels use opaque native title bars.
**Responsive layout update:** Month grid scales to the available width/height with no fixed 805-point canvas or calendar scroll; menu actions request popover dismissal before opening windows. Local UI interaction acceptance remains pending.
**Blockers:** Android target and signed release setup do not exist. Google live connection awaits a Desktop client ID. Aura and Loopin-macOS repositories are now available for source adaptation; the notch remains paused.

## Completion counters
- Selected scope: **51 features**.
- Verified DONE: **0/51** under the full acceptance definition (0.0%).
- Verified IN REVIEW: **44** (all P01, P02, P03, P04 and P05 feature IDs); implementation compiles, with runtime, provider, signing and edge-case acceptance still outstanding.
- Verified IN PROGRESS: **0** feature IDs; other feature IDs remain UNVERIFIED/TODO.
- Verified blocked feature IDs: **0**; Aura and Loopin source trees are available for adaptation, while live provider credentials remain separate.
- Notch: **optional final P08**, must not be treated as core-complete.

**Feature completion formula:** `DONE feature IDs / 51 * 100` (only after evidence audit).  
**Core completion formula:** `DONE non-notch feature IDs / 47 * 100`. Four notch-specific features are FR-35, FR-36, FR-39 and FR-40.  
**Ticket completion formula:** `DONE implementation tickets / total tracked implementation tickets * 100` (track AUD/REL tickets separately from FR tickets).  
Do **not** equate lines of code, commits, passing unit tests or phase starts with feature completion.

## Phase board
| Phase | Scope | Status | Completed / Total FRs | Exit gate | Latest PR |
|---|---|---|---|---|---|
| P00 | Baseline, repo audit & decisions | IN REVIEW | 0 / 0 | Aura and Loopin source now available and partly adapted; source inventory and ADRs need reconciliation | PR #4; PR #13 source adaptation |
| P01 | App shell, design system, settings & CI | IN REVIEW | 0 / 6 | Six feature slices compile; UI smoke, panel behavior, global actions and privacy review pending | PR #5, #6, #7 |
| P02 | Tasks & internal scheduling | IN REVIEW | 0 / 7 | Task capture, recommendations, details, panels and independent blocks compile; UI acceptance pending | PR #8 |
| P03 | Calendar & external provider integrations | IN REVIEW | 0 / 5 | Calendar grids and adapters compile; live provider and UI acceptance pending | PR #8; PR #13 |
| P04 | Timers, prompts & logging | IN REVIEW | 0 / 16 | All 16 feature IDs have implementation slices; full UI, permission and edge acceptance pending | PR #8–#13 |
| P05 | Analytics, widgets, media & utilities | IN REVIEW | 0 / 10 | All 10 feature IDs have implementation slices, including packaged WidgetKit extension; signed/runtime acceptance pending | PR #12 |
| P06 | Cloud & Android | UNVERIFIED | ? / 3 | Not verified | — |
| P07 | Full core regression & pause checkpoint | UNVERIFIED | ? / 0 | Not verified | — |
| P08 | Optional notch integration — LAST | UNVERIFIED | ? / 4 | Not verified | — |

## Current sprint / next action
- **Current:** Calendar and timesheet UI source builds on PR #13; the unsigned app package with its task widget exists. Runtime UI, signed widget installation and live provider acceptance remain pending.
- **Next engineering ticket:** P03/P04 calendar gesture and provider acceptance, then P04/P05 runtime behavior and data backup review. Google live connection awaits a Desktop client ID.
- **Notch:** P08 remains absent; user previously directed a pause before implementing it.

## Agent update template (append after every merged ticket)
```text
DATE / TIME (UTC):
TICKET / FR:
PHASE:
STATE: TODO | IN PROGRESS | BLOCKED | IN REVIEW | DONE
WHAT CHANGED:
FILES / MIGRATIONS:
TESTS RUN + EXACT RESULTS:
CLEAN BUILD + PACKAGED SMOKE:
FAULT / TIMEOUT / OFFLINE CASES:
GITHUB BRANCH / PR / MERGE SHA:
SCREENSHOT / LOG EVIDENCE:
KNOWN LIMITATIONS:
ROLLBACK:
NEXT TICKET:
COUNTERS: verified feature DONE x/51; core DONE y/47
```
