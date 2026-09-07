import Foundation
import UserNotifications

@MainActor
final class LocalTimerNotificationScheduler: TimerNotificationScheduling {
    // Keep the original identifiers so pending notifications survive app updates.
    static let identifierPrefix = "swish.timer.session"

    private let center: any UserNotificationCenterClient
    private let dateProvider: any DateProviding
    private let localizationBundle: Bundle
    private let localizationLocale: Locale

    init(
        center: any UserNotificationCenterClient,
        dateProvider: any DateProviding,
        localizationBundle: Bundle = .main,
        localizationLocale: Locale = .current
    ) {
        self.center = center
        self.dateProvider = dateProvider
        self.localizationBundle = localizationBundle
        self.localizationLocale = localizationLocale
    }

    convenience init(center: any UserNotificationCenterClient) {
        self.init(
            center: center,
            dateProvider: SystemDateProvider()
        )
    }

    func scheduleSessionEnd(
        id: UUID,
        kind: SessionKind,
        at date: Date,
        soundEnabled: Bool
    ) {
        let interval = date.timeIntervalSince(dateProvider.now)
        guard interval > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = notificationTitle(for: kind)
        content.body = notificationBody(for: kind)
        content.sound = soundEnabled ? .default : nil
        content.threadIdentifier = "swish.timer"
        content.userInfo = ["sessionID": id.uuidString]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: interval,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: identifier(for: id),
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    func cancelSessionEnd(id: UUID) {
        center.removePendingNotificationRequests(
            withIdentifiers: [identifier(for: id)]
        )
    }

    private func identifier(for id: UUID) -> String {
        "\(Self.identifierPrefix).\(id.uuidString)"
    }

    private func notificationTitle(for kind: SessionKind) -> String {
        switch kind {
        case .focus:
            String(
                localized: "notification.focus.title",
                defaultValue: "Focus complete",
                bundle: localizationBundle,
                locale: localizationLocale
            )
        case .shortBreak:
            String(
                localized: "notification.short_break.title",
                defaultValue: "Break complete",
                bundle: localizationBundle,
                locale: localizationLocale
            )
        case .longBreak:
            String(
                localized: "notification.long_break.title",
                defaultValue: "Long break complete",
                bundle: localizationBundle,
                locale: localizationLocale
            )
        }
    }

    private func notificationBody(for kind: SessionKind) -> String {
        switch kind {
        case .focus:
            String(
                localized: "notification.focus.body",
                defaultValue: "Great work. Time for a break.",
                bundle: localizationBundle,
                locale: localizationLocale
            )
        case .shortBreak, .longBreak:
            String(
                localized: "notification.break.body",
                defaultValue: "Ready for another focus session?",
                bundle: localizationBundle,
                locale: localizationLocale
            )
        }
    }
}
