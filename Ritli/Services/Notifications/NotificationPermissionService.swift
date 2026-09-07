import Observation
import UserNotifications

@MainActor
@Observable
final class NotificationPermissionService {
    private(set) var authorizationStatus: UNAuthorizationStatus?

    private let center: any UserNotificationCenterClient

    init(center: any UserNotificationCenterClient) {
        self.center = center
    }

    var isAuthorized: Bool {
        guard let authorizationStatus else { return false }

        return switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            true
        case .notDetermined, .denied:
            false
        @unknown default:
            false
        }
    }

    var isDenied: Bool {
        authorizationStatus == .denied
    }

    func refreshAuthorizationStatus() async {
        authorizationStatus = await center.authorizationStatus()
    }

    @discardableResult
    func requestAuthorizationIfNeeded() async throws -> Bool {
        let currentStatus = await center.authorizationStatus()
        authorizationStatus = currentStatus

        switch currentStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            let granted = try await center.requestAuthorization(
                options: [.alert, .sound]
            )
            authorizationStatus = granted ? .authorized : .denied
            return granted
        @unknown default:
            return false
        }
    }
}
