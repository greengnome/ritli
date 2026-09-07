import Foundation

enum FocusHistoryEntryPresentation {
    static func taskTitle(
        for entry: FocusHistoryEntry,
        bundle: Bundle = .main,
        locale: Locale = .current
    ) -> String {
        entry.taskTitle ?? String(
            localized: "history.row.unassigned",
            defaultValue: "Unassigned focus",
            bundle: bundle,
            locale: locale
        )
    }

    static func detail(
        for entry: FocusHistoryEntry,
        bundle: Bundle = .main,
        locale: Locale = .current
    ) -> String {
        let outcome = outcome(
            isCompleted: entry.isCompleted,
            bundle: bundle,
            locale: locale
        )
        guard let categoryName = entry.categoryName else { return outcome }
        let displayedCategoryName = FocusCategoryNamePresentation.displayName(
            for: categoryName,
            bundle: bundle,
            locale: locale
        )

        return String(
            localized: "history.row.detail_with_category",
            defaultValue: "\(outcome) · \(displayedCategoryName)",
            bundle: bundle,
            locale: locale
        )
    }

    static func accessibilityLabel(
        for entry: FocusHistoryEntry,
        bundle: Bundle = .main,
        locale: Locale = .current
    ) -> String {
        let title = taskTitle(for: entry, bundle: bundle, locale: locale)
        let detail = detail(for: entry, bundle: bundle, locale: locale)
        let duration = TimerDisplayFormatter.focusedTime(
            entry.focusTime,
            bundle: bundle,
            locale: locale
        )

        return String(
            localized: "history.row.accessibility",
            defaultValue: "\(title), \(detail), \(duration)",
            bundle: bundle,
            locale: locale
        )
    }

    private static func outcome(
        isCompleted: Bool,
        bundle: Bundle,
        locale: Locale
    ) -> String {
        if isCompleted {
            return String(
                localized: "history.row.completed",
                defaultValue: "Completed",
                bundle: bundle,
                locale: locale
            )
        }
        return String(
            localized: "history.row.cancelled",
            defaultValue: "Cancelled",
            bundle: bundle,
            locale: locale
        )
    }
}
