import Foundation
import Testing
@testable import Ritli

@Suite("Settings localization")
struct SettingsLocalizationTests {
    @Test("Settings copy resolves in English and Ukrainian", arguments: [
        ("settings.about.section", "About", "Про застосунок"),
        ("settings.about.privacy_policy", "Privacy Policy", "Політика конфіденційності"),
        ("settings.about.support", "Support", "Підтримка"),
        ("settings.about.version", "Version", "Версія"),
        ("settings.alert.unavailable", "Settings unavailable", "Налаштування недоступні"),
        ("settings.appearance.section", "Appearance", "Вигляд"),
        ("settings.appearance.theme", "Theme", "Тема"),
        ("settings.cycle.auto_start_breaks", "Auto-start breaks", "Автозапуск перерв"),
        ("settings.cycle.auto_start_focus", "Auto-start focus", "Автозапуск фокусу"),
        ("settings.cycle.section", "Cycle", "Цикл"),
        ("settings.data.clear", "Clear focus history", "Очистити історію фокусу"),
        (
            "settings.data.footer",
            "An active or paused timer is never removed.",
            "Активний або призупинений таймер ніколи не видаляється."
        ),
        ("settings.data.recorded_sessions", "Recorded sessions", "Записані сесії"),
        ("settings.data.section", "Data", "Дані"),
        ("settings.feedback.haptics", "Haptics", "Вібровідгук"),
        ("settings.feedback.notifications", "Notifications", "Сповіщення"),
        ("settings.feedback.section", "Feedback", "Відгук"),
        ("settings.feedback.sounds", "Notification sounds", "Звуки сповіщень"),
        ("settings.language.app_language", "App language", "Мова застосунку"),
        (
            "settings.language.footer",
            "Choose a language in iOS Settings.",
            "Виберіть мову в налаштуваннях iOS."
        ),
        ("settings.language.section", "Language", "Мова"),
        (
            "settings.privacy.show_task_titles",
            "Show task names on Lock Screen",
            "Показувати назви завдань на екрані блокування"
        ),
        ("settings.privacy.section", "Privacy", "Конфіденційність"),
        ("settings.timer.focus", "Focus", "Фокус"),
        ("settings.timer.long_break", "Long break", "Довга перерва"),
        ("settings.timer.section", "Timer", "Таймер"),
        ("settings.timer.short_break", "Short break", "Коротка перерва"),
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
