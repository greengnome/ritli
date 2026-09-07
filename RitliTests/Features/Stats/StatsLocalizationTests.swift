import Foundation
import Testing
@testable import Ritli

@Suite("Stats localization")
struct StatsLocalizationTests {
    @Test("Stats copy resolves in English and Ukrainian", arguments: [
        ("stats.action.focus_history", "Focus history", "Історія фокусу"),
        ("stats.categories.chart.accessibility", "Focus time by category", "Час фокусу за категоріями"),
        ("stats.categories.empty.description", "Completed and cancelled focus sessions appear here.", "Тут з’являться завершені й скасовані сесії фокусу."),
        ("stats.categories.empty.title", "No focus time yet", "Часу фокусу поки немає"),
        ("stats.categories.title", "Top categories", "Найпопулярніші категорії"),
        ("stats.chart.axis.period", "Period", "Період"),
        ("stats.chart.focus_time.accessibility", "Focus time chart", "Графік часу фокусу"),
        ("stats.chart.sessions.accessibility", "Completed sessions chart", "Графік завершених сесій"),
        ("stats.comparison.no_previous_data", "No previous data", "Немає попередніх даних"),
        ("stats.empty.no_focus_recorded", "No focus recorded", "Час фокусу не записано"),
        ("stats.period.picker", "Period", "Період"),
    ])
    func resolvesCopy(key: String, english: String, ukrainian: String) throws {
        let englishBundle = try localizedBundle(language: "en")
        let ukrainianBundle = try localizedBundle(language: "uk")

        #expect(localizedValue(key, bundle: englishBundle) == english)
        #expect(localizedValue(key, bundle: ukrainianBundle) == ukrainian)
    }

    private func localizedValue(_ key: String, bundle: Bundle) -> String {
        bundle.localizedString(forKey: key, value: nil, table: "Localizable")
    }

    private func localizedBundle(language: String) throws -> Bundle {
        let resourcePath = try #require(
            Bundle.main.path(forResource: language, ofType: "lproj")
        )
        return try #require(Bundle(path: resourcePath))
    }
}
