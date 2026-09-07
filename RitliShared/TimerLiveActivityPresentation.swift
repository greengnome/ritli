import Foundation

nonisolated struct TimerLiveActivityColorComponents: Equatable, Sendable {
    let red: Double
    let green: Double
    let blue: Double

    func contrastRatio(
        with other: TimerLiveActivityColorComponents
    ) -> Double {
        let lighter = max(relativeLuminance, other.relativeLuminance)
        let darker = min(relativeLuminance, other.relativeLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private var relativeLuminance: Double {
        0.2126 * linearized(red)
            + 0.7152 * linearized(green)
            + 0.0722 * linearized(blue)
    }

    private func linearized(_ component: Double) -> Double {
        if component <= 0.04045 {
            return component / 12.92
        }
        return pow((component + 0.055) / 1.055, 2.4)
    }
}

nonisolated enum TimerLiveActivityTheme: CaseIterable, Sendable {
    case light
    case dark

    var background: TimerLiveActivityColorComponents {
        switch self {
        case .light:
            TimerLiveActivityColorComponents(
                red: 0.965,
                green: 0.955,
                blue: 0.94
            )
        case .dark:
            TimerLiveActivityColorComponents(
                red: 0.075,
                green: 0.078,
                blue: 0.09
            )
        }
    }

    var primaryText: TimerLiveActivityColorComponents {
        switch self {
        case .light:
            TimerLiveActivityColorComponents(
                red: 0.08,
                green: 0.075,
                blue: 0.07
            )
        case .dark:
            TimerLiveActivityColorComponents(
                red: 0.96,
                green: 0.96,
                blue: 0.97
            )
        }
    }

    var secondaryText: TimerLiveActivityColorComponents {
        switch self {
        case .light:
            TimerLiveActivityColorComponents(
                red: 0.32,
                green: 0.30,
                blue: 0.28
            )
        case .dark:
            TimerLiveActivityColorComponents(
                red: 0.72,
                green: 0.72,
                blue: 0.75
            )
        }
    }
}

nonisolated enum TimerLiveActivityPresentation {
    static func pausedCountdown(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(ceil(max(0, interval)))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    static func progress(
        remainingTime: TimeInterval,
        plannedDuration: TimeInterval
    ) -> Double {
        guard plannedDuration > 0 else { return 0 }
        let elapsedTime = plannedDuration - max(0, remainingTime)
        return min(1, max(0, elapsedTime / plannedDuration))
    }

    static func expirationDate(
        for state: TimerLiveActivityAttributes.ContentState
    ) -> Date? {
        switch state.phase {
        case let .running(endDate):
            endDate
        case .paused:
            nil
        }
    }
}
