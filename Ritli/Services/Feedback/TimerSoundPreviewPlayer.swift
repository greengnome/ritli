import Foundation
import UserNotifications

@MainActor
final class TimerSoundPreviewPlayer {
    nonisolated static let notificationIdentifier = "ritli.timer.sound-preview"

    private let center = UNUserNotificationCenter.current()
    private var currentIdentifier: String?

    func play(_ sound: TimerSound) async throws {
        stop()
        guard sound != .silent else { return }

        let settings = await center.notificationSettings()
        try Task.checkCancellation()
        guard [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus),
              settings.soundSetting == .enabled
        else {
            throw PreviewError.soundsDisabled
        }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "settings.timer_sound.preview", defaultValue: "Sound preview")
        content.sound = sound.notificationSound
        let identifier = "\(Self.notificationIdentifier).\(UUID().uuidString)"
        currentIdentifier = identifier
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        try await center.add(request)
        if Task.isCancelled {
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            center.removeDeliveredNotifications(withIdentifiers: [identifier])
        }
    }

    func stop() {
        guard let identifier = currentIdentifier else { return }
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
        currentIdentifier = nil
    }

    private enum PreviewError: LocalizedError {
        case soundsDisabled

        var errorDescription: String? {
            String(
                localized: "settings.timer_sound.preview_requires_permission",
                defaultValue: "Enable notification sounds for Ritli in iPhone Settings to preview timer sounds."
            )
        }
    }
}
