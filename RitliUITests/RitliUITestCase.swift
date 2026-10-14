import XCTest
import UIKit

// Shared support only: concrete subclasses own all test methods.
class RitliUITestCase: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func assertAppIsInBackground(
        _ app: XCUIApplication,
        context: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let started = Date()
        var observations: [String] = []
        let background = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                let state = app.state
                observations.append(String(
                    format: "%.3fs: %@ (%lu)",
                    Date().timeIntervalSince(started),
                    String(describing: state), state.rawValue
                ))
                // iOS may suspend the process before XCTest observes it. Both
                // states are background; a terminated or foreground app is not.
                return state == .runningBackground || state == .runningBackgroundSuspended
            },
            object: nil
        )
        let result = XCTWaiter.wait(for: [background], timeout: 5)
        let diagnostic = "\(context): background wait \(result); final state \(app.state)\n"
            + observations.joined(separator: "\n")
        let attachment = XCTAttachment(string: diagnostic)
        attachment.name = "Background transition — \(context)"
        attachment.lifetime = .keepAlways
        add(attachment)
        print(diagnostic)
        if result != .completed {
            addScreenshot(named: "Failed background transition — \(context)")
        }
        XCTAssertEqual(result, .completed, diagnostic, file: file, line: line)
    }

    func splashMarkPixels(in screenshot: XCUIScreenshot) throws -> Data {
        let image = try XCTUnwrap(screenshot.image.cgImage)
        let side = CGFloat(image.width) * 0.55
        let rect = CGRect(
            x: (CGFloat(image.width) - side) / 2,
            y: (CGFloat(image.height) - side) / 2,
            width: side, height: side
        ).integral
        let mark = UIImage(cgImage: try XCTUnwrap(image.cropping(to: rect)))
        return try XCTUnwrap(mark.pngData())
    }

    func tapOnboardingButtonEdge(in app: XCUIApplication, offset: CGVector) {
        let button = app.buttons["onboarding.continue"]
        XCTAssertGreaterThan(button.frame.width, app.frame.width * 0.8)
        XCTAssertGreaterThanOrEqual(button.frame.height, 58)
        button.coordinate(withNormalizedOffset: offset).tap()
    }

    func assertOnboardingArtworkMoves(on page: String, in app: XCUIApplication) throws {
        let title = app.staticTexts["onboarding.\(page).title"]
        XCTAssertTrue(title.waitForExistence(timeout: 2))
        // Exclude page transitions, the status bar, and copy from the comparison.
        // Sample after the entrance animation to catch artwork becoming static.
        _ = XCTWaiter.wait(for: [XCTestExpectation(description: "Artwork settled")], timeout: 1.2)
        let first = try onboardingArtworkImage(above: title, in: app)
        _ = XCTWaiter.wait(for: [XCTestExpectation(description: "Next animation frame")], timeout: 1.2)
        let second = try onboardingArtworkImage(above: title, in: app)
        XCTAssertFalse(first.pngData() == second.pngData(), "The \(page) artwork should animate")
        addScreenshot(named: "Onboarding — \(page)")
    }

    func onboardingArtworkImage(above title: XCUIElement, in app: XCUIApplication) throws -> UIImage {
        let screenshot = XCUIScreen.main.screenshot().image
        let image = try XCTUnwrap(screenshot.cgImage)
        let scale = CGFloat(image.width) / app.frame.width
        let crop = CGRect(
            x: 0, y: 100 * scale,
            width: CGFloat(image.width),
            height: (title.frame.minY - 116) * scale
        ).integral
        return UIImage(cgImage: try XCTUnwrap(image.cropping(to: crop)))
    }

    func createTask(named title: String, in app: XCUIApplication) {
        XCTAssertTrue(app.buttons["tasks.add"].waitForExistence(timeout: 2))
        app.buttons["tasks.add"].tap()

        let titleField = app.textFields["tasks.editor.title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 2))
        titleField.tap()
        let keyboard = app.keyboards.firstMatch
        if !keyboard.waitForExistence(timeout: 3) {
            // A hosted simulator can miss the first tap while the editor sheet
            // settles. Focus the field again before dispatching any keystrokes.
            titleField.tap()
        }
        XCTAssertTrue(
            keyboard.waitForExistence(timeout: 5),
            "The task editor keyboard should be ready before entering the title"
        )
        titleField.typeText(title)
        // On a cold hosted keyboard, queued characters can arrive after typeText returns.
        XCTAssertTrue(waitForValue(title, of: titleField, timeout: 20))
        let saveButton = app.buttons["tasks.editor.save"]
        let saveReady = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isEnabled == true AND isHittable == true"),
            object: saveButton
        )
        XCTAssertEqual(XCTWaiter.wait(for: [saveReady], timeout: 5), .completed)
        saveButton.tap()

        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 5))
    }

    func waitForValue(
        _ value: String,
        of element: XCUIElement,
        timeout: TimeInterval = 2
    ) -> Bool {
        let predicate = NSPredicate(format: "value == %@", value)
        let expectation = XCTNSPredicateExpectation(
            predicate: predicate,
            object: element
        )
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    func addScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func waitForEnabled(
        _ isEnabled: Bool,
        of element: XCUIElement,
        timeout: TimeInterval = 2
    ) -> Bool {
        let predicate = NSPredicate(
            format: "enabled == %@",
            NSNumber(value: isEnabled)
        )
        let expectation = XCTNSPredicateExpectation(
            predicate: predicate,
            object: element
        )
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    func tapSwitch(_ element: XCUIElement) {
        element.coordinate(
            withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)
        ).tap()
    }

    func scrollToElement(
        _ element: XCUIElement,
        in app: XCUIApplication,
        maxSwipes: Int = 5
    ) -> Bool {
        for attempt in 0...maxSwipes {
            let containers = app.scrollViews.allElementsBoundByIndex
                + app.collectionViews.allElementsBoundByIndex
                + app.tables.allElementsBoundByIndex
            let scrollView = containers.filter(\.isHittable).max {
                $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height
            }
            var visibleFrame = scrollView?.frame.intersection(app.frame) ?? app.frame
            let navigationBar = app.navigationBars.firstMatch
            if navigationBar.exists && navigationBar.isHittable {
                let top = max(visibleFrame.minY, navigationBar.frame.maxY)
                visibleFrame = CGRect(
                    x: visibleFrame.minX, y: top,
                    width: visibleFrame.width, height: max(0, visibleFrame.maxY - top)
                )
            }
            let tabBar = app.tabBars.firstMatch
            if tabBar.exists && tabBar.isHittable {
                visibleFrame.size.height = max(
                    0, min(visibleFrame.maxY, tabBar.frame.minY) - visibleFrame.minY
                )
            }
            let keyboard = app.keyboards.firstMatch
            if keyboard.exists {
                visibleFrame.size.height = max(
                    0,
                    min(visibleFrame.maxY, keyboard.frame.minY) - visibleFrame.minY
                )
            }
            guard visibleFrame.height > 40 else { return false }
            // XCTest can report a partially obscured button as hittable even
            // when its tap point lies behind a navigation or tab bar.
            if element.exists && element.isHittable
                && visibleFrame.insetBy(dx: 2, dy: 2).contains(
                    CGPoint(x: element.frame.midX, y: element.frame.midY)
                ) {
                return true
            }
            guard attempt < maxSwipes else { break }

            let origin = app.coordinate(withNormalizedOffset: .zero)
            let upper = origin.withOffset(CGVector(
                dx: visibleFrame.midX - app.frame.minX,
                dy: visibleFrame.minY + visibleFrame.height * 0.2 - app.frame.minY
            ))
            let lower = origin.withOffset(CGVector(
                dx: visibleFrame.midX - app.frame.minX,
                dy: visibleFrame.minY + visibleFrame.height * 0.8 - app.frame.minY
            ))
            if element.exists && element.frame.midY < visibleFrame.midY {
                upper.press(forDuration: 0.05, thenDragTo: lower)
            } else {
                lower.press(forDuration: 0.05, thenDragTo: upper)
            }
        }
        return false
    }

    func makeApp(
        showTasks: Bool = false,
        showStats: Bool = false,
        showSettings: Bool = false,
        language: String? = nil,
        locale: String? = nil,
        taskTitle: String? = nil
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing",
            "--ui-testing-skip-onboarding"
        ]
        if let taskTitle {
            app.launchEnvironment["RITLI_UI_TEST_TASK_TITLE"] = taskTitle
        }
        if showTasks {
            app.launchArguments.append("--ui-testing-show-tasks")
        }
        if showStats {
            app.launchArguments.append("--ui-testing-show-stats")
        }
        if showSettings {
            app.launchArguments.append("--ui-testing-show-settings")
        }
        if let language {
            app.launchArguments.append(contentsOf: [
                "-AppleLanguages",
                "(\(language))"
            ])
        }
        if let locale {
            app.launchArguments.append(contentsOf: [
                "-AppleLocale",
                locale
            ])
        }
        return app
    }
}
