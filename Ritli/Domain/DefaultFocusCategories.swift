import SwiftData

struct DefaultFocusCategoryDefinition: Equatable, Sendable {
    let name: String
    let colorToken: String
    let iconName: String
}

enum DefaultFocusCategories {
    static let definitions = [
        DefaultFocusCategoryDefinition(
            name: "Work",
            colorToken: "coral",
            iconName: "briefcase.fill"
        ),
        DefaultFocusCategoryDefinition(
            name: "Personal",
            colorToken: "green",
            iconName: "person.fill"
        ),
        DefaultFocusCategoryDefinition(
            name: "Study",
            colorToken: "blue",
            iconName: "book.fill"
        )
    ]

    @MainActor
    static func seedIfNeeded(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<FocusCategory>()
        guard try context.fetchCount(descriptor) == 0 else { return }

        for (index, definition) in definitions.enumerated() {
            context.insert(
                FocusCategory(
                    name: definition.name,
                    colorToken: definition.colorToken,
                    iconName: definition.iconName,
                    sortOrder: index
                )
            )
        }
        try context.save()
    }
}
