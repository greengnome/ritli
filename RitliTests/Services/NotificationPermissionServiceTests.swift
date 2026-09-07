import Testing
import UserNotifications
@testable import Ritli

@MainActor
struct NotificationPermissionServiceTests {
    @Test("An undetermined status requests alert and sound permission")
    func requestsPermission() async throws {
        let center = UserNotificationCenterClientSpy()
        center.status = .notDetermined
        center.requestAuthorizationResult = true
        let service = NotificationPermissionService(center: center)

        let granted = try await service.requestAuthorizationIfNeeded()

        #expect(granted)
        #expect(service.authorizationStatus == .authorized)
        #expect(center.requestedAuthorizationOptions == [[.alert, .sound]])
    }

    @Test("Existing authorization never prompts again", arguments: [
        UNAuthorizationStatus.authorized,
        .provisional,
        .ephemeral,
    ])
    func acceptsExistingAuthorization(status: UNAuthorizationStatus) async throws {
        let center = UserNotificationCenterClientSpy()
        center.status = status
        let service = NotificationPermissionService(center: center)

        #expect(try await service.requestAuthorizationIfNeeded())
        #expect(service.authorizationStatus == status)
        #expect(center.requestedAuthorizationOptions.isEmpty)
    }

    @Test("A denied status returns false without prompting")
    func respectsDenial() async throws {
        let center = UserNotificationCenterClientSpy()
        center.status = .denied
        let service = NotificationPermissionService(center: center)

        #expect(try await !service.requestAuthorizationIfNeeded())
        #expect(!service.isAuthorized)
        #expect(center.requestedAuthorizationOptions.isEmpty)
    }

    @Test("Refreshing status exposes external settings changes")
    func refreshesStatus() async {
        let center = UserNotificationCenterClientSpy()
        center.status = .authorized
        let service = NotificationPermissionService(center: center)

        await service.refreshAuthorizationStatus()

        #expect(service.authorizationStatus == .authorized)
        #expect(service.isAuthorized)
    }
}
