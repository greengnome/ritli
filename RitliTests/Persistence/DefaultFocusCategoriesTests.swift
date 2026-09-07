import SwiftData
import Testing
@testable import Ritli

@MainActor
struct DefaultFocusCategoriesTests {
    @Test("Default categories are seeded once in stable display order")
    func seedsDefaultsOnce() throws {
        let container = try AppModelContainer.make(inMemory: true)
        let context = container.mainContext

        try DefaultFocusCategories.seedIfNeeded(in: context)
        try DefaultFocusCategories.seedIfNeeded(in: context)

        let categories = try context.fetch(FetchDescriptor<FocusCategory>())
            .sorted { $0.sortOrder < $1.sortOrder }

        #expect(categories.map(\.name) == ["Work", "Personal", "Study"])
        #expect(categories.map(\.colorToken) == ["coral", "green", "blue"])
    }

    @Test("Existing user categories are never replaced by defaults")
    func preservesExistingCategories() throws {
        let container = try AppModelContainer.make(inMemory: true)
        let context = container.mainContext
        context.insert(FocusCategory(name: "Writing", colorToken: "purple"))
        try context.save()

        try DefaultFocusCategories.seedIfNeeded(in: context)

        let categories = try context.fetch(FetchDescriptor<FocusCategory>())
        #expect(categories.map(\.name) == ["Writing"])
    }
}
