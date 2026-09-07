import UserNotifications
@testable import Ritli

@MainActor
final class UserNotificationCenterClientSpy: UserNotificationCenterClient {
    var status: UNAuthorizationStatus = .notDetermined
    var requestAuthorizationResult = true
    var requestAuthorizationError: Error?
    private(set) var addedRequests: [UNNotificationRequest] = []
    private(set) var removedIdentifierGroups: [[String]] = []
    private(set) var requestedAuthorizationOptions: [UNAuthorizationOptions] = []

    func add(_ request: UNNotificationRequest) {
        addedRequests.append(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedIdentifierGroups.append(identifiers)
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        status
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        requestedAuthorizationOptions.append(options)
        if let requestAuthorizationError {
            throw requestAuthorizationError
        }
        return requestAuthorizationResult
    }
}
