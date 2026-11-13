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
- Unit tests run separately. Ordinary UI tests are grouped into feature classes. CI runs them sequentially on the standard `macos-26` runner: two simulator workers regressed hosted execution despite improving local wall time. Local parallel experiments can use `-parallel-testing-enabled YES -parallel-testing-worker-count 2 -only-testing:RitliUITests -skip-testing:RitliUITests/SystemUITests -skip-testing:RitliUITests/LiveActivityUITests`. CI selects `arch=arm64` explicitly, enables 180-second timeouts for ordinary UI tests, and limits their step to 20 minutes to bound runner-launch hangs. Failure diagnostics, the raw app UI log, and result bundles are uploaded; pipeline failures are preserved with `pipefail`.
- `SystemUITests` runs sequentially on a fresh simulator after the app UI simulator is deleted, isolating it from leftover ActivityKit background launches. The notification test runs one Focus timer (per-kind titles are unit-tested), verifies its `00:15` fixture before starting, and allows up to 60 seconds for the actual banner (hosted notification processing has taken another 34 seconds after expiry). Both system steps have per-test timeouts and step time limits so a hang cannot consume the whole job. Only `testOpensAppLanguageSettings` is excluded in CI because hosted simulators can drop the Settings foreground transition; it remains in the full local suite.
- `LiveActivityUITests` runs separately and sequentially with the existing one-retry simulator recovery — ActivityKit/Dynamic Island system UI tests are flaky on hosted simulators.
- `StringCatalogIntegrityTests` parses both String Catalogs and requires a translated Ukrainian value with matching format arguments for every key, so don't add tests that pin individual translations. Avoid ternaries inside `String(localized:)`/`LocalizedStringResource` keys: string extraction then adds the English defaults as stray keys. Unit tests cover business logic (timer engine, cycle and task rules, persistence, stats/history calculations, notification and Live Activity content, startup); don't add tests for formatting, colours or copy. Keep UI coverage for rendering and interaction: Stats/History cover navigation, charts, calendar and empty states; task creation/completion runs in Ukrainian to cover language wiring and Unicode input. Avoid separate UI launches just to enumerate translations. `makeApp()` launches in English unless a test passes another language.
- `RitliUITestCase` contains shared helpers and setup only. Put new app UI tests in feature classes; put cross-app, background, and system UI scenarios in `SystemUITests` or `LiveActivityUITests` so the app UI step does not select them.
- A separate `test` pass runs `RitliTests/SplashPresentationTests` and `RitliTests/OnboardingStoreTests` against a **Release** configuration build (with `ENABLE_TESTABILITY=YES`) to verify real startup behavior isn't masked by Debug-only code paths.
- `.github/scripts/prepare-ios-simulator.sh` creates the CI simulator and waits for Xcode to recognize it — not needed locally if you already have a simulator.

Sound assets: `scripts/generate-timer-sounds.py` regenerates the procedurally-generated PCM notification tones under `Ritli/Resources/Sounds` — no external audio assets are checked in.

## Architecture

**Composition root.** `RitliApp.swift` builds an `AppDependencies` (`AppDependencies.swift`) at launch via `AppDependencies.live(...)`. This wires a SwiftData `ModelContainer`, loads/seeds the singleton `PomodoroSettings` and `PomodoroCycleState` model rows, runs `DefaultFocusCategories.seedIfNeeded` and `TaskCompletionReconciliation.run`, and constructs the single `TimerEngine` with its concrete collaborators (notification scheduler, Live Activity coordinator, feedback/sound players). `TimerEngine` and `NotificationPermissionService` are injected into the view tree via `.environment(...)` — there is no other DI container. If `AppDependencies.live` throws, the app renders `StartupFailureView` instead of the normal UI. In `DEBUG`, `RitliApp.init` reads `--ui-testing*` launch arguments to run with an in-memory store and tweak settings (shortened durations, disabled notifications, forced sound) for deterministic UI tests.

