import UIKit
import UserNotifications

@MainActor
final class AppNotificationDelegate: NSObject, UIApplicationDelegate,
    UNUserNotificationCenterDelegate {
    nonisolated static let foregroundPresentationOptions:
        UNNotificationPresentationOptions = [.banner, .sound]

    nonisolated static func presentationOptions(for identifier: String) -> UNNotificationPresentationOptions {
        identifier.hasPrefix(TimerSoundPlayer.notificationIdentifier + ".")
            ? [.sound]
            : foregroundPresentationOptions
    }

    nonisolated static func customCompletionSound(for request: UNNotificationRequest) -> (id: UUID, sound: TimerSound)? {
        guard request.identifier.hasPrefix("ritli.timer.session."),
              request.content.sound != nil,
              let idString = request.content.userInfo["sessionID"] as? String,
              let id = UUID(uuidString: idString),
              let rawSound = request.content.userInfo["timerSound"] as? String,
              let sound = TimerSound(rawValue: rawSound),
              sound.fileName != nil
        else { return nil }
        return (id, sound)
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
        if let completion = Self.customCompletionSound(for: notification.request) {
            Task { @MainActor in
                let handled = TimerCompletionSoundPlayer.shared.playCompletion(
                    id: completion.id,
                    sound: completion.sound,
                    hasScheduledNotification: true
                )
                // Custom audio is played directly; keep the banner without a second system tone.
                completionHandler(handled ? [.banner] : Self.foregroundPresentationOptions)
            }
        } else {
            completionHandler(Self.presentationOptions(for: notification.request.identifier))
        }
    }
}
