import XCTest
import UIKit

final class StatsUITests: RitliUITestCase {

    @MainActor
    func testStatsScreenSwitchesPeriodsAndShowsEmptyHistory() throws {
        let app = makeApp(showStats: true)
        app.launch()

        XCTAssertTrue(app.descendants(matching: .any)["stats.screen"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.staticTexts["stats.focusTime.value"].label, "0m")
        XCTAssertEqual(app.staticTexts["stats.sessions.value"].label, "0")
        XCTAssertEqual(app.staticTexts["stats.tasks.value"].label, "0")

        XCTAssertTrue(app.descendants(matching: .any)["stats.focusTime.chart"].exists)

        let periodPicker = app.segmentedControls["stats.period"]
        XCTAssertTrue(periodPicker.waitForExistence(timeout: 2))
        periodPicker.buttons["Month"].tap()
        XCTAssertTrue(periodPicker.buttons["Month"].isSelected)

        app.swipeUp()
        XCTAssertTrue(
            app.descendants(matching: .any)["stats.categories.empty"]
                .waitForExistence(timeout: 2)
        )
    }

    @MainActor
    func testOpensFocusHistoryFromStats() throws {
        let app = makeApp(showStats: true)
        app.launch()

        let historyButton = app.buttons["stats.history"]
        XCTAssertTrue(historyButton.waitForExistence(timeout: 2))
        historyButton.tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["history.screen"]
                .waitForExistence(timeout: 2)
        )
        XCTAssertTrue(app.descendants(matching: .any)["history.calendar"].exists)
        XCTAssertEqual(app.staticTexts["history.focusTime.value"].label, "0m")
        XCTAssertEqual(app.staticTexts["history.sessions.value"].label, "0")
        XCTAssertEqual(app.staticTexts["history.tasks.value"].label, "0")

        app.swipeUp()
        XCTAssertTrue(
            app.descendants(matching: .any)["history.empty"]
                .waitForExistence(timeout: 2)
        )
    }
}
