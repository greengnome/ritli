import Foundation

nonisolated enum SplashPresentation {
    static let uiTestingArgument = "--ui-testing"
    static let showInUITestsArgument = "--ui-testing-show-splash"

    static func shouldShow(arguments: [String]) -> Bool {
        !arguments.contains(uiTestingArgument)
            || arguments.contains(showInUITestsArgument)
    }

    static func minimumDisplayDuration(arguments: [String]) -> Duration {
        arguments.contains(showInUITestsArgument)
            ? .seconds(5)
            : .milliseconds(850)
    }
}
