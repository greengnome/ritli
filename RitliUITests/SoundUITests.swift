import XCTest
import UIKit

final class SoundUITests: RitliUITestCase {

    @MainActor
    func testSelectsTimerSoundAndPreservesItWhenReopeningPicker() throws {
        let app = makeApp(showSettings: true)
        app.launch()
        let soundRow = app.buttons["settings.timerSound"]
        XCTAssertTrue(scrollToElement(soundRow, in: app))
        soundRow.tap()
        let bell = app.buttons["settings.timerSound.gentleBell"]
        XCTAssertTrue(bell.waitForExistence(timeout: 2))
        bell.tap()
        XCTAssertTrue(bell.isSelected)
        XCTAssertTrue(app.buttons["settings.timerSound.preview.gentleBell"].exists)
        addScreenshot(named: "Timer sound — choices")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(soundRow.label.contains("Gentle bell"))
        soundRow.tap()
        XCTAssertTrue(app.buttons["settings.timerSound.gentleBell"].isSelected)
        app.buttons["settings.timerSound.silent"].tap()
        XCTAssertTrue(app.buttons["settings.timerSound.silent"].isSelected)
        XCTAssertFalse(app.buttons["settings.timerSound.preview.silent"].exists)
    }

    @MainActor
    func testFocusCompletesWithSoundAndNotificationsOff() throws {
        let app = makeApp()
        app.launchArguments.append("--ui-testing-sound-completion")
        app.launch()

        // TimerEngineSoundTests covers all three modes with a controlled clock.
        // Keep one end-to-end check of foreground completion and preferences.
        app.buttons["home.timer.primary"].tap()
        XCTAssertTrue(app.buttons["home.timer.cancel"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["home.timer.cancel"].waitForNonExistence(timeout: 8))
        let completion = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "1"),
            object: app.staticTexts["home.summary.sessions"]
        )
        XCTAssertEqual(XCTWaiter.wait(for: [completion], timeout: 2), .completed)
        app.tabBars.buttons["Settings"].tap()
        let notifications = app.switches["settings.notifications"]
        XCTAssertTrue(scrollToElement(notifications, in: app))
        XCTAssertEqual(notifications.value as? String, "Off")
        XCTAssertEqual(app.switches["settings.haptics"].value as? String, "Off")
    }

    @MainActor
    func testCustomSoundPreviewsDoNotChangeTheSelectedSound() throws {
        let app = makeApp(showSettings: true)
        app.launch()
        let soundRow = app.buttons["settings.timerSound"]
        XCTAssertTrue(scrollToElement(soundRow, in: app))
        soundRow.tap()
        let selectedSound = app.buttons["settings.timerSound.systemDefault"]
        XCTAssertTrue(selectedSound.waitForExistence(timeout: 2))

        for sound in ["gentleBell", "clearChime", "softPulse"] {
            app.buttons["settings.timerSound.preview.\(sound)"].tap()
            XCTAssertTrue(selectedSound.isSelected)
            XCTAssertFalse(app.alerts.firstMatch.exists)
        }

        app.buttons["settings.timerSound.silent"].tap()
        XCTAssertTrue(app.buttons["settings.timerSound.silent"].isSelected)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(soundRow.label.contains("Silent"))
    }

    @MainActor
    func testTimerAndSoundPickerSupportDarkAppearance() throws {
        let app = makeApp(showSettings: true)
        app.launch()
        let appearance = app.descendants(matching: .any)["settings.appearance"]
        XCTAssertTrue(scrollToElement(appearance, in: app))
        appearance.tap()
        app.buttons["Dark"].tap()
        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(app.staticTexts["home.timer.countdown"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.staticTexts["home.timer.countdown"].label, "25:00")
        addScreenshot(named: "Quiet ring — dark appearance")

        app.tabBars.buttons["Settings"].tap()
        let soundRow = app.buttons["settings.timerSound"]
        XCTAssertTrue(scrollToElement(soundRow, in: app))
        soundRow.tap()
        XCTAssertTrue(app.buttons["settings.timerSound.systemDefault"].waitForExistence(timeout: 2))
        addScreenshot(named: "Timer sound — dark appearance")
    }
}
