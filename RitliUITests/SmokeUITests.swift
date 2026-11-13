import XCTest

/// A short smoke suite: launch, the main screens, and the wiring between
/// views and the timer engine. Business rules are covered by unit tests.
final class SmokeUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testCompletesOnboardingOnlyOnce() throws {
        let app = makeApp(onboarding: .reset)
        app.launch()

        let focusTitle = app.staticTexts["onboarding.focus.title"]
        XCTAssertTrue(focusTitle.waitForExistence(timeout: 15))
        app.buttons["onboarding.continue"].tap()
        XCTAssertTrue(app.staticTexts["onboarding.tasks.title"].waitForExistence(timeout: 2))
        app.buttons["onboarding.continue"].tap()
        XCTAssertTrue(app.staticTexts["onboarding.insights.title"].waitForExistence(timeout: 2))
        app.buttons["onboarding.continue"].tap()

        XCTAssertTrue(app.staticTexts["home.timer.countdown"].waitForExistence(timeout: 2))
        XCTAssertFalse(focusTitle.exists)

        app.terminate()
        app.launchArguments = makeApp(onboarding: .keep).launchArguments
        app.launch()

        XCTAssertTrue(app.staticTexts["home.timer.countdown"].waitForExistence(timeout: 5))
        XCTAssertFalse(focusTitle.exists)
    }

    @MainActor
    func testTimerStartsPausesAndResumes() throws {
        let app = makeApp()
        app.launch()

        let startButton = app.buttons["Start focus"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 15))
        startButton.tap()

        let pauseButton = app.buttons["Pause"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 2))
        XCTAssertEqual(app.staticTexts["home.timer.status"].label, "Remaining")
        XCTAssertTrue(app.buttons["home.timer.cancel"].exists)
        pauseButton.tap()

        let resumeButton = app.buttons["Resume"]
        XCTAssertTrue(resumeButton.waitForExistence(timeout: 2))
        XCTAssertEqual(app.staticTexts["home.timer.status"].label, "Paused")
        resumeButton.tap()

        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 2))
    }

    /// Runs in Ukrainian to cover language wiring and Unicode input.
    @MainActor
    func testCreatesAndCompletesTaskInUkrainian() throws {
        let app = makeApp(showTasks: true, language: "uk", locale: "uk_UA")
        app.launch()

        XCTAssertTrue(app.buttons["tasks.add"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.navigationBars["Завдання"].exists)
        app.buttons["tasks.add"].tap()

        let titleField = app.textFields["tasks.editor.title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 2))
        titleField.tap()
        if !app.keyboards.firstMatch.waitForExistence(timeout: 3) {
            // A hosted simulator can miss the first tap while the sheet settles.
            titleField.tap()
        }
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        titleField.typeText("План проєкту")
        app.buttons["tasks.editor.save"].tap()

        XCTAssertTrue(app.buttons["Редагувати: План проєкту"].waitForExistence(timeout: 5))
        let completeButton = app.buttons["Позначити виконаним: План проєкту"]
        XCTAssertTrue(completeButton.exists)
        completeButton.tap()

        XCTAssertTrue(app.buttons["Відкрити знову: План проєкту"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testStartsFocusFromTaskAndOpensHome() throws {
        let app = makeApp(showTasks: true, taskTitle: "Project roadmap")
        app.launch()

        let startButton = app.buttons["Start focus on Project roadmap"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 15))
        startButton.tap()

        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 3))
        XCTAssertEqual(
            app.descendants(matching: .any)["home.currentTask"].label,
            "Working on Project roadmap"
        )
    }

    @MainActor
    func testShowsStatsAndOpensHistory() throws {
        let app = makeApp(showStats: true)
        app.launch()

        XCTAssertTrue(app.descendants(matching: .any)["stats.screen"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.staticTexts["stats.focusTime.value"].label, "0m")
        XCTAssertTrue(app.descendants(matching: .any)["stats.focusTime.chart"].exists)

        let historyButton = app.buttons["stats.history"]
        XCTAssertTrue(historyButton.waitForExistence(timeout: 2))
        historyButton.tap()

        XCTAssertTrue(app.descendants(matching: .any)["history.screen"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.descendants(matching: .any)["history.calendar"].exists)
    }

    // MARK: Launching

    enum OnboardingLaunch {
        /// Mark onboarding as done so tests start on the tabs.
        case skip
        /// Show onboarding from the first page.
        case reset
        /// Keep whatever the previous launch stored.
        case keep
    }

    /// Launches in English unless a test asks for another language, so label
    /// queries don't depend on the simulator's language.
    private func makeApp(
        showTasks: Bool = false,
        showStats: Bool = false,
        language: String = "en",
        locale: String = "en_US",
        taskTitle: String? = nil,
        onboarding: OnboardingLaunch = .skip
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        switch onboarding {
        case .skip:
            app.launchArguments.append("--ui-testing-skip-onboarding")
        case .reset:
            app.launchArguments.append("--ui-testing-reset-onboarding")
        case .keep:
            break
        }
        if let taskTitle {
            app.launchEnvironment["RITLI_UI_TEST_TASK_TITLE"] = taskTitle
        }
        if showTasks {
            app.launchArguments.append("--ui-testing-show-tasks")
        }
        if showStats {
            app.launchArguments.append("--ui-testing-show-stats")
        }
        app.launchArguments.append(contentsOf: [
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", locale
        ])
        return app
    }
}
