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

extension FocusTask {
    /// The task's note without surrounding whitespace, or nil when it has none.
    var trimmedNote: String? {
        guard let notes else { return nil }
        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var hasNote: Bool {
        trimmedNote != nil
    }
}
