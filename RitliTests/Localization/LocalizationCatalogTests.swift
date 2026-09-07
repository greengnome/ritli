import Foundation
import Testing
@testable import Ritli

@Suite("Localization catalog")
struct LocalizationCatalogTests {
    @Test("The app bundle includes every supported language")
    func includesSupportedLanguages() {
        let localizations = Set(Bundle.main.localizations)

        #expect(localizations.contains("en"))
        #expect(localizations.contains("uk"))
    }

    @Test("Shared copy resolves in English and Ukrainian", arguments: [
        ("en", "OK"),
        ("uk", "Гаразд"),
    ])
    func resolvesSharedCopy(language: String, expected: String) throws {
        let resourcePath = try #require(
            Bundle.main.path(forResource: language, ofType: "lproj")
        )
        let localizedBundle = try #require(Bundle(path: resourcePath))
        let value = String(
            localized: "common.action.ok",
            defaultValue: "OK",
            bundle: localizedBundle,
            locale: Locale(identifier: language)
        )

        #expect(value == expected)
    }

    @Test("Unsupported languages fall back to English")
    func fallsBackToDevelopmentLanguage() {
        let value = String(
            localized: "common.action.ok",
            defaultValue: "OK",
            bundle: .main,
            locale: Locale(identifier: "fr")
        )

        #expect(value == "OK")
    }
}