**TimerEngine is the core state machine** (`Ritli/Timer/TimerEngine.swift`). It's an `@Observable @MainActor` class owning the single `currentSession: FocusSession?` and driving all session transitions (`startFocus`/`startShortBreak`/`startLongBreak`, `pause`/`resume`, `cancel`, `skipBreak`). Key properties of the design:
- Timing is computed from absolute dates (`session.endDate`, `dateProvider.now`), not a running `Timer` — `remainingTime(at:)` is pure and callers (e.g. `TimerRefreshLoop`, run by `ContentView` while active, or `restore()` on relaunch) just re-derive state from the current date. This is what lets the timer survive backgrounding/termination.
- `synchronizeCompletionIfNeeded()` is called at the top of nearly every mutating method so a session that finished while the app was suspended gets reconciled (state transition, cycle advance, sound) before any new action is allowed. Reconciliation is either live (sound + haptics) or catch-up (`restore()` and the first `refresh(catchingUp: true)` after returning — the notification already alerted, so nothing replays).
- Every state mutation follows the same shape: mutate `FocusSession`/`PomodoroCycleState`, `try saveChanges()` (which rolls the store back on failure), then notifications, `synchronizeLiveActivity()`, then `playFeedback(...)`. Nothing outside the store may change before the save succeeds. Preserve this order when adding new transitions; `TimerCallLog` in the test harness asserts it.
- Pomodoro cycle progression (focus → short break → ... → long break → reset) lives in `advanceCycle(after:)` / `resolveSkippedRecommendationIfNeeded`, driven by `PomodoroCycleState.nextSuggestedKind` and the active routine: a task's custom `TimerRoutine` is frozen into `PomodoroCycleState.routineSnapshot` when its focus starts (so editing it mid-cycle doesn't change that cycle); without one the cycle reads the live `PomodoroSettings`, so Settings edits apply to the next session. A running session's own duration is always fixed in `plannedDuration`/`endDate`.
- Auto-start: when a phase completes, the next one starts at the previous end date with the id `FocusSession.followUpID(after:)`. Its end alert is pre-scheduled under that id while the current phase runs, so it fires even if the app stays suspended. Catch-up records at most one auto-started phase that also ran out — later phases are never invented.
- All of `TimerEngine`'s collaborators are protocols (`TimerSessionStore`, `DateProviding`, `TimerNotificationScheduling`, `TimerLiveActivityCoordinating`, `TimerFeedbackPlaying`, `TimerCompletionSoundPlaying`), each with a `NoOp*`/fake implementation under `RitliTests/TestSupport` or inline — tests construct `TimerEngine` directly with fakes rather than mocking at a higher layer.

**Persistence** is SwiftData (`Ritli/Persistence/AppModelContainer.swift` defines the `Schema`: `FocusCategory`, `FocusTask`, `TimerRoutine`, `FocusSession`, `PomodoroSettings`, `PomodoroCycleState`). `PomodoroSettings` and `PomodoroCycleState` are singleton rows (fetch-or-insert on launch). `TimerSessionStore` wraps the `ModelContext` for the engine; `TaskCompletionReconciliation` fixes up task/pomodoro completion counts against persisted sessions on launch.

**Live Activity / Dynamic Island** flows through `RitliShared`: `TimerEngine` builds a `TimerLiveActivityDescriptor` (app-side) from the current session, and `ActivityKitTimerLiveActivityCoordinator` (`Ritli/Services/LiveActivities/`) maps that to `TimerLiveActivityAttributes`/`ContentState` (defined in `RitliShared`, consumed by both the app and the `RitliLiveActivity` extension target). The coordinator serializes all `Activity` start/update/end calls through a single chained `Task` (`enqueue`) to avoid ActivityKit race conditions, and self-schedules activity expiration via `scheduleExpiration`/`TimerLiveActivityPresentation.expirationDate`. Any change to the Live Activity's visual content or lifecycle generally touches three places: the descriptor/attributes (shared), the coordinator (app), and `RitliTimerLiveActivityView` (extension).

**Notifications**: `LocalTimerNotificationScheduler` + `NotificationPermissionService` (`Ritli/Services/Notifications/`) schedule/cancel the pending "session end" local notification keyed by session `UUID` (plus the follow-up phase's alert when auto-start applies), gated on `PomodoroSettings.notificationsEnabled`. `TimerNotificationPreference` is the one place that asks for permission before a timer starts and turns notifications off when permission is declined or revoked. `AppNotificationDelegate` is the `UIApplicationDelegateAdaptor` handling foreground notification presentation.

**Feature modules** under `Ritli/Features/` (`Home`, `Tasks`, `Stats`, `History`, `Settings`, `Onboarding`, `Startup`) are mostly presentation: SwiftUI views plus small pure "presentation"/"calculator" helper types (e.g. `FocusHistoryCalculator`, `StatsCalculator`, `TimerDisplayFormatter`) that are unit-tested independently of SwiftUI. `ContentView` is the tab-based shell and runs the app-level `TimerRefreshLoop` (driven by `scenePhase`), which calls `timerEngine.refresh(...)` once per second while the app is foregrounded and re-applies the Live Activity on its first pass.

**Localization**: `Ritli/Localizable.xcstrings` (and a separate one for `RitliLiveActivity`) are String Catalogs; supported languages are English and Ukrainian (see `StringCatalogIntegrityTests`). Prefer `Text(.someKey)` / `String(localized:)` over hardcoded strings; `AppLanguagePresentation`/`AppExternalLinks` handle linking out to system language settings.

**Local-only artifacts**: `local-artifacts/` (gitignored) holds release checklists, screenshots, and research notes — not part of the app or CI. Don't look there for app behavior and don't add tracked project documentation there.
