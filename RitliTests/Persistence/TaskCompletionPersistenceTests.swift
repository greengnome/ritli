import Foundation
import SwiftData
import Testing
@testable import Ritli

@MainActor
struct TaskCompletionPersistenceTests {
    @Test("Task and final session completion are saved together", arguments: [false, true])
    func savesCompletion(restoresOverdueTimer: Bool) throws {
        let container = try AppModelContainer.make(inMemory: true)
        let context = container.mainContext
        let task = FocusTask(title: "Proposal", estimatedPomodoros: 2)
        context.insert(task)
        context.insert(FocusSession(
            kind: .focus,
            state: .completed,
            startedAt: Date(timeIntervalSince1970: 9_000),
            finishedAt: Date(timeIntervalSince1970: 9_060),
            plannedDuration: 60,
            task: task
        ))
        let settings = PomodoroSettings(focusDuration: 60)
        let cycle = PomodoroCycleState()
        context.insert(settings)
        context.insert(cycle)
        let clock = MutableDateProvider(now: Date(timeIntervalSince1970: 10_000))
        let store = SwiftDataTimerSessionStore(context: context)
        func makeEngine() -> TimerEngine {
            TimerEngine(
                store: store,
                settings: settings,
                cycleState: cycle,
                dateProvider: clock,
                notifications: NoOpTimerNotificationScheduler(),
                liveActivities: NoOpTimerLiveActivityCoordinator(),
                feedback: NoOpTimerFeedbackPlayer()
            )
        }
        let engine = makeEngine()
        try engine.startFocus(task: task)
        #expect(task.completedPomodoros == 1)
        #expect(!task.isCompleted)

        clock.advance(by: restoresOverdueTimer ? 86_400 : 60)
        if restoresOverdueTimer {
            try makeEngine().restore()
        } else {
            try engine.refresh()
        }

        let verificationContext = ModelContext(container)
        let savedTask = try #require(verificationContext.fetch(FetchDescriptor<FocusTask>()).first)
        #expect(savedTask.completedAt == Date(timeIntervalSince1970: 10_060))
        #expect(savedTask.completedPomodoros == 2)
        #expect(savedTask.sessions.allSatisfy { $0.state == .completed })
        let savedCycle = try #require(verificationContext.fetch(FetchDescriptor<PomodoroCycleState>()).first)
        #expect(savedCycle.preferredFocusTask == nil)
    }

    @Test("Existing exhausted tasks are repaired without changing history or reopening")
    func reconcilesExistingProgress() throws {
        let container = try AppModelContainer.make(inMemory: true)
        let context = container.mainContext
        let below = FocusTask(title: "Below", estimatedPomodoros: 3)
        let reached = FocusTask(title: "Reached", estimatedPomodoros: 2)
        let exceeded = FocusTask(title: "Exceeded", estimatedPomodoros: 1)
        let manual = FocusTask(title: "Manual", estimatedPomodoros: 1)
        let manualDate = Date(timeIntervalSince1970: 500)
        manual.complete(at: manualDate)
        for task in [below, reached, exceeded, manual] {
            context.insert(task)
            for end in [100.0, 200.0] {
                context.insert(FocusSession(
                    kind: .focus,
                    state: .completed,
                    startedAt: Date(timeIntervalSince1970: end - 60),
                    finishedAt: Date(timeIntervalSince1970: end),
                    plannedDuration: 60,
                    task: task
                ))
            }
        }
        try context.save()

        try TaskCompletionReconciliation.run(in: context)
        try TaskCompletionReconciliation.run(in: context)

        let verificationContext = ModelContext(container)
        let saved = try verificationContext.fetch(FetchDescriptor<FocusTask>())
        #expect(saved.first { $0.title == "Below" }?.completedAt == nil)
        #expect(saved.first { $0.title == "Reached" }?.completedAt == Date(timeIntervalSince1970: 200))
        #expect(saved.first { $0.title == "Exceeded" }?.completedAt == Date(timeIntervalSince1970: 100))
        #expect(saved.first { $0.title == "Manual" }?.completedAt == manualDate)
        #expect(saved.allSatisfy { $0.completedPomodoros == 2 })

        let reopened = try #require(saved.first { $0.title == "Exceeded" })
        reopened.reopen()
        try verificationContext.save()
        let restartContext = ModelContext(container)
        try TaskCompletionReconciliation.run(in: restartContext)
        let afterRestart = try #require(restartContext.fetch(FetchDescriptor<FocusTask>()).first {
            $0.title == "Exceeded"
        })
        #expect(!afterRestart.isCompleted)
        #expect(afterRestart.estimatedPomodoros == 3)
        #expect(afterRestart.completedPomodoros == 2)
    }
}
