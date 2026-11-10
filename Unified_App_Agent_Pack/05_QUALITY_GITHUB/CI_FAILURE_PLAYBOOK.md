# Quality Gates, GitHub Workflow and Failure Playbook

## Branch and PR policy
- Protected `main`; short-lived `feat/<ticket>-<slug>` branches; no direct pushes to main.
- Each ticket: issue with feature ID, dependency, acceptance criteria, error matrix, migration risk and rollback. Commits use `feat:`, `fix:`, `test:`, `docs:` prefixes.
- After each independently completed feature: commit, push branch, create PR, attach test logs/screenshots, await required CI and review, merge, pull main, create checkpoint tag for major phases.
- Never push credentials, OAuth tokens, signing keys or private user data. Use GitHub encrypted secrets and environment protections.

## Required CI jobs (GitHub-hosted macOS/Ubuntu runners as appropriate)
1. `format-lint`: SwiftFormat/SwiftLint pinned versions, Kotlin lint, markdown link check.
2. `macos-build`: pinned Xcode + SDK, resolve pinned packages, `swift build` / `xcodebuild` for actual app + extensions, archive/package smoke.
3. `unit-contract`: domain, parser, timer, scheduling, classifier, sync contracts.
4. `integration`: ephemeral SQLite migration/rollback, provider adapters against stubs, auth/RLS integration against isolated test backend.
5. `ui-smoke`: macOS launch, dashboard, menu bar, panels, key screens; screenshots and accessibility checks.
6. `android-build`: Gradle wrapper + locked dependencies, lint, unit tests, debug APK and emulator tests where supported.
7. `security`: dependency/license scan, secret scanning, entitlement/privacy checks, SBOM.
8. `optional-notch`: runs only for notch adapter PRs, cannot be required by core-only builds.

## Verified build protocol
- Pin Xcode/Swift/Java/Gradle/plugin versions and lock dependency resolution.
- Build from clean checkout (no developer-local derived data); include exact command and exit status in PR.
- Compile all changed targets and release packaging, not only library modules.
- Use distinct CI environment/staging accounts; no production credentials in tests.
- On failure: capture first root-cause diagnostic, isolate smallest reproducer, fix or revert, rerun entire impacted gate; never ignore compiler warnings that hide concurrency issues.

## Failure modes and mitigation
| Failure | Prevention / detection | Recovery |
|---|---|---|
| Compiler/toolchain drift | Pin versions; clean CI build | Revert incompatible change or update pinned matrix deliberately |
| Dependency unavailable | Lockfiles, cache with checksum, bounded retry | Fail transparently; do not skip tests |
| DB migration crash | Transaction + pre-migration backup + migration tests | Restore backup; safe read-only mode if necessary |
| Duplicate task/calendar blocks | Unique schedule ID, idempotent upsert, transaction | Reconcile links, deduplicate with audit trail |
| External publish without consent | Consent record and server/client guard | Block write; incident logging and repair if breached |
| OAuth expiry/revocation | Token lifecycle and typed 401/403 handling | Refresh once; prompt reconnect, preserve local data |
| API timeout/429/5xx | Operation-specific timeout, exponential backoff+jitter, retry budget | Queue pending operation; show honest status; user retry |
| Partial sync / conflict | Per-record acknowledgement, cursor commit after local transaction | Replay idempotently; conflict UI and tombstones |
| Sleep/restart timer drift | Persist absolute deadline and lifecycle hooks | Reconcile missed periods, never fabricate activity |
| Widget stale state | App Group versioned snapshots and timeline reload | Reload from canonical store; ignore stale version |
| Android Doze/reboot | OS-compatible scheduling + device tests | Explain delivery limits; reschedule when permitted |
| Permission denial | Capability probes and UI state machine | Offer Settings guidance; preserve offline workflow |
| Notch crash/geometry | Optional isolated adapter and multi-display tests | Disable adapter and return to menu bar/dashboard |

## Timeout policy
Set separate, configurable timeouts for connect, request, total operation and UI wait. Idempotent reads may retry; writes retry only with stable idempotency key. Apply bounded backoff with jitter, honor Retry-After, allow cancellation, persist outbox before network attempt. Never spin indefinitely or mark success before provider acknowledgment.

## Definition of Done
Feature works from clean install, after restart, offline/permission denied where relevant; acceptance and regression tests green; docs and settings updated; no mock status in production; migration safe; screenshots checked; PR merged under protected-branch policy; GitHub state actually verified.

## Agent stop conditions
Missing source/credential, red build, ambiguous destructive behavior, license conflict, failed migration, unverified API contract, security finding or flaky CI: STOP, document evidence, propose fix, request human decision when required. No assertion that failures are impossible.
