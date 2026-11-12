import Foundation
import Testing
@testable import Ritli

@Suite("Localized focus category names")
struct FocusCategoryPresentationTests {
    @Test("Built-in names resolve in each supported language", arguments: [
        ("Work", "en", "Work"),
        ("Personal", "en", "Personal"),
        ("Study", "en", "Study"),
        ("Uncategorized", "en", "Uncategorized"),
        ("Work", "uk", "Робота"),
        ("Personal", "uk", "Особисте"),
        ("Study", "uk", "Навчання"),
        ("Uncategorized", "uk", "Без категорії"),
    ])
    func resolvesBuiltInName(
        storedName: String,
        language: String,
        expected: String
    ) throws {
        let localizedBundle = try TestLocalization.bundle(language: language)

        let value = FocusCategoryNamePresentation.displayName(
            for: storedName,
            bundle: localizedBundle,
            locale: Locale(identifier: language)
        )

        #expect(value == expected)
    }

    @Test("User-defined category names are never translated")
    func preservesUserDefinedName() throws {
        let localizedBundle = try TestLocalization.bundle(language: "uk")

        let value = FocusCategoryNamePresentation.displayName(
            for: "Writing",
            bundle: localizedBundle,
            locale: Locale(identifier: "uk")
        )

        #expect(value == "Writing")
    }
}
