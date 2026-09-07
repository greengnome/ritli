import Foundation
import Observation

@MainActor
@Observable
final class OnboardingStore {
    static let completionKey = "hasCompletedOnboarding"
    static let resetLaunchArgument = "--ui-testing-reset-onboarding"
    static let skipLaunchArgument = "--ui-testing-skip-onboarding"

    private(set) var hasCompletedOnboarding: Bool

    @ObservationIgnored
    private let defaults: UserDefaults

    init(
        defaults: UserDefaults = .standard,
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) {
        self.defaults = defaults

        if arguments.contains(Self.resetLaunchArgument) {
            defaults.set(false, forKey: Self.completionKey)
        } else if arguments.contains(Self.skipLaunchArgument) {
            defaults.set(true, forKey: Self.completionKey)
        }

        hasCompletedOnboarding = defaults.bool(forKey: Self.completionKey)
    }

    func complete() {
        guard !hasCompletedOnboarding else { return }

        defaults.set(true, forKey: Self.completionKey)
        hasCompletedOnboarding = true
    }
}
