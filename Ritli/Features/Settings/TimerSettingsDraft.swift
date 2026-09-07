import Foundation

struct TimerSettingsDraft: Equatable {
    static let focusMinuteOptions = Array(stride(from: 5, through: 90, by: 5))
    static let shortBreakMinuteOptions = Array(1...30)
    static let longBreakMinuteOptions = Array(stride(from: 5, through: 60, by: 5))
    static let longBreakIntervalOptions = Array(2...8)

    var focusMinutes: Int
    var shortBreakMinutes: Int
    var longBreakMinutes: Int
    var longBreakEvery: Int
    var autoStartBreaks: Bool
    var autoStartFocus: Bool
    var soundEnabled: Bool
    var hapticsEnabled: Bool
    var notificationsEnabled: Bool
    var showTaskTitlesOnLockScreen: Bool

    init(settings: PomodoroSettings) {
        focusMinutes = Self.minutes(from: settings.focusDuration)
        shortBreakMinutes = Self.minutes(from: settings.shortBreakDuration)
        longBreakMinutes = Self.minutes(from: settings.longBreakDuration)
        longBreakEvery = settings.longBreakEvery
        autoStartBreaks = settings.autoStartBreaks
        autoStartFocus = settings.autoStartFocus
        soundEnabled = settings.soundEnabled
        hapticsEnabled = settings.hapticsEnabled
        notificationsEnabled = settings.notificationsEnabled
        showTaskTitlesOnLockScreen = settings.showTaskTitlesOnLockScreen
    }

    func apply(to settings: PomodoroSettings) {
        settings.focusDuration = Self.duration(from: focusMinutes)
        settings.shortBreakDuration = Self.duration(from: shortBreakMinutes)
        settings.longBreakDuration = Self.duration(from: longBreakMinutes)
        settings.longBreakEvery = max(1, longBreakEvery)
        settings.autoStartBreaks = autoStartBreaks
        settings.autoStartFocus = autoStartFocus
        settings.soundEnabled = soundEnabled
        settings.hapticsEnabled = hapticsEnabled
        settings.notificationsEnabled = notificationsEnabled
        settings.showTaskTitlesOnLockScreen = showTaskTitlesOnLockScreen
    }

    private static func minutes(from duration: TimeInterval) -> Int {
        max(1, Int((duration / 60).rounded()))
    }

    private static func duration(from minutes: Int) -> TimeInterval {
        TimeInterval(max(1, minutes) * 60)
    }
}
