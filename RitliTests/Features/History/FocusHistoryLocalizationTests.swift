import Foundation
import Testing
@testable import Ritli

@Suite("Focus History localization")
struct FocusHistoryLocalizationTests {
    @Test("History copy resolves in English and Ukrainian", arguments: [
        ("history.date_picker.label", "History date", "Дата історії"),
        ("history.empty.description", "Choose another date or complete a focus session.", "Виберіть іншу дату або завершіть сесію фокусу."),
        ("history.empty.title", "No focus sessions", "Немає сесій фокусу"),
        ("history.row.cancelled", "Cancelled", "Скасовано"),
        ("history.row.completed", "Completed", "Завершено"),
        ("history.row.unassigned", "Unassigned focus", "Фокус без завдання"),
        ("history.summary.focused", "Focused", "У фокусі"),
        ("history.title", "Focus History", "Історія фокусу"),
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
