import XCTest
import UIKit

final class TaskLifecycleUITests: RitliUITestCase {

    @MainActor
    func testAutomaticallyCompletesTaskWhileViewingTasksAndCanReopen() throws {
        let app = makeApp(showTasks: true, language: "en", locale: "en_US", taskTitle: "Finish proposal")
        app.launchArguments.append("--ui-testing-task-completion")
        app.launch()

        XCTAssertTrue(app.buttons["Start focus on Finish proposal"].waitForExistence(timeout: 3))
        app.buttons["Start focus on Finish proposal"].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 3))
        app.tabBars.buttons["Tasks"].tap()

        let reopenButton = app.buttons["Reopen Finish proposal"]
        XCTAssertTrue(reopenButton.waitForExistence(timeout: 18))
        XCTAssertTrue(app.staticTexts["1 / 1 session"].exists)
        XCTAssertFalse(app.buttons["Start focus on Finish proposal"].exists)
        let completedScreenshot = XCTAttachment(screenshot: app.screenshot())
        completedScreenshot.name = "Task automatically completed at 1 of 1 sessions"
        completedScreenshot.lifetime = .keepAlways
        add(completedScreenshot)

        reopenButton.tap()
        XCTAssertTrue(app.buttons["Mark Finish proposal complete"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["1 / 2 sessions"].exists)
        let reopenedScreenshot = XCTAttachment(screenshot: app.screenshot())
        reopenedScreenshot.name = "Reopened task with one remaining session"
        reopenedScreenshot.lifetime = .keepAlways
        add(reopenedScreenshot)
        app.buttons["Start focus on Finish proposal"].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Start break"].waitForExistence(timeout: 18))

        app.tabBars.buttons["Tasks"].tap()
        XCTAssertTrue(reopenButton.waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["2 / 2 sessions"].exists)
        XCTAssertFalse(app.buttons["Start focus on Finish proposal"].exists)
    }

    @MainActor
    func testArchivesAndRestoresTask() throws {
        let app = makeApp(showTasks: true, taskTitle: "Recoverable task")
        app.launch()

        let taskTitle = app.staticTexts["Recoverable task"]
        XCTAssertTrue(taskTitle.waitForExistence(timeout: 2))
        taskTitle.swipeLeft()

        let archiveAction = app.buttons["Archive"]
        XCTAssertTrue(archiveAction.waitForExistence(timeout: 2))
        archiveAction.tap()
        XCTAssertFalse(taskTitle.exists)

        app.buttons["tasks.archived"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["tasks.archived.screen"]
                .waitForExistence(timeout: 2)
        )

        let archivedTitle = app.staticTexts["Recoverable task"]
        XCTAssertTrue(archivedTitle.waitForExistence(timeout: 2))
        archivedTitle.swipeLeft()
        let restoreAction = app.buttons["Restore"]
        XCTAssertTrue(restoreAction.waitForExistence(timeout: 2))
        restoreAction.tap()
        XCTAssertTrue(
            app.staticTexts["No archived tasks"]
                .waitForExistence(timeout: 2)
        )

        app.buttons["Done"].tap()
        XCTAssertTrue(taskTitle.waitForExistence(timeout: 2))
    }

    @MainActor
    func testStartsFocusFromTaskAndOpensHome() throws {
        let app = makeApp(showTasks: true, taskTitle: "Project roadmap")
        app.launch()

        let startButton = app.buttons["Start focus on Project roadmap"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 2))
        startButton.tap()

        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.descendants(matching: .any)["home.currentTask"].exists)
        XCTAssertEqual(
            app.descendants(matching: .any)["home.currentTask"].label,
            "Working on Project roadmap"
        )
    }

    @MainActor
    func testSelectsTaskFromHomeForNextFocusSession() throws {
        let app = makeApp(taskTitle: "Design landing page")
        app.launch()

        let taskSelector = app.buttons["home.taskSelector"]
        XCTAssertTrue(taskSelector.waitForExistence(timeout: 2))
        taskSelector.tap()

        let taskChoice = app.buttons["Select Design landing page"]
        XCTAssertTrue(taskChoice.waitForExistence(timeout: 2))
        taskChoice.tap()

        XCTAssertEqual(taskSelector.label, "Working on Design landing page")
        app.buttons["Start focus"].tap()

        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 3))
        XCTAssertEqual(
            app.descendants(matching: .any)["home.currentTask"].label,
            "Working on Design landing page"
        )
    }
}
