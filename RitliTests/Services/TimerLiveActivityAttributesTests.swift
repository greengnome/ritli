import Foundation
import Testing
@testable import Ritli

struct TimerLiveActivityAttributesTests {
    @Test("Attributes survive the ActivityKit encoding boundary")
    func attributesCodableRoundTrip() throws {
        let attributes = TimerLiveActivityAttributes(
            sessionID: UUID(),
            kind: .focus,
            startedAt: Date(timeIntervalSince1970: 1_000),
            plannedDuration: 1_500
        )

        let encoded = try JSONEncoder().encode(attributes)
        let decoded = try JSONDecoder().decode(
            TimerLiveActivityAttributes.self,
            from: encoded
        )

        #expect(decoded == attributes)
    }

    @Test("Content state survives the ActivityKit encoding boundary", arguments: [
        TimerLiveActivityAttributes.ContentState(
            phase: .running(endDate: Date(timeIntervalSince1970: 2_000)),
            taskTitle: "Prepare release"
        ),
        TimerLiveActivityAttributes.ContentState(
            phase: .paused(remainingTime: 625),
            taskTitle: nil
        ),
    ])
    func contentStateCodableRoundTrip(
        contentState: TimerLiveActivityAttributes.ContentState
    ) throws {
        let encoded = try JSONEncoder().encode(contentState)
        let decoded = try JSONDecoder().decode(
            TimerLiveActivityAttributes.ContentState.self,
            from: encoded
        )

        #expect(decoded == contentState)
    }

    @Test("Running content counts down and clamps at zero")
    func runningRemainingTime() {
        let state = TimerLiveActivityAttributes.ContentState(
            phase: .running(endDate: Date(timeIntervalSince1970: 1_100)),
            taskTitle: nil
        )

        #expect(!state.isPaused)
        #expect(state.remainingTime(at: Date(timeIntervalSince1970: 1_000)) == 100)
        #expect(state.remainingTime(at: Date(timeIntervalSince1970: 1_200)) == 0)
    }

    @Test("Paused content freezes and normalizes remaining time")
    func pausedRemainingTime() {
        let paused = TimerLiveActivityAttributes.ContentState(
            phase: .paused(remainingTime: 300),
            taskTitle: nil
        )
        let invalid = TimerLiveActivityAttributes.ContentState(
            phase: .paused(remainingTime: -1),
            taskTitle: nil
        )

        #expect(paused.isPaused)
        #expect(paused.remainingTime(at: .distantFuture) == 300)
        #expect(invalid.remainingTime(at: .now) == 0)
    }
}
