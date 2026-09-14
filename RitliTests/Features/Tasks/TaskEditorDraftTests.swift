import Foundation
import Testing
@testable import Ritli

struct TaskEditorDraftTests {
    @Test("A task draft normalizes user input and resolves its category")
    func makesNormalizedTask() {
        let category = FocusCategory(name: "Work", colorToken: "coral")
        let routine = TimerRoutine(name: "Writing")
        let dueDate = Date(timeIntervalSince1970: 20_000)
        let draft = TaskEditorDraft(
            title: "  Project roadmap  ",
            notes: "  First draft  ",
            categoryID: category.id,
            timerRoutineID: routine.id,
            estimatedPomodoros: 4,
            priority: .high,
            includesDueDate: true,
            dueDate: dueDate
        )

        let task = draft.makeTask(
            categories: [category],
            routines: [routine],
            sortOrder: 3
        )

        #expect(task.title == "Project roadmap")
        #expect(task.notes == "First draft")
        #expect(task.category === category)
        #expect(task.timerRoutine === routine)
        #expect(task.estimatedPomodoros == 4)
        #expect(task.priority == .high)
        #expect(task.dueDate == dueDate)
        #expect(task.sortOrder == 3)
    }

    @Test("A draft cannot save a whitespace-only title")
    func validatesTitle() {
        let draft = TaskEditorDraft(title: "  \n ")

        #expect(!draft.canSave)
    }

    @Test("Editing clears optional values when the draft disables them")
    func appliesOptionalValues() {
        let category = FocusCategory(name: "Study", colorToken: "blue")
        let routine = TimerRoutine(name: "Study cycle")
        let task = FocusTask(
            title: "Old title",
            notes: "Old notes",
            dueDate: .now,
            category: category,
            timerRoutine: routine
        )
        let draft = TaskEditorDraft(
            title: "New title",
            notes: "   ",
            estimatedPomodoros: 0,
            includesDueDate: false
        )

        draft.apply(to: task, categories: [category])

        #expect(task.title == "New title")
        #expect(task.notes == nil)
        #expect(task.category == nil)
        #expect(task.timerRoutine == nil)
        #expect(task.estimatedPomodoros == 1)
        #expect(task.dueDate == nil)
    }

    @Test("Reducing the estimate to completed progress marks a task done")
    func loweredEstimateCompletesTask() {
        let completionDate = Date(timeIntervalSince1970: 1_000)
        let task = FocusTask(title: "Write tests", estimatedPomodoros: 3)
        task.sessions = [FocusSession(
            kind: .focus, state: .completed, finishedAt: completionDate,
            plannedDuration: 60
        )]
        var draft = TaskEditorDraft(task: task)
        draft.estimatedPomodoros = 1

        draft.apply(to: task, categories: [])

        #expect(task.isCompleted)
        #expect(task.completedAt == completionDate)
    }

    @Test("Editing a manually completed task preserves its completion date")
    func editingPreservesManualCompletion() {
        let completionDate = Date(timeIntervalSince1970: 1_000)
        let task = FocusTask(title: "Already done", completedAt: completionDate)
        var draft = TaskEditorDraft(task: task)
        draft.estimatedPomodoros = 4

        draft.apply(to: task, categories: [])

        #expect(task.completedAt == completionDate)
    }
}
