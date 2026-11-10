# Aura macOS App — Complete Technical Implementation Guide

**Repository reviewed:** `Aura-mac-app`  
**App version in `Aura/Info.plist`:** 1.6.1 (build 16)  
**Widget version in `project.yml` / `AuraWidgets/Info.plist`:** 1.5.2 (build 14)  
**Platform:** macOS 14+; Swift 5 language mode with Swift 6 toolchain; SwiftUI + AppKit; Swift Package Manager main app; optional Xcode WidgetKit extension.

> This guide describes the implementation that exists in this repository, including vendored Boring Notch code and excluded/shimmed features. It is a technical architecture and change map, not a claim that every source file in the checkout is compiled into the app.

## 1. Product and runtime overview

Aura is a menu-bar macOS application that hosts a Dynamic Island/notch surface, provides focus and time-management tools, and can show independent floating panels. The notch UI is the vendored Boring Notch `ContentView` stack. Aura-specific functionality includes the Command Center, panel management, focus overlay, settings, URL routing, and a shared Todo/Pomodoro data layer. When full Xcode is available, `run.sh` also builds and embeds a WidgetKit extension for desktop widgets.

### Launch sequence

1. SwiftPM enters at `Aura/AuraApp.swift` (`@main AuraApp`) and delegates lifecycle to `AppDelegate`.
2. `applicationDidFinishLaunching` chooses accessory or regular activation policy from `ui.dockVisible`; installs an invisible keep-alive window so closing panels does not quit the menu-bar app.
3. Initializes `DataStore`, `SharedDataStore`, `PomodoroController`, and `MenuBarManager`; sets app icon; starts `BoringNotchHost` and `FocusManager`; applies saved appearance.
4. Requests alert/sound notification permission, asynchronously attempts WidgetKit registration, registers the `aura://` URL event route, and watches Darwin/distributed notifications plus a short poll for pending widget quick-compose requests.
5. Handles start Pomodoro / Deep Work and completion notifications by starting focus visuals and presenting or updating the Pomodoro panel.
6. The app continues running with zero visible windows. `applicationShouldTerminateAfterLastWindowClosed` returns `false`.

### Source inclusion caveat

`Package.swift` explicitly excludes the Aura-native `Features/DynamicIsland/NotchView.swift`, `CalendarService.swift`, and `Core/NotchManager/NotchManager.swift`. The active notch implementation is `Aura/BoringNotch/ContentView.swift`, coordinated by `BoringNotchHost` and `BoringViewCoordinator`. Several vendored modules are excluded and replaced with `BoringNotch/Shims/BoringNotchShims.swift`. `AuraWidgets.xcodeproj` is generated/maintained by `project.yml`; its extension is not part of the SwiftPM executable target.

## 2. Architecture and data flow

```text
AuraApp / AppDelegate
 ├─ BoringNotchHost → Boring Notch ContentView + BoringViewCoordinator
 │   ├─ MusicManager / media controllers (Spotify, Apple Music, Now Playing)
 │   ├─ CalendarManager + EventKit calendar UI
 │   └─ notch activity views (music, Pomodoro, stopwatch, system events)
 ├─ MenuBarManager → MenuBarView → PanelManager → FloatingPanel + widget views
 │   ├─ PomodoroController ───────────────┐
 │   ├─ StopwatchViewModel                │
 │   └─ TodoViewModel                     │
 ├─ DataStore (app-local JSON, settings, history, shelf paths)
 └─ AuraShared.SharedDataStore (App Group JSON + defaults)
      ├─ AuraWidgets timeline providers / AppIntents
      └─ Darwin + NotificationCenter + WidgetCenter reloads
```

- **UI:** SwiftUI views; AppKit windows, status bar, popovers, event routing, window activation and screen geometry.
- **Local persistence:** `Aura/Models/DataStore.swift` stores Codable app data under Application Support (`Aura/aura_data.json`) with a lock and atomic JSON write. `AppSettings` provides typed access to string-key settings.
- **Cross-process persistence:** `AuraShared/SharedDataStore.swift` maintains versioned `AuraSharedPayload` (Todo lists + Pomodoro snapshot), writes an App Group JSON file and suite `UserDefaults` payload, with local app support backup where applicable. It reloads the freshest valid copy by timestamp, normalizes/migrates schema, posts Darwin and in-process notifications, then requests WidgetKit timeline reloads.
- **Concurrency:** Main app UI and timer controllers are generally main-actor isolated; persistence uses locks and Codable snapshots; cross-process updates use Darwin notifications. Avoid assuming SwiftUI observation alone crosses app/extension processes.
- **Deep links:** Bundle URL type claims `aura://`. `AuraURLRouter` dispatches compose, silent todo actions, and panel routes. Quick Compose also uses a pending shared request, Darwin/distributed notifications, app activation and polling to cover launch races.

