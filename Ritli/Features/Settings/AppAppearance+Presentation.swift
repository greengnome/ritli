import SwiftUI

extension AppAppearance {
    func title(
        bundle: Bundle = .main,
        locale: Locale = .current
    ) -> String {
        switch self {
        case .system:
            String(
                localized: "settings.appearance.system",
                defaultValue: "System",
                bundle: bundle,
                locale: locale
            )
        case .light:
            String(
                localized: "settings.appearance.light",
                defaultValue: "Light",
                bundle: bundle,
                locale: locale
            )
        case .dark:
            String(
                localized: "settings.appearance.dark",
                defaultValue: "Dark",
                bundle: bundle,
                locale: locale
            )
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}
