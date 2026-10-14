import XCTest
import UIKit

final class TaskEditorUITests: RitliUITestCase {

    @MainActor
    func testDisplaysDefaultCategoriesInUkrainian() throws {
        let app = makeApp(
            showTasks: true,
            language: "uk",
            locale: "uk_UA"
        )
        app.launch()

        XCTAssertTrue(app.buttons["Робота"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Особисте"].exists)
        XCTAssertTrue(app.buttons["Навчання"].exists)
        XCTAssertFalse(app.buttons["Work"].exists)
    }

    @MainActor
    func testCreatesAndCompletesTask() throws {
        let app = makeApp(showTasks: true)
        app.launch()

        XCTAssertTrue(app.buttons["tasks.add"].waitForExistence(timeout: 2))
        app.buttons["tasks.add"].tap()

        let titleField = app.textFields["tasks.editor.title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 2))
        titleField.tap()
        titleField.typeText("Project roadmap")
        app.buttons["tasks.editor.save"].tap()

        let editButton = app.buttons["Edit Project roadmap"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 2))

        let completeButton = app.buttons["Mark Project roadmap complete"]
        XCTAssertTrue(completeButton.exists)
        completeButton.tap()

        XCTAssertTrue(app.buttons["Reopen Project roadmap"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testCreatesAndSelectsCustomTimerRoutine() throws {
        let app = makeApp(showTasks: true)
        app.launch()

        XCTAssertTrue(app.buttons["tasks.add"].waitForExistence(timeout: 2))
        app.buttons["tasks.add"].tap()

        let routinePicker = app.descendants(matching: .any)[
            "tasks.editor.routinePicker"
        ]
        XCTAssertTrue(
            scrollToElement(routinePicker, in: app),
            "The timer routine picker should be visible in the task editor"
        )
        XCTAssertTrue(routinePicker.label.contains("App Defaults"))

        let createRoutine = app.buttons["tasks.editor.routineCreate"]
        XCTAssertTrue(scrollToElement(createRoutine, in: app))
        createRoutine.tap()

        XCTAssertTrue(
            app.navigationBars["New Timer Routine"]
                .waitForExistence(timeout: 2)
        )
        let routineName = app.textFields["routine.editor.name"]
        routineName.tap()
        routineName.typeText("Deep Work")
        app.buttons["routine.editor.save"].tap()

        XCTAssertTrue(
            app.buttons["tasks.editor.routineEdit"]
                .waitForExistence(timeout: 2)
        )
        XCTAssertTrue(routinePicker.label.contains("Deep Work"))

        let titleField = app.textFields["tasks.editor.title"]
        XCTAssertTrue(scrollToElement(titleField, in: app))
        titleField.tap()
        titleField.typeText("Write proposal")
        app.buttons["tasks.editor.save"].tap()

        let editTask = app.buttons["Edit Write proposal"]
        XCTAssertTrue(editTask.waitForExistence(timeout: 2))
        editTask.tap()

        let persistedPicker = app.descendants(matching: .any)[
            "tasks.editor.routinePicker"
        ]
        XCTAssertTrue(scrollToElement(persistedPicker, in: app))
        XCTAssertTrue(persistedPicker.label.contains("Deep Work"))
    }

    @MainActor
    func testUsesTasksInUkrainian() throws {
        let app = makeApp(
            showTasks: true,
            language: "uk",
            locale: "uk_UA"
        )
        app.launch()

        XCTAssertTrue(app.navigationBars["Завдання"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.buttons["tasks.add"].label, "Додати завдання")
        XCTAssertTrue(app.buttons["Усі"].exists)
        XCTAssertTrue(app.staticTexts["Завдань поки немає"].exists)
        XCTAssertTrue(app.buttons["Створити завдання"].exists)

        app.buttons["tasks.add"].tap()
        XCTAssertTrue(app.navigationBars["Нове завдання"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Завдання"].exists)

        let titleField = app.textFields["tasks.editor.title"]
        titleField.tap()
        titleField.typeText("План проєкту")

        let routinePicker = app.descendants(matching: .any)[
            "tasks.editor.routinePicker"
        ]
        XCTAssertTrue(scrollToElement(routinePicker, in: app))
        XCTAssertTrue(routinePicker.label.contains("Налаштування застосунку"))

        let createRoutine = app.buttons["tasks.editor.routineCreate"]
        XCTAssertTrue(scrollToElement(createRoutine, in: app))
        XCTAssertEqual(createRoutine.label, "Створити власний режим")

        XCTAssertEqual(app.buttons["tasks.editor.save"].label, "Додати завдання")
        app.buttons["tasks.editor.save"].tap()

        let editButton = app.buttons["Редагувати: План проєкту"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 2))
        let completeButton = app.buttons["Позначити виконаним: План проєкту"]
        XCTAssertTrue(completeButton.exists)
        completeButton.tap()
        XCTAssertTrue(
            app.buttons["Відкрити знову: План проєкту"]
                .waitForExistence(timeout: 2)
        )
    }
}
