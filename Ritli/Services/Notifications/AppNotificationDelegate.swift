import UIKit
import UserNotifications

@MainActor
final class AppNotificationDelegate: NSObject, UIApplicationDelegate,
    UNUserNotificationCenterDelegate {
    nonisolated static let foregroundPresentationOptions:
        UNNotificationPresentationOptions = [.banner, .sound]

    nonisolated static func presentationOptions(for identifier: String) -> UNNotificationPresentationOptions {
        identifier.hasPrefix(TimerSoundPreviewPlayer.notificationIdentifier + ".")
            ? [.sound]
            : foregroundPresentationOptions
    }

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
        completionHandler(Self.presentationOptions(for: notification.request.identifier))
    }
}
