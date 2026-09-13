import Foundation
import Testing
@testable import Ritli

struct TimerLiveActivityPresentationTests {
    @Test("Running content finishes at its deadline without an app update", arguments: [
        (TimeInterval(999), false),
        (TimeInterval(1_000), true),
        (TimeInterval(1_060), true),
    ])
    func finishesAtDeadline(timestamp: TimeInterval, expected: Bool) {
        let state = TimerLiveActivityAttributes.ContentState(
            phase: .running(endDate: Date(timeIntervalSince1970: 1_000)),
            taskTitle: "Prepare release"
        )

        #expect(
            TimerLiveActivityPresentation.isFinished(
                state: state,
                isStale: false,
                at: Date(timeIntervalSince1970: timestamp)
            ) == expected
        )
    }

    @Test("The system expiry signal finishes a suspended app's Live Activity")
    func finishesStaleContent() {
        let state = TimerLiveActivityAttributes.ContentState(
            phase: .running(endDate: Date(timeIntervalSince1970: 1_000)),
            taskTitle: nil
        )

        #expect(
            TimerLiveActivityPresentation.isFinished(
                state: state,
                isStale: true,
                at: Date(timeIntervalSince1970: 999)
            )
        )
    }

    @Test("Paused content never appears finished, including zero remaining time", arguments: [
        TimeInterval(0), TimeInterval(100),
    ])
    func pausedContentDoesNotFinish(remainingTime: TimeInterval) {
        let state = TimerLiveActivityAttributes.ContentState(
            phase: .paused(remainingTime: remainingTime),
            taskTitle: nil
        )

        #expect(
            !TimerLiveActivityPresentation.isFinished(
                state: state,
                isStale: true,
                at: .distantFuture
            )
        )
    }

    @Test("Resuming uses the new deadline rather than the original session end")
    func resumedContentUsesUpdatedDeadline() {
        let state = TimerLiveActivityAttributes.ContentState(
            phase: .running(endDate: Date(timeIntervalSince1970: 2_000)),
            taskTitle: nil
        )

        #expect(
            !TimerLiveActivityPresentation.isFinished(
                state: state,
                isStale: false,
                at: Date(timeIntervalSince1970: 1_500)
            )
        )
        #expect(TimerLiveActivityPresentation.expirationDate(for: state)
            == Date(timeIntervalSince1970: 2_000))
    }

    @Test(
        "Lock Screen text keeps accessible contrast in every appearance",
        arguments: TimerLiveActivityTheme.allCases
    )
    func lockScreenContrast(theme: TimerLiveActivityTheme) {
        #expect(
            theme.primaryText.contrastRatio(with: theme.background) >= 4.5
        )
        #expect(
            theme.secondaryText.contrastRatio(with: theme.background) >= 4.5
        )
    }

    @Test("Paused countdown rounds up and clamps invalid values", arguments: [
        (TimeInterval(625), "10:25"),
        (TimeInterval(59.1), "01:00"),
        (TimeInterval(-1), "00:00"),
    ])
    func pausedCountdown(interval: TimeInterval, expected: String) {
        #expect(TimerLiveActivityPresentation.pausedCountdown(interval) == expected)
    }

    @Test("Only a running Live Activity has an expiration date")
    func mapsExpirationDate() {
        let endDate = Date(timeIntervalSince1970: 10_000)
        let running = TimerLiveActivityAttributes.ContentState(
            phase: .running(endDate: endDate),
            taskTitle: nil
        )
        let paused = TimerLiveActivityAttributes.ContentState(
            phase: .paused(remainingTime: 100),
            taskTitle: nil
        )

        #expect(
            TimerLiveActivityPresentation.expirationDate(for: running)
                == endDate
        )
        #expect(
            TimerLiveActivityPresentation.expirationDate(for: paused) == nil
        )
    }

    @Test("Progress is normalized to the complete unit interval", arguments: [
        (TimeInterval(1_500), TimeInterval(1_500), 0.0),
        (TimeInterval(750), TimeInterval(1_500), 0.5),
        (TimeInterval(0), TimeInterval(1_500), 1.0),
        (TimeInterval(-10), TimeInterval(1_500), 1.0),
        (TimeInterval(100), TimeInterval(0), 0.0),
    ])
    func progress(
        remainingTime: TimeInterval,
        plannedDuration: TimeInterval,
        expected: Double
    ) {
        #expect(
            TimerLiveActivityPresentation.progress(
                remainingTime: remainingTime,
                plannedDuration: plannedDuration
            ) == expected
        )
    }
}
