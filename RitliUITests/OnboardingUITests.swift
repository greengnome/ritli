import XCTest
import UIKit

final class OnboardingUITests: RitliUITestCase {

    @MainActor
    func testTransitionsFromSplashToOnboarding() throws {
        let app = makeApp(onboarding: .reset, showsSplash: true)
        app.launch()

        let splash = app.descendants(matching: .any)["startup.splash"]
        XCTAssertTrue(splash.waitForExistence(timeout: 1))
        // XCTest waits for the one-shot reveal to settle before it can read
        // the hierarchy, so verify the finished wordmark rather than motion.
        let frame = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: frame)
        attachment.name = "Splash — wordmark"
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertTrue(splash.exists)
        XCTAssertGreaterThan(
            try splashWordmarkContrast(in: frame),
            0.3,
            "The splash wordmark should be drawn over the launch background"
        )
        XCTAssertTrue(splash.waitForNonExistence(timeout: 7))
        XCTAssertTrue(
            app.staticTexts["onboarding.focus.title"]
                .waitForExistence(timeout: 2)
        )
    }

    @MainActor
    func testCompletesOnboardingOnlyOnce() throws {
        let app = makeApp(onboarding: .reset)
        app.launch()

        let focusTitle = app.staticTexts["onboarding.focus.title"]
        XCTAssertTrue(focusTitle.waitForExistence(timeout: 2))
        XCTAssertEqual(
            app.buttons["onboarding.page.1"].value as? String,
            "Selected"
        )

        tapOnboardingButtonEdge(in: app, offset: CGVector(dx: 0.05, dy: 0.5))
        XCTAssertTrue(
            app.staticTexts["onboarding.tasks.title"]
                .waitForExistence(timeout: 2)
        )
        XCTAssertEqual(
            app.buttons["onboarding.page.2"].value as? String,
            "Selected"
        )

        tapOnboardingButtonEdge(in: app, offset: CGVector(dx: 0.95, dy: 0.5))
        XCTAssertTrue(
            app.staticTexts["onboarding.insights.title"]
                .waitForExistence(timeout: 2)
        )
        XCTAssertEqual(
            app.buttons["onboarding.page.3"].value as? String,
            "Selected"
        )
        XCTAssertEqual(app.buttons["onboarding.continue"].label, "Let's focus")

        tapOnboardingButtonEdge(in: app, offset: CGVector(dx: 0.5, dy: 0.1))

        XCTAssertTrue(
            app.staticTexts["home.timer.countdown"]
                .waitForExistence(timeout: 2)
        )
        XCTAssertFalse(focusTitle.exists)

        app.terminate()
        app.launchArguments = makeApp(onboarding: .keep).launchArguments
        app.launch()

        XCTAssertTrue(
            app.staticTexts["home.timer.countdown"]
                .waitForExistence(timeout: 2)
        )
        XCTAssertFalse(focusTitle.exists)
    }

    @MainActor
    func testOnboardingArtworkAnimatesOnEveryPageAndWhenRevisited() throws {
        let app = makeApp(onboarding: .reset)
        app.launch()
        // The first wait includes the launch, which is slow on a cold runner.
        XCTAssertTrue(app.buttons["onboarding.page.1"].waitForExistence(timeout: 15))

        for (index, page) in ["focus", "tasks", "insights"].enumerated() {
            XCTAssertTrue(waitForValue("Selected", of: app.buttons["onboarding.page.\(index + 1)"]))
            try assertOnboardingArtworkMoves(on: page, in: app)
            if index < 2 {
                // This test checks artwork animation; select the next page
                // directly so a missed hosted-simulator swipe cannot derail it.
                app.buttons["onboarding.page.\(index + 2)"].tap()
            }
        }

        app.buttons["onboarding.page.1"].tap()
        XCTAssertTrue(waitForValue("Selected", of: app.buttons["onboarding.page.1"]))
        try assertOnboardingArtworkMoves(on: "focus", in: app)

        XCUIDevice.shared.press(.home)
        app.activate()
        try assertOnboardingArtworkMoves(on: "focus", in: app)
    }

}