## 3. Complete feature inventory and implementation map

### 3.1 Dynamic Island / notch

**Primary files:** `Aura/BoringNotch/BoringNotchHost.swift`, `ContentView.swift`, `BoringViewCoordinator.swift`, `BoringNotchWindow.swift`, `NotchHomeView.swift`, `NotchGeometry.swift`, `BoringViewModel.swift`, `NotchSpaceManager.swift`, `NSScreen+UUID.swift`, `NotchPassThroughHostingView.swift`.

**How it works:** `BoringNotchHost` owns notch window(s), positions them against selected screens, listens for display/geometry settings, and updates mouse pass-through. The closed state only intercepts input over the physical island/hit region; expanded state accepts interaction. `ContentView` builds the visual surface, hover expansion, gestures, drag/drop zones, home view, tabs and live activities. `BoringViewCoordinator` tracks selected view, screen, preferences, live activities and expansion state. Geometry code determines physical/simulated notch dimensions and compact wing sizing.

**Implementation sequence for a change:**
1. Identify whether behavior belongs in host/window geometry, shared coordinator state, or SwiftUI content.
2. Add persisted preference only if user configurable; add a stable `DataStore.SettingKey` and defaults migration/read path.
3. Implement geometry and hit testing in the geometry/host layer; keep closed-state pass-through behavior correct.
4. Add or update view composition in `ContentView` or a component; keep state in coordinator/view models rather than unmanaged globals.
5. Subscribe to screen and preference changes and refresh all relevant notch windows.
6. Manually verify built-in notch, simulated notch, external display selection, open/closed hover, click-through areas, and full-screen transitions.

### 3.2 Media and music

**Primary files:** `Aura/BoringNotch/managers/MusicManager.swift`, `Aura/Features/DynamicIsland/MediaTracker.swift`, `MediaControllers/{SpotifyController,AppleMusicController,NowPlayingController,MediaControllerProtocol}.swift`, `PlaybackState.swift`, `MusicVisualizer.swift`, `ImageService.swift`, `ContentView.swift`.

**Behavior:** Tracks current media metadata/artwork and playback; supports play/pause, next/previous, shuffle/repeat and configurable skip increments; presents live music activity and artwork. AppleScript automation controls Spotify / Music; system Now Playing is selected where available. Media source preferences and enabled flags are stored in Defaults/DataStore. Track metadata is also persisted as `LastTrackInfo` for restoration/context. The vendored source includes a YouTube Music controller directory, but `Package.swift` excludes it.

**Implementation sequence:** add/extend `MediaControllerProtocol`; implement source-specific metadata polling and Apple Events commands; update manager source selection and fallback rules; marshal updates to main actor; update artwork fetch/cache and view; add usage text/automation entitlement if a new app is controlled; add setting and error state; manually test app absent, denied automation, stale artwork, paused/playing, and switching sources.

### 3.3 Calendar and reminders

**Primary files:** active vendored `CalendarManager.swift`, `CalendarModel.swift`, `EventModel.swift`, `BoringCalendar.swift`, `CalendarServiceProviding.swift`, calendar components in `ContentView`. Aura-native `Features/DynamicIsland/CalendarService.swift` and `NotchView.swift` are excluded from SPM.

**Behavior:** EventKit-based event retrieval and calendar presentation, home-strip calendar mode, selected-day browsing, event indicators, configurable all-day filtering and title truncation. Calendar access is optional. The README mentions Reminders, but review the actual active manager and `Info.plist` before expanding functionality: only calendar usage descriptions and calendar entitlement are visible in the current configuration.

**Implementation sequence:** request/check appropriate EventKit authorization; query a bounded date interval; map EventKit values to display models; handle authorization changes and empty/error states; connect date selection and filters to UI; update privacy usage strings/entitlements; test granted, denied, no calendars, all-day, timezone/day-boundary, and large event titles.

### 3.4 Command Center / menu bar

