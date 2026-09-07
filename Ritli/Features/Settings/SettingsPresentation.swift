import Foundation

enum SettingsPresentation {
    static func minutes(
        _ minutes: Int,
        bundle: Bundle = .main,
        locale: Locale = .current
    ) -> String {
        String(
            localized: "settings.duration.minutes",
            defaultValue: "\(minutes) min",
            bundle: bundle,
            locale: locale
        )
    }

    static func longBreakInterval(
        _ count: Int,
        bundle: Bundle = .main,
        locale: Locale = .current
    ) -> String {
        String(
            localized: "settings.cycle.every_focus_sessions",
            defaultValue: "Every \(count) focus sessions",
            bundle: bundle,
            locale: locale
        )
    }

    static func toggleState(
        isOn: Bool,
        bundle: Bundle = .main,
        locale: Locale = .current
    ) -> String {
        if isOn {
            return String(
                localized: "common.state.on",
                defaultValue: "On",
                bundle: bundle,
                locale: locale
            )
        }
        return String(
            localized: "common.state.off",
            defaultValue: "Off",
            bundle: bundle,
            locale: locale
        )
    }
}
