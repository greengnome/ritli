import XCTest
import UIKit

final class HomeUITests: RitliUITestCase {

    @MainActor
    func testFoundationLaunches() throws {
        let app = makeApp()
        app.launch()

        XCTAssertTrue(app.staticTexts["Ritli"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["home.timer.countdown"].exists)
        XCTAssertEqual(app.staticTexts["home.timer.status"].label, "Ready to focus")
        addScreenshot(named: "Quiet ring — ready")
    }

    @MainActor
    func testTimerModeMenuRemainsUsableAcrossRefreshIntervals() throws {
        let app = makeApp()
        app.launch()

        for (kind, mode, countdown) in [
            ("shortBreak", "Short break", "05:00"),
            // Reselect the current mode: the trigger and menu item share a label.
            ("shortBreak", "Short break", "05:00"),
            ("longBreak", "Long break", "15:00"),
            ("focus", "Focus", "25:00")
        ] {
            // Exercise the menu across the old one-second whole-card refresh boundary.
            selectTimerMode(kind, titled: mode, in: app, menuOpenDuration: 1.2)
            XCTAssertEqual(app.staticTexts["home.timer.countdown"].label, countdown)
        }
        addScreenshot(named: "Quiet ring — Focus mode menu")
    }

    @MainActor
    func testTimerStartsPausesAndResumes() throws {
        let app = makeApp()
        app.launch()

        let startButton = app.buttons["Start focus"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 3))
        let controlHeight = startButton.frame.height
        startButton.tap()

        let pauseButton = app.buttons["Pause"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 2))
        XCTAssertEqual(app.staticTexts["home.timer.status"].label, "Remaining")
        addScreenshot(named: "Quiet ring — running")
        XCTAssertEqual(pauseButton.frame.height, controlHeight, accuracy: 1)

        let cancelButton = app.buttons["home.timer.cancel"]
        XCTAssertTrue(cancelButton.exists)
        XCTAssertEqual(cancelButton.frame.height, controlHeight, accuracy: 1)
        pauseButton.tap()

        let resumeButton = app.buttons["Resume"]
        XCTAssertTrue(resumeButton.waitForExistence(timeout: 2))
        XCTAssertEqual(app.staticTexts["home.timer.status"].label, "Paused")
        addScreenshot(named: "Quiet ring — paused")
        XCTAssertEqual(resumeButton.frame.height, controlHeight, accuracy: 1)
        resumeButton.tap()

        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Cancel timer"].exists)
    }

    @MainActor
    func testTimerControlsRemainUsableAtLargestTextSize() throws {
        let app = makeApp()
        app.launchArguments += [
            "-UIPreferredContentSizeCategoryName",
            UIContentSizeCategory.accessibilityExtraExtraExtraLarge.rawValue
        ]
        app.launch()

        let primary = app.buttons["home.timer.primary"]
        XCTAssertTrue(scrollToElement(primary, in: app))
        XCTAssertGreaterThan(primary.frame.height, 52)
        XCTAssertTrue(app.buttons["Start focus"].exists)
        addScreenshot(named: "Home timer — largest Dynamic Type")
        primary.tap()

        // The pause/resume flow is covered at the default size; here only
        // check that the running controls stay reachable.
        let pause = app.buttons["Pause"]
        XCTAssertTrue(pause.waitForExistence(timeout: 3))
        XCTAssertTrue(scrollToElement(pause, in: app))

        let cancel = app.buttons["home.timer.cancel"]
        // Dynamic Type can move Cancel under the navigation bar while XCTest
        // still reports it as hittable. Bring its tap point into visible bounds.
        XCTAssertTrue(scrollToElement(cancel, in: app))
        cancel.tap()
        XCTAssertTrue(app.buttons["Start focus"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testOpensSettingsFromHomeToolbar() throws {
        let app = makeApp()
        app.launch()

        let settingsButton = app.buttons["home.settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 2))
        settingsButton.tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["settings.screen"]
                .waitForExistence(timeout: 2)
        )
        XCTAssertTrue(app.tabBars.buttons["Settings"].isSelected)
    }

    @MainActor
    func testOpensFocusHistoryFromHomeSummary() throws {
        let app = makeApp()
        app.launch()

        let viewAllButton = app.buttons["home.summary.viewAll"]
        XCTAssertTrue(viewAllButton.waitForExistence(timeout: 2))
        app.swipeUp()
        viewAllButton.tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["history.screen"]
                .waitForExistence(timeout: 2)
        )
        XCTAssertTrue(app.tabBars.buttons["Home"].isSelected)
    }
}
