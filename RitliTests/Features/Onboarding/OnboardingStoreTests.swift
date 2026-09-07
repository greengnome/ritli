import Foundation
import Testing
@testable import Ritli

@MainActor
@Suite("OnboardingStore")
struct OnboardingStoreTests {
    @Test("Completion persists across store instances")
    func completionPersists() {
        let defaults = makeDefaults()
        let store = OnboardingStore(defaults: defaults, arguments: [])

        #expect(!store.hasCompletedOnboarding)

        store.complete()

        #expect(store.hasCompletedOnboarding)
        #expect(
            OnboardingStore(defaults: defaults, arguments: [])
                .hasCompletedOnboarding
        )
    }

    @Test("UI-test launch arguments provide deterministic onboarding state")
    func launchArgumentsOverridePersistedState() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: OnboardingStore.completionKey)

        let resetStore = OnboardingStore(
            defaults: defaults,
            arguments: [OnboardingStore.resetLaunchArgument]
        )
        #expect(!resetStore.hasCompletedOnboarding)

        let skippedStore = OnboardingStore(
            defaults: defaults,
            arguments: [OnboardingStore.skipLaunchArgument]
        )
        #expect(skippedStore.hasCompletedOnboarding)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "OnboardingStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
