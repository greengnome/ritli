import Foundation
import Testing
@testable import Ritli

@MainActor
struct TimerEngineCycleTests {
    @Test("Natural completion is idempotent and recommends a short break")
    func completesOnce() throws {
        let settings = PomodoroSettings(focusDuration: 60)
        let harness = TimerEngineHarness(settings: settings)
        let session = try harness.engine.startFocus()
        harness.clock.advance(by: 60)

        #expect(try harness.engine.refresh())
        #expect(session.state == .completed)
        #expect(session.finishedAt == harness.clock.now)
        #expect(session.actualActiveDuration == 60)
        #expect(harness.cycle.completedFocusesInCycle == 1)
        #expect(harness.cycle.nextSuggestedKind == .shortBreak)

        #expect(try !harness.engine.refresh())
        #expect(harness.cycle.completedFocusesInCycle == 1)
    }

    @Test("The configured focus count recommends a long break")
    func recommendsLongBreak() throws {
        let settings = PomodoroSettings(focusDuration: 60, longBreakEvery: 4)
        let cycle = PomodoroCycleState(completedFocusesInCycle: 3)
        let harness = TimerEngineHarness(settings: settings, cycle: cycle)
        try harness.engine.startFocus()
        harness.clock.advance(by: 60)

        try harness.engine.refresh()

        #expect(harness.cycle.completedFocusesInCycle == 4)
        #expect(harness.cycle.nextSuggestedKind == .longBreak)
    }

    @Test("Skipping a long break resets the Pomodoro cycle")
    func skippingLongBreakResetsCycle() throws {
        let cycle = PomodoroCycleState(
            completedFocusesInCycle: 4,
            nextSuggestedKind: .longBreak
        )
        let harness = TimerEngineHarness(cycle: cycle)
        let session = try harness.engine.startLongBreak()
        harness.clock.advance(by: 30)

        try harness.engine.skipBreak()

        #expect(session.state == .skipped)
        #expect(harness.cycle.completedFocusesInCycle == 0)
        #expect(harness.cycle.nextSuggestedKind == .focus)
    }

    @Test("Starting focus instead of the suggested long break resets the cycle")
    func focusOverrideResetsLongBreak() throws {
        let cycle = PomodoroCycleState(
            completedFocusesInCycle: 4,
            nextSuggestedKind: .longBreak
        )
        let harness = TimerEngineHarness(cycle: cycle)

        try harness.engine.startFocus()

        #expect(harness.cycle.completedFocusesInCycle == 0)
        #expect(harness.cycle.nextSuggestedKind == .focus)
    }

    @Test("Auto-start breaks creates the recommended session")
    func autoStartsBreak() throws {
        let settings = PomodoroSettings(
            focusDuration: 60,
            autoStartBreaks: true
        )
        let harness = TimerEngineHarness(settings: settings)
        try harness.engine.startFocus()
        harness.clock.advance(by: 60)

        try harness.engine.refresh()

        #expect(harness.store.sessions.count == 2)
        #expect(harness.engine.currentSession?.kind == .shortBreak)
        #expect(harness.engine.currentSession?.state == .running)
    }

    @Test("Auto-start focus creates a focus session after a break")
    func autoStartsFocus() throws {
        let settings = PomodoroSettings(
            shortBreakDuration: 60,
            autoStartFocus: true
        )
        let cycle = PomodoroCycleState(nextSuggestedKind: .shortBreak)
        let harness = TimerEngineHarness(settings: settings, cycle: cycle)
        try harness.engine.startShortBreak()
        harness.clock.advance(by: 60)

        try harness.engine.refresh()

        #expect(harness.store.sessions.count == 2)
        #expect(harness.engine.currentSession?.kind == .focus)
        #expect(harness.engine.currentSession?.state == .running)
    }

    @Test("Auto-started focus retains the selected task across a break")
    func autoStartedFocusRetainsTask() throws {
        let task = FocusTask(
            title: "Ship Ritli",
            estimatedPomodoros: 2
        )
        let settings = PomodoroSettings(
            focusDuration: 60,
            shortBreakDuration: 60,
            autoStartBreaks: true,
            autoStartFocus: true
        )
        let harness = TimerEngineHarness(settings: settings)
        try harness.engine.selectFocusTask(task)
        try harness.engine.startFocus(task: task)

        harness.clock.advance(by: 60)
        try harness.engine.refresh()
        #expect(harness.engine.currentSession?.kind == .shortBreak)

        harness.clock.advance(by: 60)
        try harness.engine.refresh()

        #expect(harness.engine.currentSession?.kind == .focus)
        #expect(harness.engine.currentSession?.task === task)
        #expect(harness.cycle.preferredFocusTask === task)
    }

