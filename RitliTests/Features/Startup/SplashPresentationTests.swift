import Testing
@testable import Ritli

struct SplashPresentationTests {
    @Test("Production launches show the splash")
    func showsSplashInProduction() {
        #expect(SplashPresentation.shouldShow(arguments: []))
    }

    @Test("Regular UI tests skip the splash")
    func skipsSplashForUITests() {
        #expect(
            !SplashPresentation.shouldShow(
                arguments: [SplashPresentation.uiTestingArgument]
            )
        )
    }

    @Test("Dedicated UI tests can show the splash")
    func showsSplashForDedicatedUITest() {
        let arguments = [
            SplashPresentation.uiTestingArgument,
            SplashPresentation.showInUITestsArgument
        ]

        #expect(SplashPresentation.shouldShow(arguments: arguments))
        #expect(
            SplashPresentation.minimumDisplayDuration(arguments: arguments)
                == .seconds(5)
        )
    }
}
