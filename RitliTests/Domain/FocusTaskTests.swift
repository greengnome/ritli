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
}
