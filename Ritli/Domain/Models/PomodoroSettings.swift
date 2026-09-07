import Foundation
import SwiftData

@Model
final class PomodoroSettings {
    @Attribute(.unique) var id: UUID
    var focusDuration: TimeInterval
    var shortBreakDuration: TimeInterval
    var longBreakDuration: TimeInterval
    var longBreakEvery: Int
    var autoStartBreaks: Bool
    var autoStartFocus: Bool
    var soundEnabled: Bool
    var hapticsEnabled: Bool
    var notificationsEnabled: Bool
    var showTaskTitlesOnLockScreen: Bool = false
    var dailyGoal: Int?
    var appearanceRawValue: String = AppAppearance.system.rawValue

    init(
        id: UUID = UUID(),
        focusDuration: TimeInterval = 25 * 60,
        shortBreakDuration: TimeInterval = 5 * 60,
        longBreakDuration: TimeInterval = 15 * 60,
        longBreakEvery: Int = 4,
        autoStartBreaks: Bool = false,
        autoStartFocus: Bool = false,
        soundEnabled: Bool = true,
        hapticsEnabled: Bool = true,
        notificationsEnabled: Bool = true,
        showTaskTitlesOnLockScreen: Bool = false,
        dailyGoal: Int? = nil,
        appearance: AppAppearance = .system
    ) {
        self.id = id
        self.focusDuration = max(1, focusDuration)
        self.shortBreakDuration = max(1, shortBreakDuration)
        self.longBreakDuration = max(1, longBreakDuration)
        self.longBreakEvery = max(1, longBreakEvery)
        self.autoStartBreaks = autoStartBreaks
        self.autoStartFocus = autoStartFocus
        self.soundEnabled = soundEnabled
        self.hapticsEnabled = hapticsEnabled
        self.notificationsEnabled = notificationsEnabled
        self.showTaskTitlesOnLockScreen = showTaskTitlesOnLockScreen
        self.dailyGoal = dailyGoal.map { max(1, $0) }
        self.appearanceRawValue = appearance.rawValue
    }

    var appearance: AppAppearance {
        get { AppAppearance(rawValue: appearanceRawValue) ?? .system }
        set { appearanceRawValue = newValue.rawValue }
    }

    func duration(for kind: SessionKind) -> TimeInterval {
        switch kind {
        case .focus:
            focusDuration
        case .shortBreak:
            shortBreakDuration
        case .longBreak:
            longBreakDuration
        }
    }
}
