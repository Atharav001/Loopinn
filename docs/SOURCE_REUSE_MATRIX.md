# Source inventory and reuse decision

Audited 10 November 2026 for P00. Loopinn is built as original Swift code in this repository.

| Source | Material present in workspace | Reuse decision | License action |
|---|---|---|---|
| Current Loopinn | SwiftUI executable, Swift core, tests and build scripts | Continue original implementation | No third-party package dependencies |
| Aura | Product and design references only; no source tree | No code reuse | Reassess only if source is later supplied |
| Earlier Loopin | Product and design references only; no source tree | No code reuse | Reassess only if source is later supplied |
| Logtrackin | Archived technical analysis document; no source tree | No code reuse | Reassess only if source is later supplied |
| Boring Notch | No fork or source tree in this checkout | No code reuse; P08 remains isolated and opt-in | GPL-3.0 distribution review before any reuse |

This matrix closes the decision for the code currently in the repository. It does not certify absent source trees or grant permission to copy them later. The macOS baseline build and tests are reproducible with `swift test --disable-sandbox` and `sh scripts/build-app.sh`. Android build is not applicable to this checkout because no Android target exists yet.
