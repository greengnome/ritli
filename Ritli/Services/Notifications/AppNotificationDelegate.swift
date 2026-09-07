import UIKit
import UserNotifications

@MainActor
final class AppNotificationDelegate: NSObject, UIApplicationDelegate,
    UNUserNotificationCenterDelegate {
    nonisolated static let foregroundPresentationOptions:
        UNNotificationPresentationOptions = [.banner, .sound]

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler(Self.foregroundPresentationOptions)
    }
}
