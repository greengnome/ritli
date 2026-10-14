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
    func testUsesStatsInUkrainian() throws {
        let app = makeApp(
            showStats: true,
            language: "uk",
            locale: "uk_UA"
        )
        app.launch()

        XCTAssertTrue(app.navigationBars["Статистика"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.buttons["stats.history"].label, "Історія фокусу")

        let periodPicker = app.segmentedControls["stats.period"]
        XCTAssertTrue(periodPicker.buttons["День"].exists)
        XCTAssertTrue(periodPicker.buttons["Тиждень"].isSelected)
        XCTAssertTrue(periodPicker.buttons["Місяць"].exists)
        XCTAssertTrue(periodPicker.buttons["Рік"].exists)
        XCTAssertTrue(app.staticTexts["Час фокусу"].exists)
        let focusTimeChart = app.descendants(matching: .any)
            .matching(identifier: "stats.focusTime.chart")
            .firstMatch
        XCTAssertTrue(focusTimeChart.exists)
        XCTAssertEqual(
            focusTimeChart.label,
            "Графік часу фокусу"
        )
        XCTAssertTrue(app.staticTexts["Сесії"].exists)
        XCTAssertTrue(app.staticTexts["Виконано"].exists)

        app.swipeUp()
        XCTAssertTrue(
            app.staticTexts["Найпопулярніші категорії"]
                .waitForExistence(timeout: 2)
        )
        XCTAssertTrue(app.staticTexts["Часу фокусу поки немає"].exists)
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
        XCTAssertEqual(app.staticTexts["history.focusTime.value"].label, "0m")
        XCTAssertEqual(app.staticTexts["history.sessions.value"].label, "0")
        XCTAssertEqual(app.staticTexts["history.tasks.value"].label, "0")

        app.swipeUp()
        XCTAssertTrue(
            app.descendants(matching: .any)["history.empty"]
                .waitForExistence(timeout: 2)
        )
    }

    @MainActor
    func testUsesFocusHistoryInUkrainian() throws {
        let app = makeApp(
            showStats: true,
            language: "uk",
            locale: "uk_UA"
        )
        app.launch()

        let historyButton = app.buttons["stats.history"]
        XCTAssertTrue(historyButton.waitForExistence(timeout: 2))
        historyButton.tap()

        XCTAssertTrue(
            app.navigationBars["Історія фокусу"]
                .waitForExistence(timeout: 2)
        )
        XCTAssertTrue(app.descendants(matching: .any)["history.calendar"].exists)
        XCTAssertTrue(app.staticTexts["У фокусі"].exists)
        XCTAssertTrue(app.staticTexts["Сесії"].exists)
        XCTAssertTrue(app.staticTexts["Завдання"].exists)

        app.swipeUp()
        XCTAssertTrue(
            app.staticTexts["Немає сесій фокусу"]
                .waitForExistence(timeout: 2)
        )
        XCTAssertTrue(
            app.staticTexts["Виберіть іншу дату або завершіть сесію фокусу."]
                .exists
        )
    }
}
