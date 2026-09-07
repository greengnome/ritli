import Foundation
import Testing
@testable import Ritli

@Suite("Onboarding localization")
struct OnboardingLocalizationTests {
    @Test("Onboarding copy resolves in English and Ukrainian", arguments: [
        ("onboarding.action.continue", "Continue", "Продовжити"),
        ("onboarding.action.finish", "Let's focus", "Почати фокусування"),
        ("onboarding.focus.title", "Focus deeply", "Зосереджуйтеся глибше"),
        (
            "onboarding.focus.message",
            "Accurate focus and break timers keep going when Ritli is in the background.",
            "Точні таймери фокусу й перерв продовжують працювати, навіть коли Ritli у фоновому режимі."
        ),
        (
            "onboarding.tasks.title",
            "Turn plans into progress",
            "Перетворюйте плани на прогрес"
        ),
        (
            "onboarding.tasks.message",
            "Attach sessions to tasks, set Pomodoro estimates, and make every focus block count.",
            "Прив’язуйте сесії до завдань, оцінюйте їх у помодоро й перетворюйте кожен блок фокусу на результат."
        ),
        ("onboarding.tasks.project_roadmap", "Project roadmap", "План проєкту"),
        ("onboarding.tasks.read_pages", "Read 20 pages", "Прочитати 20 сторінок"),
        ("onboarding.tasks.done", "Done", "Готово"),
        ("onboarding.tasks.learn_spanish", "Learn Spanish", "Вивчати іспанську"),
        (
            "onboarding.insights.title",
            "Understand your momentum",
            "Відстежуйте свій прогрес"
        ),
        (
            "onboarding.insights.message",
            "Review focus time, completed sessions, categories, and your day-by-day history.",
            "Переглядайте час фокусування, завершені сесії, категорії та історію за днями."
        ),
        ("onboarding.insights.focus.value", "2h 15m", "2 год 15 хв"),
        ("onboarding.insights.focus.label", "Focus", "Фокус"),
        ("onboarding.insights.sessions.label", "Sessions", "Сесії"),
        ("onboarding.page.selected", "Selected", "Вибрано"),
        ("onboarding.page.not_selected", "Not selected", "Не вибрано"),
        (
            "onboarding.accessibility.page",
            "Onboarding page %lld",
            "Сторінка знайомства %lld"
        ),
    ])
    func resolvesCopy(key: String, english: String, ukrainian: String) throws {
        let englishBundle = try localizedBundle(language: "en")
        let ukrainianBundle = try localizedBundle(language: "uk")

        #expect(
            englishBundle.localizedString(
                forKey: key,
                value: nil,
                table: "Localizable"
            ) == english
        )
        #expect(
            ukrainianBundle.localizedString(
                forKey: key,
                value: nil,
                table: "Localizable"
            ) == ukrainian
        )
    }

    private func localizedBundle(language: String) throws -> Bundle {
        let resourcePath = try #require(
            Bundle.main.path(forResource: language, ofType: "lproj")
        )
        return try #require(Bundle(path: resourcePath))
    }
}