**Primary files:** `MenuBarManager.swift`, `MenuBarView.swift`, `MenuBarViewModel.swift`, `MenuBarIconFactory.swift`, `AppDelegate.swift`.

**Behavior:** `NSStatusItem` opens an application-defined popover. `MenuBarView` exposes Pomodoro, Deep Work, Stopwatch, To-Do, settings and audio/file related actions. The manager sizes popover to SwiftUI intrinsic content, handles outside-click dismissal, and defers panel-spawning actions until the popover closes so AppKit does not cancel them. Icon visibility follows preferences.

**Implementation sequence:** add a UI action and its view-model operation; route window actions through `runAfterClosingPopover`; add a notification or direct main-actor service call for lifecycle-level actions; implement setting persistence; check accessory activation and outside-click behavior; test with Dock hidden and visible.

### 3.5 Floating panels and widget shell

**Primary files:** `FloatingPanel.swift`, `PanelManager.swift`, `WindowSpaceBehavior.swift`, `WidgetContainer.swift`, `WidgetState.swift`, `AdaptiveWidgetScale.swift`, `WindowDragHandle.swift`, `WindowResizeHandle.swift`.

**Behavior:** A keyed panel registry prevents duplicate Todo/Pomodoro/Stopwatch panels. Panels are always-on-top, resizable/draggable, optionally pinned, translucent/blurred and placed across Spaces according to window behavior. `WidgetContainer` supplies shared chrome, controls, opacity/blur, pinning, attention, resizing and move-to-notch callbacks. Todo panel size reflects configured columns; panels snap near screen edges. Pomodoro/stopwatch can move into notch live-activity mode and be restored to panels.

**Implementation sequence:** register a stable panel key and view factory; set design and initial sizes; implement panel state/chrome in `WidgetContainer`; define close cleanup and keyed registry cleanup; handle multi-display/Space behavior; add settings where appropriate; test duplicate open, close/reopen, resize, pin, all Spaces, and notch handoff.

### 3.6 Pomodoro

**Primary files:** `PomodoroController.swift`, `PomodoroViewModel.swift`, `PomodoroWidget.swift`, `PomodoroSnapshot.swift`, `TimerAlertService.swift`, `TimerAttentionOverlay.swift`, `ScreenEdgeGlowManager.swift`, `ConfettiView.swift`, shared store and notch live activity.

**Behavior:** Main-actor singleton tracks idle/running/paused/finished, focus/short-break/long-break phases, cycle count, duration, remaining time, automatic continuation and alert playback. State hydrates from shared snapshot and uses wall-clock `endDate` for cross-process countdown consistency. Duration changes/settings sync into shared storage. Completion can notify, play chosen built-in/custom sound, show attention and celebration, and update notch/widget surfaces. Toolbar/Dock actions start normal Pomodoro or 50-minute Deep Work.

**Implementation sequence:** define state transition and duration rules in `PomodoroController`; persist a complete `PomodoroSnapshot` (including `endDate`, phase and settings); reconcile remote snapshots without feedback loops; expose controls from views/AppIntents; implement completion sound/notification and focus visuals; reload desktop timeline; manually verify start/pause/resume/reset, phase boundaries, auto-continue, app relaunch, remote widget mutation, and permission-denied notification behavior.

### 3.7 Stopwatch / countdown

**Primary files:** `StopwatchViewModel.swift`, `StopwatchWidget.swift`, `StopwatchLiveActivity.swift`, panel/notch handoff in `PanelManager`.

**Behavior:** View model supports stopwatch and countdown modes, elapsed/remaining display, laps, start/stop/reset, alarm sound selection and stop. `PanelManager` can move the surface to a notch live activity. Unlike Pomodoro, the inspected shared snapshot is specifically Pomodoro; do not assume Stopwatch survives app relaunch or syncs to desktop widget without adding a schema and sync path.

**Implementation sequence:** keep time source monotonic for elapsed timing; define countdown completion and lifecycle behavior; bind controls; connect optional notch status; add persistence only if required, version it, and test sleep/wake/time changes and panel/notch transitions.

### 3.8 Multi-list To-Do

**Primary files:** `TodoModels.swift`, `SharedDataStore.swift`, `TodoViewModel.swift`, `TodoWidget.swift`, `QuickComposePanel.swift`, `QuickComposeBridge.swift`, `WidgetDeepLink.swift`, `AuraURLRouter.swift`.

