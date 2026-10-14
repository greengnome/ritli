import XCTest
import UIKit

final class LiveActivityUITests: RitliUITestCase {

    @MainActor
    func testDisplaysRunningTimerOutsideApp() throws {
        let app = makeApp()
        defer {
            app.activate()
            let cancelButton = app.buttons["home.timer.cancel"]
            if cancelButton.waitForExistence(timeout: 2) {
                cancelButton.tap()
            }
            app.terminate()
        }
        app.launch()

        XCTAssertTrue(app.buttons["Start focus"].waitForExistence(timeout: 3))
        app.buttons["Start focus"].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 2))

        XCUIDevice.shared.press(.home)

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCTAssertTrue(
            springboard.wait(for: .runningForeground, timeout: 3),
            "Starting a timer should leave a running Live Activity visible outside Ritli."
        )
        let activityContainer = springboard.descendants(matching: .any)
            .matching(
                NSPredicate(
                    format: "identifier CONTAINS %@",
                    "WidgetRenderer-Activities"
                )
            )
            .firstMatch

        XCTAssertTrue(
            activityContainer.waitForExistence(timeout: 10),
            "The Live Activity container should become available in SpringBoard."
        )

        addScreenshot(named: "Running focus Live Activity — compact")

        activityContainer.press(forDuration: 1)

        let expandedTitle = springboard.staticTexts["Focus"]
        var didRevealExpandedActivity = expandedTitle.waitForExistence(timeout: 10)
        if !didRevealExpandedActivity {
            addScreenshot(named: "Running focus Live Activity — first expansion attempt")

            // SpringBoard's hosted activity renderer can briefly expose its
            // container before its accessibility content is ready. Collapse
            // it and make one fresh expansion attempt before failing.
            springboard.coordinate(
                withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)
            ).tap()
            XCTAssertTrue(
                activityContainer.waitForExistence(timeout: 5),
                "The Live Activity should remain available for a retry."
            )
            activityContainer.press(forDuration: 1)
            didRevealExpandedActivity = expandedTitle.waitForExistence(timeout: 10)
        }

        XCTAssertTrue(
            didRevealExpandedActivity,
            "Long-pressing the timer should reveal the expanded Live Activity."
        )

        addScreenshot(named: "Running focus Live Activity — expanded")
    }

    @MainActor
    func testDisplaysFinishedTimerOutsideApp() throws {
        let app = makeApp(language: "en", locale: "en_US")
        app.launchArguments.append("--ui-testing-short-session")
        defer {
            app.activate()
            let cancelButton = app.buttons["home.timer.cancel"]
            if cancelButton.exists {
                cancelButton.tap()
            }
            app.terminate()
        }
        app.launch()

        XCTAssertTrue(app.buttons["Start focus"].waitForExistence(timeout: 3))
        app.buttons["Start focus"].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 2))
        XCUIDevice.shared.press(.home)

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let activityContainer = springboard.descendants(matching: .any)
            .matching(NSPredicate(
                format: "identifier CONTAINS %@", "WidgetRenderer-Activities"
            ))
            .firstMatch
        XCTAssertTrue(activityContainer.waitForExistence(timeout: 10))
        // Stop app-side timers so this exercises ActivityKit's expiry render,
        // as it must work when iOS suspends or terminates the app process.
        app.terminate()
        activityContainer.press(forDuration: 1)
        XCTAssertTrue(
            springboard.staticTexts["Focus finished"].waitForExistence(timeout: 150),
            "An expired session should display its completion without an update from the app."
        )
        XCTAssertFalse(springboard.staticTexts["Stay focused"].exists)
        XCTAssertFalse(springboard.staticTexts["0:00"].exists)
        addScreenshot(named: "Finished focus Live Activity — expanded")

        springboard.coordinate(
            withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)
        ).tap()
        XCTAssertTrue(springboard.images["Finished"].waitForExistence(timeout: 10))
        addScreenshot(named: "Finished focus Live Activity — compact")

        // Notification Center hosts the same presentation as the Lock Screen.
        springboard.coordinate(
            withNormalizedOffset: CGVector(dx: 0.15, dy: 0.01)
        ).press(
            forDuration: 0.1,
            thenDragTo: springboard.coordinate(
                withNormalizedOffset: CGVector(dx: 0.15, dy: 0.8)
            )
        )
        XCTAssertTrue(
            springboard.staticTexts["Focus finished"].waitForExistence(timeout: 10)
        )
        XCTAssertFalse(springboard.staticTexts["Stay focused"].exists)
        XCTAssertFalse(springboard.staticTexts["0:00"].exists)
        addScreenshot(named: "Finished focus Live Activity — Lock Screen layout")
    }
}
