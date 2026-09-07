import Foundation
import Testing

@Suite("Live Activity localization")
struct TimerLiveActivityLocalizationTests {
    @Test("Live Activity copy resolves in English and Ukrainian", arguments: [
        ("live_activity.focus", "Focus", "Фокус"),
        ("live_activity.short_break", "Short Break", "Коротка перерва"),
        ("live_activity.long_break", "Long Break", "Довга перерва"),
        ("live_activity.paused", "Paused", "Призупинено"),
        ("live_activity.stay_focused", "Stay focused", "Зберігайте фокус"),
    ])
    func resolvesCopy(key: String, english: String, ukrainian: String) throws {
        let extensionBundle = try liveActivityBundle()
        let englishBundle = try localizedBundle(
            language: "en",
            in: extensionBundle
        )
        let ukrainianBundle = try localizedBundle(
            language: "uk",
            in: extensionBundle
        )

        #expect(localizedValue(key, bundle: englishBundle) == english)
        #expect(localizedValue(key, bundle: ukrainianBundle) == ukrainian)
    }

    private func localizedValue(_ key: String, bundle: Bundle) -> String {
        bundle.localizedString(forKey: key, value: nil, table: "Localizable")
    }

    private func liveActivityBundle() throws -> Bundle {
        let plugInsURL = try #require(Bundle.main.builtInPlugInsURL)
        let bundleURL = plugInsURL.appendingPathComponent(
            "RitliLiveActivity.appex"
        )
        return try #require(Bundle(url: bundleURL))
    }

    private func localizedBundle(
        language: String,
        in bundle: Bundle
    ) throws -> Bundle {
        let resourcePath = try #require(
            bundle.path(forResource: language, ofType: "lproj")
        )
        return try #require(Bundle(path: resourcePath))
    }
}
