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
                focusMinutes: TimerDurationOptions.minutes(from: routine.focusDuration),
                shortBreakMinutes: TimerDurationOptions.minutes(from: routine.shortBreakDuration),
                longBreakMinutes: TimerDurationOptions.minutes(from: routine.longBreakDuration),
                longBreakEvery: routine.longBreakEvery,
                autoStartBreaks: routine.autoStartBreaks,
                autoStartFocus: routine.autoStartFocus
            )
        } else if let defaults {
            self.init(
                focusMinutes: TimerDurationOptions.minutes(from: defaults.focusDuration),
                shortBreakMinutes: TimerDurationOptions.minutes(from: defaults.shortBreakDuration),
                longBreakMinutes: TimerDurationOptions.minutes(from: defaults.longBreakDuration),
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
            focusDuration: TimerDurationOptions.duration(fromMinutes: focusMinutes),
            shortBreakDuration: TimerDurationOptions.duration(fromMinutes: shortBreakMinutes),
            longBreakDuration: TimerDurationOptions.duration(fromMinutes: longBreakMinutes),
            longBreakEvery: longBreakEvery,
            autoStartBreaks: autoStartBreaks,
            autoStartFocus: autoStartFocus
        )
    }

    func apply(to routine: TimerRoutine) {
        routine.name = normalizedName
        routine.focusDuration = TimerDurationOptions.duration(fromMinutes: focusMinutes)
        routine.shortBreakDuration = TimerDurationOptions.duration(fromMinutes: shortBreakMinutes)
        routine.longBreakDuration = TimerDurationOptions.duration(fromMinutes: longBreakMinutes)
        routine.longBreakEvery = max(1, longBreakEvery)
        routine.autoStartBreaks = autoStartBreaks
        routine.autoStartFocus = autoStartFocus
    }
}
