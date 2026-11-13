import XCTest
import UIKit

final class SystemUITests: RitliUITestCase {

    @MainActor
    func testFocusNotificationArrivesWhileAppIsInBackground() throws {
        let app = makeApp()
        app.launchArguments += ["--ui-testing-sound-completion", "--ui-testing-background-sound"]
        app.launch()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

        // Per-kind titles are unit-tested (LocalTimerNotificationSchedulerTests);
        // one real delivery covers the system path without three long waits.
        for (kind, mode, title) in [("focus", "Focus", "Focus complete")] {
            XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
            selectTimerMode(kind, titled: mode, in: app)
            let countdown = app.staticTexts["home.timer.countdown"]
            XCTAssertTrue(countdown.waitForExistence(timeout: 5))
            XCTAssertEqual(
                countdown.label, "00:15",
                "The \(mode) notification test must start with the 15-second fixture"
            )
            let primary = app.buttons["home.timer.primary"]
            XCTAssertTrue(scrollToElement(primary, in: app), "\(mode): Start must be reachable")
            primary.tap()
            let cancel = app.buttons["home.timer.cancel"]
            let permissionAlert = springboard.alerts["“Ritli” Would Like to Send You Notifications"]
            // Starting the timer awaits notification permission on a fresh install.
            // Return as soon as the timer starts when permission was already granted.
            let readyToContinue = XCTNSPredicateExpectation(
                predicate: NSPredicate { _, _ in cancel.exists || permissionAlert.exists },
                object: nil
            )
            XCTAssertEqual(
                XCTWaiter.wait(for: [readyToContinue], timeout: 5), .completed,
                "\(mode): tapping Start must start the timer or request notification permission"
            )
            if permissionAlert.exists {
                permissionAlert.buttons["Allow"].tap()
                XCTAssertTrue(cancel.waitForExistence(timeout: 5))
            } else {
                XCTAssertTrue(cancel.exists)
            }
            XCUIDevice.shared.press(.home)
            assertAppIsInBackground(app, context: mode)
            // CI logs show up to 34 seconds in the system notification pipeline
            // after the 15-second timer fires. Keep checking actual banner delivery.
            XCTAssertTrue(springboard.staticTexts[title].waitForExistence(timeout: 60))
            addScreenshot(named: "Background timer alert — \(mode)")
            app.activate()
            XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
            XCTAssertTrue(app.buttons["home.timer.cancel"].waitForNonExistence(timeout: 2))
        }
    }

    @MainActor
    /// End-to-end catch-up of a timer that ran out in the background. Not
    /// replaying its sound is unit-tested in TimerRefreshLoopTests.
    func testReturningToAnExpiredTimerCompletesIt() throws {
        let app = makeApp()
        app.launchArguments.append("--ui-testing-sound-completion")
        app.launch()
        app.buttons["home.timer.primary"].tap()
        XCTAssertTrue(app.buttons["home.timer.cancel"].waitForExistence(timeout: 2))
        XCUIDevice.shared.press(.home)
        // The app is suspended, so there is nothing to poll: wait past the
        // 6-second fixture.
        _ = XCTWaiter.wait(for: [XCTestExpectation(description: "Timer expires in background")], timeout: 7)
        app.activate()
        XCTAssertTrue(app.buttons["home.timer.cancel"].waitForNonExistence(timeout: 2))
        let completion = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "1"),
            object: app.staticTexts["home.summary.sessions"]
        )
        XCTAssertEqual(XCTWaiter.wait(for: [completion], timeout: 3), .completed)
        XCTAssertEqual(app.staticTexts["home.timer.status"].label, "Ready to rest")
    }

    @MainActor
    func testOpensAppLanguageSettings() throws {
        let app = makeApp(showSettings: true)
        let systemSettings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        app.launch()

        let languageButton = app.buttons["settings.language"]
        XCTAssertTrue(
            scrollToElement(languageButton, in: app),
            "The Language row should be reachable by scrolling"
        )
        languageButton.tap()

        XCTAssertTrue(
            systemSettings.wait(for: .runningForeground, timeout: 3),
            "The Language row should open Ritli's page in iOS Settings"
        )
    }
}
