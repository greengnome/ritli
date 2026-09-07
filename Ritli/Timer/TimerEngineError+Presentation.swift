import Foundation

extension TimerEngineError: LocalizedError {
    var errorDescription: String? {
        message()
    }

    func message(
        bundle: Bundle = .main,
        locale: Locale = .current
    ) -> String {
        switch self {
        case .activeSessionExists:
            String(
                localized: "timer.error.active_session_exists",
                defaultValue: "A timer is already running.",
                bundle: bundle,
                locale: locale
            )
        case .noActiveSession:
            String(
                localized: "timer.error.no_active_session",
                defaultValue: "There is no active timer.",
                bundle: bundle,
                locale: locale
            )
        case .invalidTransition:
            String(
                localized: "timer.error.invalid_transition",
                defaultValue: "This timer action is not available right now.",
                bundle: bundle,
                locale: locale
            )
        case .focusSessionCannotBeSkipped:
            String(
                localized: "timer.error.focus_cannot_be_skipped",
                defaultValue: "Focus sessions cannot be skipped.",
                bundle: bundle,
                locale: locale
            )
        }
    }
}
