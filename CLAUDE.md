# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Ritli is a native iOS Pomodoro/focus-timer app (SwiftUI + SwiftData), with a Live Activity / widget extension and a shared framework for Dynamic Island / Lock Screen presentation. No external package dependencies — everything is Apple frameworks (SwiftUI, SwiftData, ActivityKit, UserNotifications, Observation, Testing).

Targets (see `Ritli.xcodeproj`):
- `Ritli` — the main app.
- `RitliLiveActivity` — the widget extension hosting the Live Activity UI.
- `RitliShared` — framework/types shared between the app and the Live Activity extension (e.g. `TimerLiveActivityAttributes`, `TimerLiveActivityPresentation`).
- `RitliTests` — unit tests (Swift Testing).
- `RitliUITests` — UI tests (XCTest/XCUITest), including system-level Live Activity/Dynamic Island tests.

## Commands

All building/testing goes through `xcodebuild` (no SwiftPM CLI usage; no Fastlane). Default simulator device type used in CI is iPhone 17 Pro.

Build for testing:
```sh
xcodebuild -project Ritli.xcodeproj -scheme Ritli -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .derivedData \
  build-for-testing
```

Run the full unit/UI test suite against a booted simulator:
```sh
xcodebuild -project Ritli.xcodeproj -scheme Ritli -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath .derivedData \
  -parallel-testing-enabled NO \
  test
```

Run a single test (Swift Testing suite/test, or XCTest class/method) with `-only-testing`:
```sh
xcodebuild -project Ritli.xcodeproj -scheme Ritli -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath .derivedData \
  -only-testing:RitliTests/TimerEngineCycleTests \
  test
```

Notes mirrored from `.github/workflows/swift.yml` (the CI pipeline):
- Unit tests run separately. Ordinary UI tests are grouped into feature classes and run on two isolated simulator clones with `-parallel-testing-enabled YES -parallel-testing-worker-count 2 -only-testing:RitliUITests -skip-testing:RitliUITests/SystemUITests -skip-testing:RitliUITests/LiveActivityUITests`.
- `SystemUITests` runs sequentially on the original simulator. Only `testOpensAppLanguageSettings` is excluded in CI because hosted simulators can drop the Settings foreground transition; it remains in the full local suite.
- `LiveActivityUITests` runs separately and sequentially with the existing one-retry simulator recovery — ActivityKit/Dynamic Island system UI tests are flaky on hosted simulators.
- `RitliUITestCase` contains shared helpers and setup only. Put new app UI tests in feature classes; put cross-app, background, and system UI scenarios in `SystemUITests` or `LiveActivityUITests` so the parallel step does not select them.
- A separate `test` pass runs `RitliTests/SplashPresentationTests` and `RitliTests/OnboardingStoreTests` against a **Release** configuration build (with `ENABLE_TESTABILITY=YES`) to verify real startup behavior isn't masked by Debug-only code paths.
- `.github/scripts/prepare-ios-simulator.sh` creates the CI simulator and waits for Xcode to recognize it — not needed locally if you already have a simulator.

Sound assets: `scripts/generate-timer-sounds.py` regenerates the procedurally-generated PCM notification tones under `Ritli/Resources/Sounds` — no external audio assets are checked in.

## Architecture

**Composition root.** `RitliApp.swift` builds an `AppDependencies` (`AppDependencies.swift`) at launch via `AppDependencies.live(...)`. This wires a SwiftData `ModelContainer`, loads/seeds the singleton `PomodoroSettings` and `PomodoroCycleState` model rows, runs `DefaultFocusCategories.seedIfNeeded` and `TaskCompletionReconciliation.run`, and constructs the single `TimerEngine` with its concrete collaborators (notification scheduler, Live Activity coordinator, feedback/sound players). `TimerEngine` and `NotificationPermissionService` are injected into the view tree via `.environment(...)` — there is no other DI container. If `AppDependencies.live` throws, the app renders `StartupFailureView` instead of the normal UI. In `DEBUG`, `RitliApp.init` reads `--ui-testing*` launch arguments to run with an in-memory store and tweak settings (shortened durations, disabled notifications, forced sound) for deterministic UI tests.

