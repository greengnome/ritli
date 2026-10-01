import Foundation

extension SessionKind {
    var title: LocalizedStringResource {
        switch self {
        case .focus:
            .homeTimerModeFocus
        case .shortBreak:
            .homeTimerModeShortBreak
        case .longBreak:
            .homeTimerModeLongBreak
        }
    }

    var timerSubtitle: LocalizedStringResource {
        switch self {
        case .focus:
            .homeTimerSubtitleFocus
        case .shortBreak, .longBreak:
            .homeTimerSubtitleBreak
        }
    }

    func timerSubtitle(state: SessionState?, remainingTime: TimeInterval) -> LocalizedStringResource {
        switch state {
        case .running where remainingTime <= 0, .completed:
            LocalizedStringResource("home.timer.status.complete", defaultValue: "Complete")
        case .running:
            LocalizedStringResource("home.timer.status.remaining", defaultValue: "Remaining")
        case .paused:
            LocalizedStringResource("home.timer.status.paused", defaultValue: "Paused")
        case .cancelled, .skipped, .none:
            timerSubtitle
        }
    }

    var timerAccessibilityLabel: LocalizedStringResource {
        switch self {
        case .focus:
            .homeTimerAccessibilityFocus
        case .shortBreak:
            .homeTimerAccessibilityShortBreak
        case .longBreak:
            .homeTimerAccessibilityLongBreak
        }
    }
}
