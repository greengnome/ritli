import Foundation
import Testing
@testable import Ritli

struct SettingsPresentationTests {
    @Test("Dynamic Settings values follow English and Ukrainian grammar")
    func localizesDynamicValues() throws {
        let englishBundle = try localizedBundle(language: "en")
        let ukrainianBundle = try localizedBundle(language: "uk")

        #expect(
            SettingsPresentation.minutes(
                25,
                bundle: englishBundle,
                locale: Locale(identifier: "en")
            ) == "25 min"
        )
        #expect(
            SettingsPresentation.minutes(
                25,
                bundle: ukrainianBundle,
                locale: Locale(identifier: "uk")
            ) == "25 хв"
        )
        #expect(
            SettingsPresentation.longBreakInterval(
                4,
                bundle: englishBundle,
                locale: Locale(identifier: "en")
            ) == "Every 4 focus sessions"
        )
        #expect(
            SettingsPresentation.longBreakInterval(
                4,
                bundle: ukrainianBundle,
                locale: Locale(identifier: "uk")
            ) == "Після кожних 4 сесій фокусу"
        )
    }

    @Test("Appearance and toggle values resolve in Ukrainian")
    func localizesChoices() throws {
        let bundle = try localizedBundle(language: "uk")
        let locale = Locale(identifier: "uk")

        #expect(AppAppearance.system.title(bundle: bundle, locale: locale) == "Системна")
        #expect(AppAppearance.light.title(bundle: bundle, locale: locale) == "Світла")
        #expect(AppAppearance.dark.title(bundle: bundle, locale: locale) == "Темна")
        #expect(
            SettingsPresentation.toggleState(
                isOn: true,
                bundle: bundle,
                locale: locale
            ) == "Увімкнено"
        )
        #expect(
            SettingsPresentation.toggleState(
                isOn: false,
                bundle: bundle,
                locale: locale
            ) == "Вимкнено"
        )
    }

    private func localizedBundle(language: String) throws -> Bundle {
        let resourcePath = try #require(
            Bundle.main.path(forResource: language, ofType: "lproj")
        )
        return try #require(Bundle(path: resourcePath))
    }
}
