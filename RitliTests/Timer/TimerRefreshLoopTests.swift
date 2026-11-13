import Foundation
import Testing
@testable import Ritli

@MainActor
struct TimerRefreshLoopTests {
    /// Runs the loop for `passes` iterations, calling `between` before each
    /// sleep returns, then stops it as a cancelled task would.
    private func run(
        _ engine: TimerEngine,
        passes: Int,
        between: @escaping @MainActor (Int) -> Void = { _ in },
        onError: @escaping @MainActor (Error) -> Void = { _ in }
    ) async {
        var pass = 0
        let loop = TimerRefreshLoop(interval: .seconds(1)) { _ in
            pass += 1
            guard pass < passes else { throw CancellationError() }
            between(pass)
        }
        await loop.run(engine: engine, onError: onError)
    }

    @Test("The first pass after activation catches up silently; later passes alert live")
    func firstPassDoesNotReplayTheSound() async throws {
        let harness = TimerEngineHarness(settings: PomodoroSettings(focusDuration: 60))
        let expired = try harness.engine.startFocus()
        harness.clock.advance(by: 600)
        var live: FocusSession?

        await run(harness.engine, passes: 2, between: { _ in
            live = try? harness.engine.startFocus()
            harness.clock.advance(by: 60)
        })

        let liveSession = try #require(live)
        #expect(expired.state == .completed)
        #expect(liveSession.state == .completed)
        #expect(harness.completionSound.playbacks.map(\.id) == [liveSession.id])
    }

    @Test("The first pass re-applies the Live Activity")
    func firstPassResynchronizesLiveActivity() async throws {
        let harness = TimerEngineHarness()
        let session = try harness.engine.startFocus()
        let eventsBefore = harness.liveActivities.events.count

        await run(harness.engine, passes: 3)

        #expect(harness.liveActivities.events.count == eventsBefore + 1)
        #expect(harness.liveActivities.lastDescriptor?.attributes.sessionID == session.id)
    }

    @Test("A failure is reported once per streak, not every second")
    func reportsFailureOncePerStreak() async throws {
        let harness = try SwiftDataTimerHarness(settings: PomodoroSettings(focusDuration: 60))
        let session = try harness.engine.startFocus()
        harness.clock.advance(by: 60)
        harness.store.failingSaves = 3
        var reported = 0

        await run(harness.engine, passes: 5, onError: { _ in reported += 1 })

        #expect(reported == 1)
        #expect(session.state == .completed)
    }
}
