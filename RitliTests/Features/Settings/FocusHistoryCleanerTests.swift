import Foundation
import SwiftData
import Testing
@testable import Ritli

@MainActor
struct FocusHistoryCleanerTests {
    @Test("Clearing history removes terminal sessions and preserves app data")
    func clearsOnlyRecordedSessions() throws {
        let container = try AppModelContainer.make(inMemory: true)
        let context = container.mainContext
        let category = FocusCategory(name: "Work", colorToken: "coral")
        let task = FocusTask(title: "Write proposal", category: category)
        let settings = PomodoroSettings(focusDuration: 45 * 60)
        let cycle = PomodoroCycleState(completedFocusesInCycle: 2)
        let completed = FocusSession(
            kind: .focus,
            state: .completed,
            plannedDuration: 1_500,
            actualActiveDuration: 1_500,
            task: task
        )
        let cancelled = FocusSession(
            kind: .focus,
            state: .cancelled,
            plannedDuration: 1_500,
            actualActiveDuration: 300,
            task: task
        )
        let skippedBreak = FocusSession(
            kind: .shortBreak,
            state: .skipped,
            plannedDuration: 300
        )
        let paused = FocusSession(
            kind: .focus,
            state: .paused,
            plannedDuration: 1_500,
            pausedRemainingTime: 900,
            task: task
        )

        context.insert(category)
        context.insert(task)
        context.insert(settings)
        context.insert(cycle)
        context.insert(completed)
        context.insert(cancelled)
        context.insert(skippedBreak)
        context.insert(paused)
        try context.save()

        let deletedCount = try FocusHistoryCleaner.clearRecordedSessions(
            in: context
        )

        let remainingSessions = try context.fetch(
            FetchDescriptor<FocusSession>()
        )
        #expect(deletedCount == 3)
        #expect(remainingSessions.count == 1)
        #expect(remainingSessions.first === paused)
        #expect(task.sessions.count == 1)
        #expect(task.sessions.first === paused)
        // The task keeps its progress although the record is gone.
        #expect(task.clearedPomodoroCount == 1)
        #expect(task.completedPomodoros == 1)
        #expect(try context.fetch(FetchDescriptor<FocusTask>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<FocusCategory>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<PomodoroSettings>()).first === settings)
        #expect(try context.fetch(FetchDescriptor<PomodoroCycleState>()).first === cycle)
    }

    @Test("A task reaches its estimate after history was cleared")
    func completesTaskAcrossClearedHistory() throws {
        let container = try AppModelContainer.make(inMemory: true)
        let context = container.mainContext
        let task = FocusTask(title: "Write proposal", estimatedPomodoros: 2)
        let first = FocusSession(
            kind: .focus,
            state: .completed,
            plannedDuration: 1_500,
            actualActiveDuration: 1_500,
            task: task
        )
        context.insert(task)
        context.insert(first)
        try context.save()

        try FocusHistoryCleaner.clearRecordedSessions(in: context)
        #expect(!task.completeIfEstimateReached())

        let finish = Date(timeIntervalSince1970: 50_000)
        let second = FocusSession(
            kind: .focus,
            state: .completed,
            finishedAt: finish,
            plannedDuration: 1_500,
            actualActiveDuration: 1_500,
            task: task
        )
        context.insert(second)

        #expect(task.completeIfEstimateReached())
        #expect(task.completedAt == finish)
    }

    @Test("Clearing empty history succeeds without changes")
    func clearsEmptyHistory() throws {
        let container = try AppModelContainer.make(inMemory: true)

        let deletedCount = try FocusHistoryCleaner.clearRecordedSessions(
            in: container.mainContext
        )

        #expect(deletedCount == 0)
    }
}
