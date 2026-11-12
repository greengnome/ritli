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

    /// `StringCatalogIntegrityTests` checks the source catalogs; this smoke
    /// test checks that the compiled `.lproj` tables actually ship them.
    @Test("Shared copy resolves from each compiled language table", arguments: [
        ("en", "OK"),
        ("uk", "Гаразд"),
    ])
    func resolvesSharedCopy(language: String, expected: String) throws {
        let bundle = try TestLocalization.bundle(language: language)

        #expect(
            bundle.localizedString(forKey: "common.action.ok", value: nil, table: nil)
                == expected
        )
    }

    @Test("Unsupported languages fall back to English")
    func fallsBackToDevelopmentLanguage() throws {
        let resolved = Bundle.preferredLocalizations(
            from: Bundle.main.localizations,
            forPreferences: ["fr"]
        )

        #expect(resolved.first == "en")
        let fallback = try TestLocalization.bundle(language: try #require(resolved.first))
        #expect(
            fallback.localizedString(forKey: "common.action.ok", value: nil, table: nil)
                == "OK"
        )
    }
}
