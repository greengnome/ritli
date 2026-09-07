import Foundation
import SwiftData

@Model
final class PomodoroCycleState {
    @Attribute(.unique) var id: UUID
    var completedFocusesInCycle: Int
    private var nextSuggestedKindRawValue: String
    @Relationship(deleteRule: .nullify) var preferredFocusTask: FocusTask?
    var routineFocusDuration: TimeInterval?
    var routineShortBreakDuration: TimeInterval?
    var routineLongBreakDuration: TimeInterval?
    var routineLongBreakEvery: Int?
    var routineAutoStartBreaks: Bool?
    var routineAutoStartFocus: Bool?

    var nextSuggestedKind: SessionKind {
        get { SessionKind(rawValue: nextSuggestedKindRawValue) ?? .focus }
        set { nextSuggestedKindRawValue = newValue.rawValue }
    }

    var routineSnapshot: TimerRoutineSnapshot? {
        get {
            guard
                let focusDuration = routineFocusDuration,
                let shortBreakDuration = routineShortBreakDuration,
                let longBreakDuration = routineLongBreakDuration,
                let longBreakEvery = routineLongBreakEvery,
                let autoStartBreaks = routineAutoStartBreaks,
                let autoStartFocus = routineAutoStartFocus
            else {
                return nil
            }

            return TimerRoutineSnapshot(
                focusDuration: focusDuration,
                shortBreakDuration: shortBreakDuration,
                longBreakDuration: longBreakDuration,
                longBreakEvery: longBreakEvery,
                autoStartBreaks: autoStartBreaks,
                autoStartFocus: autoStartFocus
            )
        }
        set {
            routineFocusDuration = newValue?.focusDuration
            routineShortBreakDuration = newValue?.shortBreakDuration
            routineLongBreakDuration = newValue?.longBreakDuration
            routineLongBreakEvery = newValue?.longBreakEvery
            routineAutoStartBreaks = newValue?.autoStartBreaks
            routineAutoStartFocus = newValue?.autoStartFocus
        }
    }

    init(
        id: UUID = UUID(),
        completedFocusesInCycle: Int = 0,
        nextSuggestedKind: SessionKind = .focus,
        preferredFocusTask: FocusTask? = nil,
        routineSnapshot: TimerRoutineSnapshot? = nil
    ) {
        self.id = id
        self.completedFocusesInCycle = max(0, completedFocusesInCycle)
        self.nextSuggestedKindRawValue = nextSuggestedKind.rawValue
        self.preferredFocusTask = preferredFocusTask
        self.routineFocusDuration = routineSnapshot?.focusDuration
        self.routineShortBreakDuration = routineSnapshot?.shortBreakDuration
        self.routineLongBreakDuration = routineSnapshot?.longBreakDuration
        self.routineLongBreakEvery = routineSnapshot?.longBreakEvery
        self.routineAutoStartBreaks = routineSnapshot?.autoStartBreaks
        self.routineAutoStartFocus = routineSnapshot?.autoStartFocus
    }

    func reset() {
        completedFocusesInCycle = 0
        nextSuggestedKind = .focus
        routineSnapshot = nil
    }
}
