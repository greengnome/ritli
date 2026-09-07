import SwiftData
import Testing
@testable import Ritli

@MainActor
struct AppModelContainerTests {
    @Test("All domain models persist in the configured schema")
    func persistsDomainGraph() throws {
        let container = try AppModelContainer.make(inMemory: true)
        let context = container.mainContext
        let category = FocusCategory(name: "Study", colorToken: "purple")
        let routine = TimerRoutine(name: "Deep work", focusDuration: 3_000)
        let task = FocusTask(
            title: "Learn Spanish",
            category: category,
            timerRoutine: routine
        )
        let session = FocusSession(
            kind: .focus,
            state: .completed,
            plannedDuration: 1_500,
            actualActiveDuration: 1_500,
            task: task
        )

        context.insert(category)
        context.insert(task)
        context.insert(routine)
        context.insert(session)
        context.insert(PomodoroSettings())
        let snapshot = TimerRoutineSnapshot(
            focusDuration: 3_000,
            shortBreakDuration: 600,
            longBreakDuration: 1_200,
            longBreakEvery: 3,
            autoStartBreaks: true,
            autoStartFocus: false
        )
        context.insert(
            PomodoroCycleState(
                preferredFocusTask: task,
                routineSnapshot: snapshot
            )
        )
        try context.save()

        #expect(try context.fetch(FetchDescriptor<FocusCategory>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<FocusTask>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<TimerRoutine>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<FocusSession>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<PomodoroSettings>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<PomodoroCycleState>()).count == 1)
        #expect(
            try context.fetch(FetchDescriptor<PomodoroCycleState>())
                .first?.preferredFocusTask === task
        )
        #expect(
            try context.fetch(FetchDescriptor<PomodoroCycleState>())
                .first?.routineSnapshot == snapshot
        )
        #expect(
            try context.fetch(FetchDescriptor<FocusTask>())
                .first?.timerRoutine === routine
        )
    }
}
