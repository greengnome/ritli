import XCTest
import UIKit

final class TaskEditorUITests: RitliUITestCase {

    @MainActor
    func testCreatesAndCompletesTaskInUkrainian() throws {
        let app = makeApp(showTasks: true, language: "uk", locale: "uk_UA")
        app.launch()

        XCTAssertTrue(app.buttons["tasks.add"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.navigationBars["Завдання"].exists)
        XCTAssertTrue(app.buttons["Робота"].exists)
        XCTAssertTrue(app.staticTexts["Завдань поки немає"].exists)
        app.buttons["tasks.add"].tap()

        let titleField = app.textFields["tasks.editor.title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 2))
        titleField.tap()
        titleField.typeText("План проєкту")
        app.buttons["tasks.editor.save"].tap()

        let editButton = app.buttons["Редагувати: План проєкту"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 2))

        let completeButton = app.buttons["Позначити виконаним: План проєкту"]
        XCTAssertTrue(completeButton.exists)
        completeButton.tap()

        XCTAssertTrue(app.buttons["Відкрити знову: План проєкту"].waitForExistence(timeout: 2))
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
}
