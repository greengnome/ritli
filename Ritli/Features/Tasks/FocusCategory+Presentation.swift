import SwiftUI

enum FocusCategoryNamePresentation {
    static func displayName(
        for storedName: String,
        bundle: Bundle = .main,
        locale: Locale = .current
    ) -> String {
        switch storedName {
        case "Work":
            String(
                localized: "category.default.work",
                defaultValue: "Work",
                bundle: bundle,
                locale: locale
            )
        case "Personal":
            String(
                localized: "category.default.personal",
                defaultValue: "Personal",
                bundle: bundle,
                locale: locale
            )
        case "Study":
            String(
                localized: "category.default.study",
                defaultValue: "Study",
                bundle: bundle,
                locale: locale
            )
        case "Uncategorized":
            String(
                localized: "common.category.uncategorized",
                defaultValue: "Uncategorized",
                bundle: bundle,
                locale: locale
            )
        default:
            storedName
        }
    }
}

extension FocusCategory {
    var displayName: String {
        FocusCategoryNamePresentation.displayName(for: name)
    }

    var presentationColor: Color {
        RitliTheme.categoryColor(for: colorToken)
    }
}
