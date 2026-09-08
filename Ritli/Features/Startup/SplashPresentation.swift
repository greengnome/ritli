import Foundation

nonisolated enum SplashPresentation {
    static let uiTestingArgument = "--ui-testing"
    static let showInUITestsArgument = "--ui-testing-show-splash"

    static func shouldShow(arguments: [String]) -> Bool {
        #if DEBUG
        !arguments.contains(uiTestingArgument)
            || arguments.contains(showInUITestsArgument)
        #else
        true
        #endif
    }

    static func minimumDisplayDuration(arguments: [String]) -> Duration {
        #if DEBUG
        arguments.contains(showInUITestsArgument)
            ? .seconds(5)
            : .milliseconds(850)
        #else
        .milliseconds(850)
        #endif
    }
}
