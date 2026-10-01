import UserNotifications

extension TimerSound {
    var notificationSound: UNNotificationSound? {
        switch self {
        case .systemDefault:
            .default
        case .silent:
            nil
        case .gentleBell, .clearChime, .softPulse:
            fileName.map { UNNotificationSound(named: UNNotificationSoundName($0)) }
        }
    }
}
