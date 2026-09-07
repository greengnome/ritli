import Foundation
import Testing
@testable import Ritli

@Suite("Home localization")
struct HomeLocalizationTests {
    @Test("Home copy resolves in English and Ukrainian", arguments: [
        ("app.tab.home", "Home", "Головна"),
        ("app.tab.stats", "Stats", "Статистика"),
        ("app.tab.tasks", "Tasks", "Завдання"),
        ("app.tab.settings", "Settings", "Налаштування"),
        ("common.action.cancel", "Cancel", "Скасувати"),
        ("common.category.none", "No category", "Без категорії"),
        ("common.error.try_again", "Please try again.", "Спробуйте ще раз."),
        ("home.alert.timer_unavailable", "Timer unavailable", "Таймер недоступний"),
        ("home.summary.today", "Today", "Сьогодні"),
        ("home.summary.view_all", "View all", "Переглянути все"),
        ("home.summary.sessions", "Sessions", "Сесії"),
        ("home.summary.focus_time", "Focus time", "Час фокусу"),
        ("home.summary.tasks_done", "Tasks done", "Виконано"),
        ("home.task.working_on", "Working on", "У роботі"),
        (
            "home.task.choose_optional",
            "Choose a task (optional)",
            "Завдання (за бажанням)"
        ),
        ("home.task.choose", "Choose a task", "Вибрати завдання"),
        (
            "home.task_picker.hint",
            "Selects an optional task for the next focus session",
            "Вибирає необов’язкове завдання для наступної сесії фокусу"
        ),
        ("home.task_picker.no_task", "No task", "Без завдання"),
        (
            "home.task_picker.no_task.description",
            "Keep this focus session unassigned",
            "Не прив’язувати цю сесію фокусу до завдання"
        ),
        (
            "home.task_picker.select_no_task",
            "Select no task",
            "Вибрати варіант без завдання"
        ),
        ("home.task_picker.empty.title", "No active tasks", "Немає активних завдань"),
        (
            "home.task_picker.empty.description",
            "Create a task from the Tasks tab first.",
            "Спочатку створіть завдання на вкладці «Завдання»."
        ),
        ("home.task_picker.active_tasks", "Active tasks", "Активні завдання"),
        ("home.task_picker.title", "Choose Task", "Вибрати завдання"),
        ("home.timer.mode.focus", "Pomodoro", "Помодоро"),
        ("home.timer.mode.short_break", "Short break", "Коротка перерва"),
        ("home.timer.mode.long_break", "Long break", "Довга перерва"),
        ("home.timer.subtitle.focus", "Focus time", "Час фокусу"),
        ("home.timer.subtitle.break", "Recharge", "Час відпочити"),
        ("home.timer.accessibility.focus", "Pomodoro timer", "Таймер помодоро"),
        (
            "home.timer.accessibility.short_break",
            "Short break timer",
            "Таймер короткої перерви"
        ),
        (
            "home.timer.accessibility.long_break",
            "Long break timer",
            "Таймер довгої перерви"
        ),
        ("home.timer.action.start_focus", "Start focus", "Почати фокус"),
        ("home.timer.action.start_break", "Start break", "Почати перерву"),
        ("home.timer.action.pause", "Pause", "Пауза"),
        ("home.timer.action.resume", "Resume", "Продовжити"),
        ("home.timer.action.cancel", "Cancel timer", "Скасувати таймер"),
        ("home.timer.action.skip_break", "Skip break", "Пропустити перерву"),
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
