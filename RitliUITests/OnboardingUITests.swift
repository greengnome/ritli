import XCTest
import UIKit

final class OnboardingUITests: RitliUITestCase {

    @MainActor
    func testTransitionsFromSplashToOnboarding() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing",
            "--ui-testing-show-splash",
            "--ui-testing-reset-onboarding",
            "-AppleLanguages",
            "(en)",
            "-AppleLocale",
            "en_US"
        ]
        app.launch()

        let splash = app.descendants(matching: .any)["startup.splash"]
        XCTAssertTrue(splash.waitForExistence(timeout: 1))
        let firstFrame = XCUIScreen.main.screenshot()
        let firstAttachment = XCTAttachment(screenshot: firstFrame)
        firstAttachment.name = "Splash — animated mark, first frame"
        firstAttachment.lifetime = .keepAlways
        add(firstAttachment)

        _ = XCTWaiter.wait(for: [XCTestExpectation(description: "Next splash animation frame")], timeout: 0.6)
        let secondFrame = XCUIScreen.main.screenshot()
        let secondAttachment = XCTAttachment(screenshot: secondFrame)
        secondAttachment.name = "Splash — animated mark, second frame"
        secondAttachment.lifetime = .keepAlways
        add(secondAttachment)
        XCTAssertTrue(splash.exists)
        XCTAssertFalse(
            try splashMarkPixels(in: firstFrame) == splashMarkPixels(in: secondFrame),
            "The splash logo should visibly animate while it is displayed"
        )
        XCTAssertTrue(splash.waitForNonExistence(timeout: 7))
        XCTAssertTrue(
            app.staticTexts["onboarding.focus.title"]
                .waitForExistence(timeout: 2)
        )
    }

    @MainActor
    func testCompletesOnboardingOnlyOnce() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing",
            "--ui-testing-reset-onboarding",
            "-AppleLanguages",
            "(en)",
            "-AppleLocale",
            "en_US"
        ]
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
        app.launchArguments = [
            "--ui-testing",
            "-AppleLanguages",
            "(en)",
            "-AppleLocale",
            "en_US"
        ]
        app.launch()

        XCTAssertTrue(
            app.staticTexts["home.timer.countdown"]
                .waitForExistence(timeout: 2)
        )
        XCTAssertFalse(focusTitle.exists)
    }

    @MainActor
    func testOnboardingArtworkAnimatesOnEveryPageAndWhenRevisited() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing", "--ui-testing-reset-onboarding",
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US"
        ]
        app.launch()

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

    @MainActor
    func testDisplaysOnboardingInUkrainian() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing",
            "--ui-testing-reset-onboarding",
            "-AppleLanguages",
            "(uk)",
            "-AppleLocale",
            "uk_UA"
        ]
        app.launch()

        let focusTitle = app.staticTexts["onboarding.focus.title"]
        XCTAssertTrue(focusTitle.waitForExistence(timeout: 2))
        XCTAssertEqual(focusTitle.label, "Зосереджуйтеся глибше")
        addScreenshot(named: "Onboarding Ukrainian — focus")
        XCTAssertEqual(app.buttons["onboarding.continue"].label, "Продовжити")
        XCTAssertEqual(
            app.buttons["onboarding.page.1"].value as? String,
            "Вибрано"
        )

        app.buttons["onboarding.continue"].tap()
        let tasksTitle = app.staticTexts["onboarding.tasks.title"]
        XCTAssertTrue(tasksTitle.waitForExistence(timeout: 2))
        XCTAssertEqual(tasksTitle.label, "Перетворюйте плани на прогрес")
        addScreenshot(named: "Onboarding Ukrainian — tasks")

        app.buttons["onboarding.continue"].tap()
        let insightsTitle = app.staticTexts["onboarding.insights.title"]
        XCTAssertTrue(insightsTitle.waitForExistence(timeout: 2))
        XCTAssertEqual(insightsTitle.label, "Відстежуйте свій прогрес")
        addScreenshot(named: "Onboarding Ukrainian — insights")
        XCTAssertEqual(
            app.buttons["onboarding.continue"].label,
            "Почати фокусування"
        )
    }
}
