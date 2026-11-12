import Foundation
import Testing
import UserNotifications
@testable import Ritli

@MainActor
struct TimerNotificationPreferenceTests {
    private func make(
        status: UNAuthorizationStatus,
        granted: Bool = true,
        notificationsEnabled: Bool = true
    ) -> (UserNotificationCenterClientSpy, NotificationPermissionService, TimerEngineHarness) {
        let center = UserNotificationCenterClientSpy()
        center.status = status
        center.requestAuthorizationResult = granted
        let harness = TimerEngineHarness(
            settings: PomodoroSettings(notificationsEnabled: notificationsEnabled)
        )
        return (center, NotificationPermissionService(center: center), harness)
    }

    @Test("Starting a timer asks once and keeps notifications on when granted")
    func grantedPermission() async throws {
        let (center, permissions, harness) = make(status: .notDetermined, granted: true)

        let readiness = try await TimerNotificationPreference.prepareForTimerStart(
            permissions: permissions,
            engine: harness.engine
        )

        #expect(readiness == .ready)
        #expect(center.requestedAuthorizationOptions == [[.alert, .sound]])
        #expect(harness.settings.notificationsEnabled)
    }

    @Test("A declined or revoked permission turns notifications off", arguments: [
        UNAuthorizationStatus.notDetermined, .denied,
    ])
    func deniedPermission(status: UNAuthorizationStatus) async throws {
        let (_, permissions, harness) = make(status: status, granted: false)

        let readiness = try await TimerNotificationPreference.prepareForTimerStart(
            permissions: permissions,
            engine: harness.engine
        )

        #expect(readiness == .permissionDenied)
        #expect(!harness.settings.notificationsEnabled)
    }

    @Test("Nothing is asked when notifications are already off in the app")
    func skipsWhenDisabled() async throws {
        let (center, permissions, harness) = make(status: .notDetermined, notificationsEnabled: false)

        let readiness = try await TimerNotificationPreference.prepareForTimerStart(
            permissions: permissions,
            engine: harness.engine
        )

        #expect(readiness == .ready)
        #expect(center.requestedAuthorizationOptions.isEmpty)
    }

    @Test("A failed request turns notifications off and reports the error")
    func failedRequest() async {
        let (center, permissions, harness) = make(status: .notDetermined)
        center.requestAuthorizationError = CocoaError(.featureUnsupported)

        await #expect(throws: CocoaError.self) {
            try await TimerNotificationPreference.prepareForTimerStart(
                permissions: permissions,
                engine: harness.engine
            )
        }
        #expect(!harness.settings.notificationsEnabled)
    }

    @Test("Returning to the app turns notifications off only when permission was revoked", arguments: [
        (UNAuthorizationStatus.denied, false),
        (.authorized, true),
        (.notDetermined, true),
    ])
    func synchronizesOnReturn(status: UNAuthorizationStatus, expectedEnabled: Bool) async throws {
        let (_, permissions, harness) = make(status: status)

        try await TimerNotificationPreference.disableIfDenied(
            permissions: permissions,
            engine: harness.engine
        )

        #expect(harness.settings.notificationsEnabled == expectedEnabled)
    }
}
