import Foundation

struct TimerRoutineDraft: Equatable {
    var name: String
    var focusMinutes: Int
    var shortBreakMinutes: Int
    var longBreakMinutes: Int
    var longBreakEvery: Int
    var autoStartBreaks: Bool
    var autoStartFocus: Bool

    init(
        name: String = "",
        focusMinutes: Int = 25,
        shortBreakMinutes: Int = 5,
        longBreakMinutes: Int = 15,
        longBreakEvery: Int = 4,
        autoStartBreaks: Bool = false,
        autoStartFocus: Bool = false
    ) {
        self.name = name
        self.focusMinutes = max(1, focusMinutes)
        self.shortBreakMinutes = max(1, shortBreakMinutes)
        self.longBreakMinutes = max(1, longBreakMinutes)
        self.longBreakEvery = max(1, longBreakEvery)
        self.autoStartBreaks = autoStartBreaks
        self.autoStartFocus = autoStartFocus
    }

    init(routine: TimerRoutine?, defaults: PomodoroSettings?) {
        if let routine {
            self.init(
                name: routine.name,
                focusMinutes: Self.minutes(from: routine.focusDuration),
                shortBreakMinutes: Self.minutes(from: routine.shortBreakDuration),
                longBreakMinutes: Self.minutes(from: routine.longBreakDuration),
                longBreakEvery: routine.longBreakEvery,
                autoStartBreaks: routine.autoStartBreaks,
                autoStartFocus: routine.autoStartFocus
            )
        } else if let defaults {
            self.init(
                focusMinutes: Self.minutes(from: defaults.focusDuration),
                shortBreakMinutes: Self.minutes(from: defaults.shortBreakDuration),
                longBreakMinutes: Self.minutes(from: defaults.longBreakDuration),
                longBreakEvery: defaults.longBreakEvery,
                autoStartBreaks: defaults.autoStartBreaks,
                autoStartFocus: defaults.autoStartFocus
            )
        } else {
            self.init()
        }
    }

    var normalizedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSave: Bool {
        !normalizedName.isEmpty
    }

    func makeRoutine() -> TimerRoutine {
        TimerRoutine(
            name: normalizedName,
            focusDuration: Self.duration(from: focusMinutes),
            shortBreakDuration: Self.duration(from: shortBreakMinutes),
            longBreakDuration: Self.duration(from: longBreakMinutes),
            longBreakEvery: longBreakEvery,
            autoStartBreaks: autoStartBreaks,
            autoStartFocus: autoStartFocus
        )
    }

    func apply(to routine: TimerRoutine) {
        routine.name = normalizedName
        routine.focusDuration = Self.duration(from: focusMinutes)
        routine.shortBreakDuration = Self.duration(from: shortBreakMinutes)
        routine.longBreakDuration = Self.duration(from: longBreakMinutes)
        routine.longBreakEvery = max(1, longBreakEvery)
        routine.autoStartBreaks = autoStartBreaks
        routine.autoStartFocus = autoStartFocus
    }

    private static func minutes(from duration: TimeInterval) -> Int {
        max(1, Int((duration / 60).rounded()))
    }

    private static func duration(from minutes: Int) -> TimeInterval {
        TimeInterval(max(1, minutes) * 60)
    }
}
