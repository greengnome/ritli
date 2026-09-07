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
