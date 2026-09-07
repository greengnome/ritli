import Testing
@testable import Ritli

struct TimerRoutineTests {
    @Test("A routine normalizes its name and timer values")
    func normalizesValues() {
        let routine = TimerRoutine(
            name: "  Deep work  ",
            focusDuration: 0,
            shortBreakDuration: -1,
            longBreakDuration: 0,
            longBreakEvery: 0
        )

        #expect(routine.name == "Deep work")
        #expect(routine.focusDuration == 1)
        #expect(routine.shortBreakDuration == 1)
        #expect(routine.longBreakDuration == 1)
        #expect(routine.longBreakEvery == 1)
    }

    @Test("A snapshot preserves routine values independently")
    func snapshotIsIndependent() {
        let routine = TimerRoutine(
            name: "Writing",
            focusDuration: 3_000,
            shortBreakDuration: 600,
            longBreakDuration: 1_200,
            longBreakEvery: 3,
            autoStartBreaks: true,
            autoStartFocus: true
        )
        let snapshot = TimerRoutineSnapshot(routine: routine)

        routine.focusDuration = 1_500

        #expect(snapshot.focusDuration == 3_000)
        #expect(snapshot.duration(for: .shortBreak) == 600)
        #expect(snapshot.longBreakEvery == 3)
        #expect(snapshot.autoStartBreaks)
        #expect(snapshot.autoStartFocus)
    }
}
