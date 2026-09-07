import Testing
@testable import Ritli

@MainActor
struct TimerRoutineDraftTests {
    @Test("A new routine starts from app defaults")
    func startsFromDefaults() {
        let settings = PomodoroSettings(
            focusDuration: 45 * 60,
            shortBreakDuration: 10 * 60,
            longBreakDuration: 30 * 60,
            longBreakEvery: 3,
            autoStartBreaks: true,
            autoStartFocus: true
        )

        let draft = TimerRoutineDraft(routine: nil, defaults: settings)

        #expect(draft.focusMinutes == 45)
        #expect(draft.shortBreakMinutes == 10)
        #expect(draft.longBreakMinutes == 30)
        #expect(draft.longBreakEvery == 3)
        #expect(draft.autoStartBreaks)
        #expect(draft.autoStartFocus)
    }

    @Test("A routine draft normalizes and applies every timer option")
    func appliesValues() {
        let routine = TimerRoutine(name: "Old")
        let draft = TimerRoutineDraft(
            name: "  Deep Work  ",
            focusMinutes: 50,
            shortBreakMinutes: 10,
            longBreakMinutes: 30,
            longBreakEvery: 3,
            autoStartBreaks: true,
            autoStartFocus: true
        )

        draft.apply(to: routine)

        #expect(routine.name == "Deep Work")
        #expect(routine.focusDuration == 50 * 60)
        #expect(routine.shortBreakDuration == 10 * 60)
        #expect(routine.longBreakDuration == 30 * 60)
        #expect(routine.longBreakEvery == 3)
        #expect(routine.autoStartBreaks)
        #expect(routine.autoStartFocus)
    }

    @Test("A routine requires a visible name")
    func validatesName() {
        let draft = TimerRoutineDraft(name: " \n ")

        #expect(!draft.canSave)
    }
}
