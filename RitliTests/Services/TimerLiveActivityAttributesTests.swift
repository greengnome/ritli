import Foundation
import Testing
@testable import Ritli

struct TimerLiveActivityAttributesTests {
    // Fixed payloads rather than round-trips: a running activity keeps the
    // JSON it was started with, so renaming a case or key would break it
    // after an app update, while a round-trip would still pass.
    // Dates use JSONDecoder's default (seconds since 1 January 2001).
    @Test("Attributes decode from their established wire format")
    func decodesAttributes() throws {
        let json = """
        {"sessionID":"6F9619FF-8B86-D011-B42D-00C04FC964FF","kind":"shortBreak",\
        "startedAt":-978306200,"plannedDuration":1500}
        """

        let decoded = try JSONDecoder().decode(
            TimerLiveActivityAttributes.self,
            from: Data(json.utf8)
        )

        #expect(decoded == TimerLiveActivityAttributes(
            sessionID: try #require(UUID(uuidString: "6F9619FF-8B86-D011-B42D-00C04FC964FF")),
            kind: .shortBreak,
            startedAt: Date(timeIntervalSince1970: 1_000),
            plannedDuration: 1_500
        ))
    }

    @Test("Content state decodes from its established wire format", arguments: [
        (
            #"{"phase":{"running":{"endDate":-978305200}},"taskTitle":"Prepare release"}"#,
            TimerLiveActivityAttributes.ContentState(
                phase: .running(endDate: Date(timeIntervalSince1970: 2_000)),
                taskTitle: "Prepare release"
            )
        ),
        (
            #"{"phase":{"paused":{"remainingTime":625}}}"#,
            TimerLiveActivityAttributes.ContentState(
                phase: .paused(remainingTime: 625),
                taskTitle: nil
            )
        ),
    ])
    func decodesContentState(
        json: String,
        expected: TimerLiveActivityAttributes.ContentState
    ) throws {
        let decoded = try JSONDecoder().decode(
            TimerLiveActivityAttributes.ContentState.self,
            from: Data(json.utf8)
        )

        #expect(decoded == expected)
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