**Behavior:** Codable Todo items/lists support completion, star, create/edit/delete, list rename/delete, visibility pinning, color palette and deterministic ordering. Lists persist cross-process for floating panels and desktop widgets. Migration upgrades older single-list and generic-list payloads; it ensures at least one visible list and two visible columns when possible. Quick compose routes from widgets into Aura; silent deep links support toggle/delete/clear-completed.

**Implementation sequence:** change shared Codable models with backward-compatible decode defaults; update `SharedDataStore` mutation APIs and schema normalization; publish notifications only after successful persistence; update view model and UI; add corresponding AppIntent/deep-link actions if widget-accessible; refresh widget timelines; test migration, deletes against stale copies, empty title/list, last-list safeguards, cross-process updates and pinned visibility.

### 3.9 WidgetKit desktop widgets

**Primary files:** `AuraWidgets/TodoDesktopWidget.swift`, `PomodoroDesktopWidget.swift`, `AuraWidgetIntents.swift`, `AuraWidgetsAppIntents.swift`, `AuraWidgetsBundle.swift`, shared models/store, `WidgetRegistrar.swift`, `project.yml`, entitlements and plists.

**Behavior:** `TimelineProvider`s read fresh shared payloads and render Todo/Pomodoro configurations. AppIntents mutate shared storage for task/list actions and timer changes. App Group `group.com.aura.macos` is required. `run.sh` conditionally generates/builds `AuraWidgets.xcodeproj`, embeds `.appex` and `AuraShared.framework`, signs nested products, registers with PlugInKit/Launch Services, and restarts WidgetKit services. Without full Xcode, floating overlays still work but desktop widgets are omitted.

**Implementation sequence:** add widget model/configuration/provider and view; ensure kinds remain stable; add intents in shared extension target; set App Group entitlements on app/extension/framework; keep app and widget signing compatible; embed framework and extension with correct runpaths; register after install; reload timelines after writes; test the actual installed `.app`, not just SwiftPM executable, and remove/re-add a widget after kind/layout changes.

### 3.10 Settings and appearance

**Primary files:** `Aura/Features/Settings/SettingsView.swift`, `Aura/Models/AppSettings.swift`, `DataStore.swift`, `ThemeManager.swift`, `LiquidGlass.swift`, `GlassmorphicMaterials.swift`, `AnimationCurves.swift`, settings window in `PanelManager`.

**Behavior:** Settings groups general, notch/display, appearance/material, gestures/interactions, media, calendar/battery, Pomodoro, widgets, shelf/clipboard, and app integration options. Values are mostly string-backed in local JSON; some Boring Notch settings use `Defaults` or `@AppStorage`. This means not all preferences share the same store; use the existing key’s store consistently.

**Implementation sequence:** create a typed key in `SettingKey`; choose correct default and migration; add settings state and UI; apply changes immediately or on save; notify host/view models when runtime geometry or behavior must refresh; update tests/manual validation; ensure reset/default paths and settings survive relaunch.

### 3.11 Focus overlay and alerts

**Primary files:** `FocusManager.swift`, `FocusViewModel.swift`, `FocusOverlay.swift`, timer completion notifications and `AppDelegate` handlers.

**Behavior:** Starting focus activates a dim/ripple overlay; completion triggers a wave. Pomodoro/Deep Work actions start focus. Focus is a visual ritual and does not appear to enforce app blocking or system-wide focus restrictions.

**Implementation sequence:** trigger start/stop through `FocusManager`; keep animation state main-actor bound; ensure end animations clean state; connect completion without stopping focus during auto-loop; verify repeated starts and rapid stop/start.

### 3.12 File shelf / clipboard / audio utilities present in source

The checkout includes vendored components for Shelf drag/drop, Quick Look, thumbnailing, sharing, temporary files, bookmark persistence, clipboard-content helpers, local audio selection/player, webcam/mirror, battery, brightness and volume managers. `NOTICE.md` and `Package.swift` exclusions define what is shimmed or unavailable. Treat each as active only after tracing references from compiled targets: source presence alone does not guarantee it is exposed or operational. Shelf/clipboard persistence fields exist in `DataStore`, while some associated vendored modules are present but may not be wired into Aura's shipped surface.

**Implementation sequence:** first confirm source is included by SwiftPM/Xcode and reachable from an active view; then implement service/model/view-model/view layers; scope/security-bookmark file access; persist only durable state; update privacy strings/entitlements; test cancellation, permissions, stale bookmarks, external volume and cleanup.

