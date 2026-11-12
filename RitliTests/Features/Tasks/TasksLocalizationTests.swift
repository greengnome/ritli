import Foundation
import Testing
@testable import Ritli

/// Covers composition of formatted and plural task copy. Whether each key is
/// translated at all is checked once for the whole catalog by
/// `StringCatalogIntegrityTests`.
@Suite("Tasks localization")
struct TasksLocalizationTests {
    @Test("Dynamic task actions preserve the task title", arguments: [
        ("tasks.row.complete.accessibility", "Mark План проєкту complete", "Позначити виконаним: План проєкту"),
        ("tasks.row.edit.accessibility", "Edit План проєкту", "Редагувати: План проєкту"),
        ("tasks.row.reopen.accessibility", "Reopen План проєкту", "Відкрити знову: План проєкту"),
        ("tasks.row.start_focus.accessibility", "Start focus on План проєкту", "Почати фокус: План проєкту"),
    ])
    func resolvesDynamicAction(
        key: String,
        english: String,
        ukrainian: String
    ) throws {
        #expect(try formattedValue(key, language: "en") == english)
        #expect(try formattedValue(key, language: "uk") == ukrainian)
    }

    @Test("Focus estimate composes with localized session plurals", arguments: [
        ("en", 1, "Focus estimate: 1 session"),
        ("en", 3, "Focus estimate: 3 sessions"),
        ("uk", 1, "Оцінка фокусу: 1 сесія"),
        ("uk", 3, "Оцінка фокусу: 3 сесії"),
        ("uk", 5, "Оцінка фокусу: 5 сесій"),
    ])
    func resolvesFocusEstimate(
        language: String,
        count: Int,
        expected: String
    ) throws {
        let bundle = try TestLocalization.bundle(language: language)
        let sessionCount = TimerDisplayFormatter.sessionCount(
            count,
            bundle: bundle,
            locale: Locale(identifier: language)
        )
        let template = localizedValue(
            "tasks.editor.focus_estimate",
            bundle: bundle
        )

        #expect(String(format: template, sessionCount) == expected)
    }

    private func localizedValue(_ key: String, bundle: Bundle) -> String {
        bundle.localizedString(forKey: key, value: nil, table: "Localizable")
    }

    private func formattedValue(_ key: String, language: String) throws -> String {
        String(
            format: localizedValue(key, bundle: try TestLocalization.bundle(language: language)),
            locale: Locale(identifier: language),
            "План проєкту"
        )
    }
}