    @Test("Completing a task estimate clears it before the next focus")
    func completedEstimateClearsPreferredTask() throws {
        let task = FocusTask(
            title: "Ship Ritli",
            estimatedPomodoros: 1
        )
        let settings = PomodoroSettings(
            focusDuration: 60,
            shortBreakDuration: 60,
            autoStartBreaks: true,
            autoStartFocus: true
        )
        let harness = TimerEngineHarness(settings: settings)
        try harness.engine.selectFocusTask(task)
        try harness.engine.startFocus(task: task)

        harness.clock.advance(by: 60)
        try harness.engine.refresh()

        #expect(task.completedPomodoros == 1)
        #expect(!task.isCompleted)
        #expect(harness.cycle.preferredFocusTask == nil)
        #expect(harness.engine.currentSession?.kind == .shortBreak)

        harness.clock.advance(by: 60)
        try harness.engine.refresh()

        #expect(harness.engine.currentSession?.kind == .focus)
        #expect(harness.engine.currentSession?.task == nil)
    }

    @Test("A task routine controls focus and its following break")
    func taskRoutineControlsCycleDurations() throws {
        let routine = TimerRoutine(
            name: "Writing",
            focusDuration: 60,
            shortBreakDuration: 30,
            autoStartBreaks: true
        )
        let task = FocusTask(
            title: "Write chapter",
            timerRoutine: routine,
            estimatedPomodoros: 2
        )
        let settings = PomodoroSettings(
            focusDuration: 120,
            shortBreakDuration: 90,
            autoStartBreaks: false
        )
        let harness = TimerEngineHarness(settings: settings)

        let focus = try harness.engine.startFocus(task: task)
        #expect(focus.plannedDuration == 60)

        routine.shortBreakDuration = 300
        routine.autoStartBreaks = false
        harness.clock.advance(by: 60)
        try harness.engine.refresh()

        #expect(harness.engine.currentSession?.kind == .shortBreak)
        #expect(harness.engine.currentSession?.plannedDuration == 30)
    }

    @Test("A selected task routine controls the idle focus preview")
    func taskRoutineControlsIdlePreview() {
        let task = FocusTask(
            title: "Write chapter",
            timerRoutine: TimerRoutine(
                name: "Writing",
                focusDuration: 30 * 60
            )
        )
        let harness = TimerEngineHarness(
            settings: PomodoroSettings(focusDuration: 25 * 60)
        )

        #expect(
            harness.engine.previewDuration(for: .focus, task: task)
                == 30 * 60
        )
        #expect(
            harness.engine.previewDuration(for: .focus)
                == 25 * 60
        )
    }

    @Test("Changing app defaults does not alter the active cycle")
    func appDefaultsAreSnapshottedForCycle() throws {
        let settings = PomodoroSettings(
            focusDuration: 60,
            shortBreakDuration: 30,
            autoStartBreaks: true
        )
        let harness = TimerEngineHarness(settings: settings)

        try harness.engine.startFocus()
        settings.shortBreakDuration = 300
        settings.autoStartBreaks = false
        harness.clock.advance(by: 60)
        try harness.engine.refresh()

        #expect(harness.engine.currentSession?.kind == .shortBreak)
        #expect(harness.engine.currentSession?.plannedDuration == 30)
    }

    @Test("A task routine controls long-break frequency")
    func taskRoutineControlsLongBreakFrequency() throws {
        let routine = TimerRoutine(
            name: "Fast cycle",
            focusDuration: 60,
            longBreakEvery: 2
        )
        let task = FocusTask(title: "Review", timerRoutine: routine)
        let settings = PomodoroSettings(longBreakEvery: 4)
        let cycle = PomodoroCycleState(completedFocusesInCycle: 1)
        let harness = TimerEngineHarness(settings: settings, cycle: cycle)

        try harness.engine.startFocus(task: task)
        harness.clock.advance(by: 60)
        try harness.engine.refresh()

        #expect(harness.cycle.nextSuggestedKind == .longBreak)
    }

    @Test("The next unassigned focus returns to app defaults")
    func exhaustedTaskReturnsToDefaults() throws {
        let routine = TimerRoutine(
            name: "Quick task",
            focusDuration: 60,
            shortBreakDuration: 30,
            autoStartBreaks: true,
            autoStartFocus: true
        )
        let task = FocusTask(
            title: "Reply",
            timerRoutine: routine,
            estimatedPomodoros: 1
        )
        let settings = PomodoroSettings(
            focusDuration: 120,
            shortBreakDuration: 90,
            autoStartBreaks: false,
            autoStartFocus: true
        )
        let harness = TimerEngineHarness(settings: settings)

        try harness.engine.startFocus(task: task)
        harness.clock.advance(by: 60)
        try harness.engine.refresh()

        #expect(harness.cycle.preferredFocusTask == nil)
        #expect(harness.engine.currentSession?.plannedDuration == 30)

        harness.clock.advance(by: 30)
        try harness.engine.refresh()

        #expect(harness.engine.currentSession?.kind == .focus)
        #expect(harness.engine.currentSession?.task == nil)
        #expect(harness.engine.currentSession?.plannedDuration == 120)
    }
}