**TimerEngine is the core state machine** (`Ritli/Timer/TimerEngine.swift`). It's an `@Observable @MainActor` class owning the single `currentSession: FocusSession?` and driving all session transitions (`startFocus`/`startShortBreak`/`startLongBreak`, `pause`/`resume`, `cancel`, `skipBreak`). Key properties of the design:
- Timing is computed from absolute dates (`session.endDate`, `dateProvider.now`), not a running `Timer` — `remainingTime(at:)` is pure and callers (e.g. `ContentView`'s `monitorTimer` polling loop, or `restore()` on relaunch) just re-derive state from the current date. This is what lets the timer survive backgrounding/termination.
- `synchronizeCompletionIfNeeded()` is called at the top of nearly every mutating method so a session that finished while the app was suspended gets reconciled (state transition, cycle advance, sound) before any new action is allowed.
- Every state mutation follows the same shape: mutate `FocusSession`/`PomodoroCycleState`, `try store.save()`, `synchronizeLiveActivity()`, then `playFeedback(...)`. Preserve this order when adding new transitions.
- Pomodoro cycle progression (focus → short break → ... → long break → reset) lives in `advanceCycle(after:)` / `resolveSkippedRecommendationIfNeeded`, driven by `PomodoroCycleState.nextSuggestedKind` and the active `TimerRoutineSnapshot` (a value-type snapshot of durations/auto-start flags, taken from either the task's custom `TimerRoutine` or the global `PomodoroSettings` at session start — so changing settings mid-session doesn't retroactively change an in-flight session).
- All of `TimerEngine`'s collaborators are protocols (`TimerSessionStore`, `DateProviding`, `TimerNotificationScheduling`, `TimerLiveActivityCoordinating`, `TimerFeedbackPlaying`, `TimerCompletionSoundPlaying`), each with a `NoOp*`/fake implementation under `RitliTests/TestSupport` or inline — tests construct `TimerEngine` directly with fakes rather than mocking at a higher layer.

**Persistence** is SwiftData (`Ritli/Persistence/AppModelContainer.swift` defines the `Schema`: `FocusCategory`, `FocusTask`, `TimerRoutine`, `FocusSession`, `PomodoroSettings`, `PomodoroCycleState`). `PomodoroSettings` and `PomodoroCycleState` are singleton rows (fetch-or-insert on launch). `TimerSessionStore` wraps the `ModelContext` for the engine; `TaskCompletionReconciliation` fixes up task/pomodoro completion counts against persisted sessions on launch.

**Live Activity / Dynamic Island** flows through `RitliShared`: `TimerEngine` builds a `TimerLiveActivityDescriptor` (app-side) from the current session, and `ActivityKitTimerLiveActivityCoordinator` (`Ritli/Services/LiveActivities/`) maps that to `TimerLiveActivityAttributes`/`ContentState` (defined in `RitliShared`, consumed by both the app and the `RitliLiveActivity` extension target). The coordinator serializes all `Activity` start/update/end calls through a single chained `Task` (`enqueue`) to avoid ActivityKit race conditions, and self-schedules activity expiration via `scheduleExpiration`/`TimerLiveActivityPresentation.expirationDate`. Any change to the Live Activity's visual content or lifecycle generally touches three places: the descriptor/attributes (shared), the coordinator (app), and `RitliTimerLiveActivityView` (extension).

**Notifications**: `LocalTimerNotificationScheduler` + `NotificationPermissionService` (`Ritli/Services/Notifications/`) schedule/cancel the single pending "session end" local notification keyed by session `UUID`, gated on `PomodoroSettings.notificationsEnabled`. `AppNotificationDelegate` is the `UIApplicationDelegateAdaptor` handling foreground notification presentation.

**Feature modules** under `Ritli/Features/` (`Home`, `Tasks`, `Stats`, `History`, `Settings`, `Onboarding`, `Startup`) are mostly presentation: SwiftUI views plus small pure "presentation"/"calculator" helper types (e.g. `FocusHistoryCalculator`, `StatsCalculator`, `TimerDisplayFormatter`) that are unit-tested independently of SwiftUI. `ContentView` is the tab-based shell and owns the app-level polling loop (`monitorTimer`, driven by `scenePhase`) that calls `timerEngine.refresh(...)` once per second while the app is foregrounded.

**Localization**: `Ritli/Localizable.xcstrings` (and a separate one for `RitliLiveActivity`) are String Catalogs; supported languages are English and Ukrainian (see `LocalizationCatalogTests`). Prefer `Text(.someKey)` / `String(localized:)` over hardcoded strings; `AppLanguagePresentation`/`AppExternalLinks` handle linking out to system language settings.

**Local-only artifacts**: `local-artifacts/` (gitignored) holds release checklists, screenshots, and research notes — not part of the app or CI. Don't look there for app behavior and don't add tracked project documentation there.
