import XCTest
import UIKit

final class SettingsUITests: RitliUITestCase {

    @MainActor
    func testChangesSettingsPreferences() throws {
        let app = makeApp(showSettings: true)
        app.launch()

        XCTAssertTrue(
            app.descendants(matching: .any)["settings.screen"]
                .waitForExistence(timeout: 2)
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["settings.focusDuration"].exists
        )
        let autoStartBreaks = app.switches["settings.autoStartBreaks"]
        XCTAssertTrue(autoStartBreaks.exists)
        XCTAssertEqual(autoStartBreaks.value as? String, "Off")
        tapSwitch(autoStartBreaks)
        XCTAssertTrue(waitForValue("On", of: autoStartBreaks))

        let appearance = app.descendants(matching: .any)["settings.appearance"]
        XCTAssertTrue(
            scrollToElement(appearance, in: app),
            "Appearance settings should be reachable by scrolling"
        )
        XCTAssertEqual(
            app.switches["settings.showTaskTitlesOnLockScreen"].value as? String,
            "Off"
        )

        let support = app.descendants(matching: .any)["settings.support"]
        XCTAssertTrue(
            scrollToElement(support, in: app),
            "Support settings should be reachable by scrolling"
        )
    }

    @MainActor
    func testVersionRowStaysWithinVisibleBounds() throws {
        let app = makeApp(showSettings: true)
        app.launch()

        XCTAssertTrue(
            scrollToElement(app.staticTexts["About"], in: app),
            "The About section should be reachable by scrolling"
        )
        // The read-only title is not hittable on iOS 18 because the combined
        // title/value accessibility element covers it. Verify its visible bounds.
        app.swipeUp()
        let version = app.staticTexts["Version"]
        XCTAssertTrue(version.exists)
        XCTAssertGreaterThanOrEqual(version.frame.minY, app.navigationBars.firstMatch.frame.maxY)
        XCTAssertLessThanOrEqual(version.frame.maxY, app.tabBars.firstMatch.frame.minY)
    }

    @MainActor
    func testClearsRecordedFocusHistory() throws {
        let app = makeApp()
        app.launch()

        XCTAssertTrue(app.buttons["Start focus"].waitForExistence(timeout: 3))
        app.buttons["Start focus"].tap()

        let cancelTimer = app.buttons["home.timer.cancel"]
        XCTAssertTrue(cancelTimer.waitForExistence(timeout: 2))
        cancelTimer.tap()

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["settings.screen"]
                .waitForExistence(timeout: 2)
        )

        let clearHistory = app.buttons["settings.clearHistory"]
        XCTAssertTrue(
            scrollToElement(clearHistory, in: app),
            "Clear History should be reachable by scrolling"
        )
        XCTAssertTrue(clearHistory.isEnabled)
        clearHistory.tap()

        let confirmClear = app.buttons["Clear History"]
        XCTAssertTrue(confirmClear.waitForExistence(timeout: 2))
        confirmClear.tap()

        XCTAssertTrue(waitForEnabled(false, of: clearHistory))
        XCTAssertEqual(
            app.staticTexts["settings.historyCount"].label,
            "Recorded sessions, 0"
        )
    }
}
