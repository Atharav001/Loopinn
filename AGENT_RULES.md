# Mandatory instructions for the coding agent

1. Read `STATUS.md`, `FEATURE_MATRIX.md`, `IMPLEMENTATION_PHASE_PLAN.md`, the master PRD, architecture and design specifications before modifying code.
2. Start each work session by inspecting `git status`, current branch, HEAD SHA, open PRs and CI results. Never assume earlier tasks are complete from prose alone.
3. Pick the first unblocked ticket whose dependencies are DONE. State the precise files and intended tests before edits.
4. Preserve a working build: do not stack multiple unverified features. If build/test fails, fix or revert before beginning the next ticket.
5. Never silently skip tests, disable failing assertions, fake backend success or claim GitHub push/merge without evidence.
6. For network calls use explicit deadlines, bounded retry with jitter for transient errors, idempotency keys and cancellation. Do not retry permission failures or invalid user input.
7. For writes use transactional migrations, backups and conflict-safe IDs; do not overwrite user data on app launch.
8. For external calendar mutations require explicit consent and record the approved operation; default to internal-only planning.
9. Keep notch implementation isolated and last. No notch imports in core; user must opt in and licensing review must pass.
10. Update tracker, changelog, tests and screenshots in the same feature PR; never mark DONE before merge and verification.
11. End each session with a short report: completed, in progress, blocked, actual tests/build status, PR/commit links, next ticket, and verified percentages.
12. If source repo, macOS runner, signing, or GitHub credentials are unavailable, mark BLOCKED and request access; do not invent verification.

## Branch protection proposal
Require PR reviews, macOS clean build/unit/UI smoke, Android build for companion changes, migration tests for schema changes, security/secret scanning and release packaging smoke. Preserve last-green release tag and a tested rollback procedure.

## Status transition rules
`UNVERIFIED -> TODO -> IN PROGRESS -> IN REVIEW -> DONE`; `BLOCKED` can interrupt any pre-DONE state. `DONE -> REGRESSED` if a later integration breaks acceptance; recalculate counters immediately. A merged PR without runtime evidence is `IN REVIEW`.
