import Foundation
import Testing
@testable import Ritli

@Suite("Tasks localization")
struct TasksLocalizationTests {
    @Test("Tasks copy resolves in English and Ukrainian", arguments: [
        ("tasks.action.add", "Add task", "Додати завдання"),
        ("tasks.action.add_short", "Add", "Додати"),
        ("tasks.action.archive", "Archive", "Архівувати"),
        ("tasks.action.create", "Create a task", "Створити завдання"),
        ("tasks.action.edit", "Edit", "Редагувати"),
        ("tasks.action.save", "Save", "Зберегти"),
        ("tasks.action.save.accessibility", "Save task", "Зберегти завдання"),
        ("tasks.alert.save_failed", "Task could not be saved", "Не вдалося зберегти завдання"),
        ("tasks.alert.unavailable", "Tasks unavailable", "Завдання недоступні"),
        ("tasks.archived.delete", "Delete", "Видалити"),
        ("tasks.archived.empty.title", "No archived tasks", "Немає заархівованих завдань"),
        ("tasks.archived.restore", "Restore", "Відновити"),
        ("tasks.archived.title", "Archived Tasks", "Архівовані завдання"),
        ("tasks.editor.category", "Category", "Категорія"),
        ("tasks.editor.date", "Date", "Дата"),
        ("tasks.editor.due_date", "Due date", "Термін виконання"),
        ("tasks.editor.edit.title", "Edit Task", "Редагувати завдання"),
        ("tasks.editor.new.title", "New Task", "Нове завдання"),
        ("tasks.editor.notes_placeholder", "Optional details", "Необов’язкові деталі"),
        ("tasks.editor.notes_section", "Notes", "Нотатки"),
        ("tasks.editor.plan_section", "Plan", "План"),
        ("tasks.editor.priority", "Priority", "Пріоритет"),
        ("tasks.editor.routine.app_defaults", "App Defaults", "Налаштування застосунку"),
        ("tasks.editor.routine.create", "Create Custom Routine", "Створити власний режим"),
        ("tasks.editor.routine.edit", "Edit Routine", "Редагувати режим"),
        (
            "tasks.editor.routine.footer",
            "App Defaults follow Settings. Custom routines can be reused by other tasks.",
            "Налаштування застосунку відповідають розділу «Налаштування». Власні режими можна використовувати для інших завдань."
        ),
        ("tasks.editor.routine.picker", "Routine", "Режим"),
        ("tasks.editor.routine.section", "Timer Routine", "Режим таймера"),
        ("tasks.editor.task_section", "Task", "Завдання"),
        ("tasks.editor.title_placeholder", "What do you want to accomplish?", "Що ви хочете виконати?"),
        ("tasks.routine.editor.edit.title", "Edit Timer Routine", "Редагувати режим таймера"),
        ("tasks.routine.editor.name", "Name", "Назва"),
        ("tasks.routine.editor.name_placeholder", "e.g. Deep Work", "напр. Глибока робота"),
        ("tasks.routine.editor.new.title", "New Timer Routine", "Новий режим таймера"),
        (
            "tasks.empty.all.description",
            "Plan work in focus sessions, then track progress here.",
            "Плануйте роботу сесіями фокусу й відстежуйте прогрес тут."
        ),
        ("tasks.empty.all.title", "No tasks yet", "Завдань поки немає"),
        (
            "tasks.empty.category.description",
            "Choose another category or create a task for this one.",
            "Виберіть іншу категорію або створіть завдання для цієї."
        ),
        ("tasks.empty.category.title", "No tasks in this category", "У цій категорії немає завдань"),
        ("tasks.filter.all", "All", "Усі"),
        ("tasks.priority.high", "Important", "Важливий"),
        ("tasks.priority.high.accessibility", "High priority", "Високий пріоритет"),
        ("tasks.priority.low", "Low", "Низький"),
        ("tasks.priority.normal", "Normal", "Звичайний"),
        ("tasks.row.start_focus.hint", "Starts a focus timer and opens Home", "Запускає таймер фокусу й відкриває вкладку «Головна»"),
        ("tasks.row.timer_active.hint", "Finish or cancel the current timer first", "Спочатку завершіть або скасуйте поточний таймер"),
    ])
    func resolvesCopy(key: String, english: String, ukrainian: String) throws {
        let englishBundle = try localizedBundle(language: "en")
        let ukrainianBundle = try localizedBundle(language: "uk")

        #expect(localizedValue(key, bundle: englishBundle) == english)
        #expect(localizedValue(key, bundle: ukrainianBundle) == ukrainian)
    }

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
        let englishBundle = try localizedBundle(language: "en")
        let ukrainianBundle = try localizedBundle(language: "uk")

        #expect(formattedValue(key, bundle: englishBundle) == english)
        #expect(formattedValue(key, bundle: ukrainianBundle) == ukrainian)
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
        let bundle = try localizedBundle(language: language)
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

    private func formattedValue(_ key: String, bundle: Bundle) -> String {
        String(
            format: localizedValue(key, bundle: bundle),
            locale: Locale(identifier: bundle.bundleURL.lastPathComponent),
            "План проєкту"
        )
    }

    private func localizedBundle(language: String) throws -> Bundle {
        let resourcePath = try #require(
            Bundle.main.path(forResource: language, ofType: "lproj")
        )
        return try #require(Bundle(path: resourcePath))
    }
}