## 4. Persistence schemas and integration contracts

### Local `DataStore`

- `todoItems` legacy flat list, migrated once to the shared multi-list store when shared data is empty.
- `settings`: `[AppSettings(key,value)]`, typed using `DataStore.SettingKey`.
- `lastTrack`: metadata and optional icon bytes.
- `clipboardItems`: pinned items retained; unpinned items older than seven days are pruned.
- `shelfPaths`: paths, not security-scoped bookmark data in this model.
- File writing is JSON and atomic; protect mutations with its lock.

### Shared payload

- `AuraSharedPayload` contains schema version, timestamp, Todo lists and Pomodoro snapshot.
- App Group identifier: `group.com.aura.macos`.
- JSON name: `aura_shared.json`.
- Stable widget kinds: `com.aura.macos.widgets.todo`, `com.aura.macos.widgets.pomodoro`.
- Cross-process update path: save JSON + suite defaults → Darwin notification → in-process notifications → deferred WidgetCenter timeline reload.
- Store chooses newest valid timestamp from App Group locations and suite preferences. Stale payloads must not overwrite newer in-memory state; timestamp precedence is specifically intended to avoid deleted item resurrection.

**When changing persisted structures:** add decode defaults for new fields, bump schema version, normalize old data, preserve identifiers where possible, write a migration test, and verify app plus widget extension independently read/write the same App Group data.

## 5. Build, run, signing, and release process

### Developer run

1. Install Swift toolchain / Xcode Command Line Tools; macOS 14+.
2. From repository root run `chmod +x run.sh` once if needed, then `./run.sh`.
3. Script selects/creates local signing identity, runs `swift build`, assembles `/tmp/Aura.app`, copies plist/icons/sounds/resources and signs with app entitlements.
4. If full Xcode is selected, attempts widget project generation/build, embeds extension/framework, signs them, installs to `/Applications/Aura.app`, registers it, then opens it.
5. If only CLI tools are available, Aura app and floating widgets work, but desktop WidgetKit extension is skipped.

`swift build` alone produces `.build/debug/Aura`, not the fully packaged app. The bundle plist, entitlements, assets and widget embedding are applied by scripts.

### Release

1. Configure Developer ID Application signing and runtime signing for distribution.
2. Run `./build-release.sh` (optionally configuration argument `release`).
3. Script builds, assembles `/tmp/Aura.app`, optionally builds widgets, signs nested framework/executable/app/extension, creates DMG and ZIP.
4. For notarization set `APPLE_ID`, `TEAM_ID`, `APP_PASSWORD`, and `SIGN_IDENTITY`, then run build script or `scripts/notarize.sh` on the DMG.
5. `scripts/create-installer-dmg.sh`, `scripts/fix-gatekeeper.sh`, `scripts/notarize.sh`, `scripts/install-with-widgets.sh`, `scripts/reload-widgets.sh` and `scripts/setup-local-signing.sh` support packaging/install workflows; inspect each script before changing release behavior.

### Signing/entitlement details

- Main app sandbox, Apple Events automation, selected/download files, audio input, network client, calendar access and App Group are declared in `Aura/Aura.entitlements`.
- Widget extension has App Group entitlement plus compatibility exceptions for app-group paths/defaults under ad-hoc signing.
- Main app and widget need compatible signing for reliable App Group access. Current `run.sh` has a development/local/ad-hoc fallback and explicitly warns that ad-hoc TeamIdentifier can impair App Group resolution.
- App privacy usage descriptions are in `Aura/Info.plist`; bundle identifier and URL scheme are also defined there. Widget extension identity is `com.aura.macos.widgets` from `project.yml`.

## 6. Permissions and external dependencies

- **Calendar:** EventKit requires calendar authorization; app has calendar usage descriptions and calendar entitlement.
- **Automation:** Apple Events to Spotify/Music prompts at runtime; entitlements list Spotify, Music, iCal and CalendarAgent temporary exceptions.
- **Notifications:** app asks alert and sound permission at launch.
- **Files/audio input/network:** declared capabilities for selected files, Downloads, microphone/audio input and network. Verify user-facing permission rationale before adding new capture/access behavior.
- **Build package dependency:** `Defaults` from Sindre Sorhus, resolved through `Package.resolved`.
- **Widget project generation:** optional `xcodegen`; full Xcode required for `xcodebuild` extension build.

