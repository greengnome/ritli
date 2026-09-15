import Foundation
import Testing
@testable import Ritli

struct FocusTaskTests {
    @Test("Task input is normalized and estimate has a valid minimum")
    func normalizesInput() {
        let task = FocusTask(
            title: "  Project roadmap  ",
            priority: .high,
            estimatedPomodoros: 0
        )

        #expect(task.title == "Project roadmap")
        #expect(task.priority == .high)
        #expect(task.estimatedPomodoros == 1)
        #expect(!task.isCompleted)
    }

    @Test("Task completion is reversible")
    func completionLifecycle() {
        let completedAt = Date(timeIntervalSince1970: 1_000)
        let task = FocusTask(title: "Write tests")

        task.complete(at: completedAt)
        #expect(task.isCompleted)
        #expect(task.completedAt == completedAt)

        task.reopen()
        #expect(!task.isCompleted)
        #expect(task.completedAt == nil)
    }

    @Test("Pomodoro progress is derived only from completed focus sessions")
    func derivesCompletedPomodoros() {
        let task = FocusTask(title: "Implement timer", estimatedPomodoros: 4)
        task.sessions = [
            FocusSession(kind: .focus, state: .completed, plannedDuration: 1_500),
            FocusSession(kind: .focus, state: .cancelled, plannedDuration: 1_500),
            FocusSession(kind: .shortBreak, state: .completed, plannedDuration: 300),
        ]

        #expect(task.completedPomodoros == 1)
    }

    @Test("Tasks complete at or above their estimate", arguments: [0, 1, 2, 3])
    func completesAtEstimate(completedCount: Int) {
        let task = FocusTask(title: "Write tests", estimatedPomodoros: 2)
        task.sessions = (0..<completedCount).reversed().map { index in
            FocusSession(
                kind: .focus, state: .completed,
                finishedAt: Date(timeIntervalSince1970: Double(index + 1) * 100),
                plannedDuration: 60
            )
        }

        #expect(task.completeIfEstimateReached() == (completedCount >= 2))
        #expect(task.isCompleted == (completedCount >= 2))
        #expect(task.completedAt == (completedCount >= 2 ? Date(timeIntervalSince1970: 200) : nil))
        #expect(!task.completeIfEstimateReached())
    }

    @Test("Only finished focus sessions count toward automatic completion")
    func ignoresOtherSessionStatesAndBreaks() {
        let task = FocusTask(title: "Write tests")
        task.sessions = [
            FocusSession(kind: .focus, state: .running, plannedDuration: 60),
            FocusSession(kind: .focus, state: .paused, plannedDuration: 60),
            FocusSession(kind: .focus, state: .cancelled, plannedDuration: 60),
            FocusSession(kind: .focus, state: .skipped, plannedDuration: 60),
            FocusSession(kind: .shortBreak, state: .completed, plannedDuration: 60),
            FocusSession(kind: .longBreak, state: .completed, plannedDuration: 60),
        ]

        #expect(!task.completeIfEstimateReached())
        #expect(!task.isCompleted)
    }

    @Test("Reopening makes room for another session without changing actual progress", arguments: [1, 2, 24])
    func reopeningExtendsReachedEstimate(completedCount: Int) {
        let task = FocusTask(title: "More work", estimatedPomodoros: 1)
        task.sessions = (0..<completedCount).map { _ in
            FocusSession(kind: .focus, state: .completed, plannedDuration: 60)
        }
        task.complete()

        task.reopen()

        #expect(!task.isCompleted)
        #expect(task.estimatedPomodoros == completedCount + 1)
        #expect(task.completedPomodoros == completedCount)
        #expect(!task.completeIfEstimateReached())
    }

    @Test("Reopening an early completion preserves the remaining estimate")
    func reopeningPreservesRemainingEstimate() {
        let task = FocusTask(title: "More work", estimatedPomodoros: 4)
        task.sessions = [FocusSession(kind: .focus, state: .completed, plannedDuration: 60)]
        task.complete()

        task.reopen()

        #expect(task.estimatedPomodoros == 4)
        #expect(!task.isCompleted)
    }
}
