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

        let soundRow = app.buttons["settings.timerSound"]
        XCTAssertTrue(scrollToElement(soundRow, in: app))
        soundRow.tap()
        XCTAssertTrue(app.buttons["settings.timerSound.systemDefault"].waitForExistence(timeout: 2))
        app.buttons["settings.timerSound.silent"].tap()
        XCTAssertTrue(app.buttons["settings.timerSound.silent"].isSelected)
        app.navigationBars.buttons.element(boundBy: 0).tap()

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
    func testUsesSettingsInUkrainian() throws {
        let app = makeApp(
            showSettings: true,
            language: "uk",
            locale: "uk_UA"
        )
        app.launch()

        XCTAssertTrue(app.navigationBars["Налаштування"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Таймер"].exists)
        XCTAssertTrue(app.staticTexts["Цикл"].exists)

        let focusDuration = app.descendants(matching: .any)["settings.focusDuration"]
        XCTAssertTrue(focusDuration.exists)
        XCTAssertTrue(focusDuration.label.contains("Фокус"))
        XCTAssertTrue(focusDuration.label.contains("25 хв"))

        let autoStartBreaks = app.switches["settings.autoStartBreaks"]
        XCTAssertEqual(autoStartBreaks.label, "Автозапуск перерв")
        XCTAssertEqual(autoStartBreaks.value as? String, "Вимкнено")

        XCTAssertTrue(
            scrollToElement(app.staticTexts["Відгук"], in: app),
            "Розділ відгуку має бути доступним після прокручування"
        )
        let soundRow = app.buttons["settings.timerSound"]
        XCTAssertTrue(scrollToElement(soundRow, in: app))
        XCTAssertTrue(soundRow.label.contains("Звук таймера"))
        XCTAssertEqual(app.switches["settings.haptics"].label, "Вібровідгук")
        XCTAssertEqual(app.switches["settings.notifications"].label, "Сповіщення")

        XCTAssertTrue(
            scrollToElement(app.staticTexts["Конфіденційність"], in: app),
            "Розділ конфіденційності має бути доступним після прокручування"
        )
        XCTAssertEqual(
            app.switches["settings.showTaskTitlesOnLockScreen"].label,
            "Показувати назви завдань на екрані блокування"
        )
        XCTAssertTrue(
            scrollToElement(app.staticTexts["Вигляд"], in: app),
            "Розділ вигляду має бути доступним після прокручування"
        )

        let languageButton = app.buttons["settings.language"]
        XCTAssertTrue(
            scrollToElement(languageButton, in: app),
            "Налаштування мови має бути доступним після прокручування"
        )
        XCTAssertTrue(app.staticTexts["Мова"].exists)
        XCTAssertTrue(languageButton.label.contains("Мова застосунку"))
        XCTAssertTrue(languageButton.label.contains("Українська"))
        let languageScreenshot = XCTAttachment(screenshot: app.screenshot())
        languageScreenshot.name = "Ukrainian Language Setting"
        languageScreenshot.lifetime = .keepAlways
        add(languageScreenshot)

        XCTAssertTrue(
            scrollToElement(app.staticTexts["Дані"], in: app),
            "Розділ даних має бути доступним після прокручування"
        )
        XCTAssertTrue(app.staticTexts["Записані сесії"].exists)
        XCTAssertTrue(app.buttons["Очистити історію фокусу"].exists)
        XCTAssertTrue(
            scrollToElement(app.staticTexts["Про застосунок"], in: app),
            "Розділ про застосунок має бути доступним після прокручування"
        )
        // The read-only title is not hittable on iOS 18 because the combined
        // title/value accessibility element covers it. Verify its visible bounds.
        app.swipeUp()
        let version = app.staticTexts["Версія"]
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