## 7. Tests and verification

Tests live in `AuraTests/`:

- `SharedDataStoreTests.swift`: fresh payload, add-and-read persistence, delete does not resurrect from stale copies.
- `TimerLogicTests.swift`: currently contains manual verification comments; no executable XCTest assertions in that file.
- `SwiftDataTests.swift`: manual checklist only; the implementation currently uses Codable JSON stores rather than SwiftData models.

The repository README recommends `swift test` (full Xcode needed for XCTest setup). No tests were run during this documentation review. For each feature change, add focused tests for pure logic and persistence/migration; then verify packaged app behavior on macOS, especially widget signing and multi-display notch interactions. Do not infer manual checklist comments are automated tests.

## 8. Recommended implementation workflow for every change

1. **Trace active target:** inspect references and `Package.swift` exclusions / `project.yml` membership first.
2. **Identify ownership:** model, persistence/service, view model, view, host/window, app lifecycle, or extension.
3. **Define state contract:** inputs, defaults, error/permission states, persistence lifetime, cross-process behavior.
4. **Implement model/service first:** preserve main-actor boundaries; use shared store only when extension/process sharing is required.
5. **Version storage:** Codable fallback + migration + normalization before shipping a schema change.
6. **Connect UI:** wire state and actions into active view; respect accessory activation and popover close timing.
7. **Connect integrations:** notifications, Darwin messages, URL routes, AppIntents, WidgetCenter reloads as needed.
8. **Update packaging:** plist privacy descriptions, entitlements, target membership, resource copy, signing, URL registration.
9. **Verify:** focused logic/persistence tests; build correct target; manual permission-denied, relaunch, multi-display, widget and error-path checks.
10. **Document:** update README and this architecture map when user-visible features, requirements, permissions or build behavior change.

## 9. Important gaps and cautions found during review

- README statements and actual compiled target membership should be checked together. Several folders contain legacy/custom alternatives or vendored features that SwiftPM excludes.
- README mentions Reminders, while current plist/entitlement evidence is calendar-focused; confirm actual Reminders access before promising it.
- The test files for timer and SwiftData mostly contain comments, not automated tests; the active persistence is JSON/Codable rather than SwiftData.
- Main app and widget version numbers currently differ; release process should intentionally synchronize or document that versioning policy.
- `DataStore` persists shelf paths and clipboard items, but their presence does not prove those features are currently surfaced in the active app.
- `BoringNotchShims.swift` returns inert/no-op responses for unavailable Lottie/XPC/accessibility/brightness/Settings behaviors. Do not describe these as fully implemented integrations.
- The Boring Notch vendored stack is GPL-3.0; `Aura/BoringNotch/NOTICE.md` and README explain licensing implications for distribution.

## 10. File index by responsibility

| Area | Files / directories |
|---|---|
| App lifecycle | `Aura/AuraApp.swift`, `Aura/Info.plist`, `Aura/Aura.entitlements` |
| Local models/store | `Aura/Models/DataStore.swift`, `AppSettings.swift`, `TodoItem.swift` |
| Shared app/widget contract | `AuraShared/*` |
| Notch host/UI | `Aura/BoringNotch/BoringNotchHost.swift`, `ContentView.swift`, `BoringViewCoordinator.swift`, `components/Notch`, `models`, `sizing`, `managers` |
| Media | `Aura/BoringNotch/MediaControllers`, `managers/MusicManager.swift`, `Aura/Features/DynamicIsland/MediaTracker.swift` |
| Menu bar | `Aura/Features/MenuBar/*` |
| Floating widgets | `Aura/Core/WindowManagement/*`, `Aura/Features/Widgets/*` |
| Focus | `Aura/Features/FocusRitual/*` |
| Settings/theme | `Aura/Features/Settings/*`, `Aura/Theme/*` |
| Desktop widgets | `AuraWidgets/*`, `project.yml`, `AuraWidgets.xcodeproj/*` |
| Build/release | `Package.swift`, `run.sh`, `build-release.sh`, `scripts/*` |
| Tests | `AuraTests/*` |
| Attribution | `Aura/BoringNotch/NOTICE.md`, `README.md` |

---

**Review boundary:** This guide was written from the checked-in source, package/project configuration, app/extension plist and entitlements, README and tests. It does not claim a live runtime audit or successful build/test run.
