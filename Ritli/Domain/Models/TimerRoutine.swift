import Foundation
import SwiftData

struct TimerRoutineSnapshot: Equatable, Sendable {
    let focusDuration: TimeInterval
    let shortBreakDuration: TimeInterval
    let longBreakDuration: TimeInterval
    let longBreakEvery: Int
    let autoStartBreaks: Bool
    let autoStartFocus: Bool

    init(
        focusDuration: TimeInterval,
        shortBreakDuration: TimeInterval,
        longBreakDuration: TimeInterval,
        longBreakEvery: Int,
        autoStartBreaks: Bool,
        autoStartFocus: Bool
    ) {
        self.focusDuration = max(1, focusDuration)
        self.shortBreakDuration = max(1, shortBreakDuration)
        self.longBreakDuration = max(1, longBreakDuration)
        self.longBreakEvery = max(1, longBreakEvery)
        self.autoStartBreaks = autoStartBreaks
        self.autoStartFocus = autoStartFocus
    }

    init(settings: PomodoroSettings) {
        self.init(
            focusDuration: settings.focusDuration,
            shortBreakDuration: settings.shortBreakDuration,
            longBreakDuration: settings.longBreakDuration,
            longBreakEvery: settings.longBreakEvery,
            autoStartBreaks: settings.autoStartBreaks,
            autoStartFocus: settings.autoStartFocus
        )
    }

    init(routine: TimerRoutine) {
        self.init(
            focusDuration: routine.focusDuration,
            shortBreakDuration: routine.shortBreakDuration,
            longBreakDuration: routine.longBreakDuration,
            longBreakEvery: routine.longBreakEvery,
            autoStartBreaks: routine.autoStartBreaks,
            autoStartFocus: routine.autoStartFocus
        )
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

@Model
final class TimerRoutine {
    @Attribute(.unique) var id: UUID
    var name: String
    var focusDuration: TimeInterval
    var shortBreakDuration: TimeInterval
    var longBreakDuration: TimeInterval
    var longBreakEvery: Int
    var autoStartBreaks: Bool
    var autoStartFocus: Bool
    var createdAt: Date

    @Relationship(inverse: \FocusTask.timerRoutine)
    var tasks: [FocusTask]

    init(
        id: UUID = UUID(),
        name: String,
        focusDuration: TimeInterval = 25 * 60,
        shortBreakDuration: TimeInterval = 5 * 60,
        longBreakDuration: TimeInterval = 15 * 60,
        longBreakEvery: Int = 4,
        autoStartBreaks: Bool = false,
        autoStartFocus: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.focusDuration = max(1, focusDuration)
        self.shortBreakDuration = max(1, shortBreakDuration)
        self.longBreakDuration = max(1, longBreakDuration)
        self.longBreakEvery = max(1, longBreakEvery)
        self.autoStartBreaks = autoStartBreaks
        self.autoStartFocus = autoStartFocus
        self.createdAt = createdAt
        self.tasks = []
    }
}
