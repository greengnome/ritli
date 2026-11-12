import Foundation
import Testing
@testable import Ritli

/// User-driven transitions: start, pause, resume, cancel and skip.
@MainActor
struct TimerEngineTransitionTests {
    @Test("Starting focus snapshots duration, task and end date, then alerts, syncs and buzzes in order")
    func startsFocus() throws {
        let harness = TimerEngineHarness()
        let task = FocusTask(title: "Project roadmap")

        let session = try harness.engine.startFocus(task: task)

        #expect(session.state == .running)
        #expect(session.kind == .focus)
        #expect(session.task === task)
        #expect(session.taskTitleSnapshot == "Project roadmap")
        #expect(session.plannedDuration == 1_500)
        #expect(session.endDate == harness.startDate.addingTimeInterval(1_500))
        #expect(harness.store.sessions.count == 1)
        #expect(harness.cycle.preferredFocusTask === task)
        #expect(harness.notifications.pending == [
            session.id: .init(
                id: session.id,
                kind: .focus,
                date: session.endDate!,
                soundEnabled: true
            ),
        ])
        #expect(harness.liveActivities.lastDescriptor?.attributes.sessionID == session.id)
        #expect(harness.log.calls == [
            .save, .schedule(.focus), .cancelNotification, .liveActivity, .feedback(.started),
        ])
    }

    @Test("Settings edits never change a running session")
    func runningSessionKeepsItsDuration() throws {
        let harness = TimerEngineHarness()
        let session = try harness.engine.startFocus()

        harness.settings.focusDuration = 3_000
        harness.clock.advance(by: 100)

        #expect(session.plannedDuration == 1_500)
        #expect(harness.engine.remainingTime == 1_400)
    }

    @Test("Disabled notifications schedule nothing; disabled sound schedules a silent alert")
    func respectsNotificationAndSoundPreferences() throws {
        let quiet = TimerEngineHarness(settings: PomodoroSettings(notificationsEnabled: false))
        try quiet.engine.startFocus()
        #expect(quiet.notifications.schedules.isEmpty)

        let silent = TimerEngineHarness(settings: PomodoroSettings(soundEnabled: false))
        try silent.engine.startFocus()
        #expect(silent.notifications.schedules.first?.soundEnabled == false)
    }

    @Test("Pause and resume exclude paused time and move the alert")
    func pausesAndResumes() throws {
        let harness = TimerEngineHarness()
        let session = try harness.engine.startFocus()
        harness.clock.advance(by: 100)

        try harness.engine.pause()
        #expect(session.state == .paused)
        #expect(session.pausedRemainingTime == 1_400)
        #expect(session.actualActiveDuration == 100)
        #expect(harness.notifications.pending.isEmpty)
        #expect(
            harness.liveActivities.lastDescriptor?.contentState.phase
                == .paused(remainingTime: 1_400)
        )

        harness.clock.advance(by: 500)
        #expect(harness.engine.remainingTime == 1_400)

        try harness.engine.resume()
        #expect(session.state == .running)
        #expect(session.totalPausedDuration == 500)
        #expect(session.endDate == harness.clock.now.addingTimeInterval(1_400))
        #expect(harness.notifications.pending[session.id]?.date == session.endDate)
        #expect(
            harness.liveActivities.lastDescriptor?.contentState.phase
                == .running(endDate: harness.clock.now.addingTimeInterval(1_400))
        )
        #expect(harness.feedback.events == [.started, .paused, .resumed])
    }

    @Test("Cancelling records active time, excluding pauses, without advancing the cycle")
    func cancels() throws {
        let harness = TimerEngineHarness()
        let session = try harness.engine.startFocus()
        harness.clock.advance(by: 100)
        try harness.engine.pause()
        harness.clock.advance(by: 500)

        try harness.engine.cancel()

        #expect(session.state == .cancelled)
        #expect(session.finishedAt == harness.clock.now)
        #expect(session.actualActiveDuration == 100)
        #expect(session.totalPausedDuration == 500)
        #expect(harness.cycle.completedFocusesInCycle == 0)
        #expect(harness.cycle.nextSuggestedKind == .focus)
        #expect(harness.notifications.pending.isEmpty)
        #expect(harness.liveActivities.events.last == .ended)
        #expect(harness.completionSound.playbacks.isEmpty)
    }

    @Test("Skipping a break ends it and advances the cycle", arguments: [
        (SessionKind.shortBreak, 2, SessionKind.focus, 2),
        (SessionKind.longBreak, 4, SessionKind.focus, 0),
    ])
    func skipsBreak(
        kind: SessionKind,
        completedBefore: Int,
        expectedNext: SessionKind,
        expectedCompleted: Int
    ) throws {
        let harness = TimerEngineHarness(cycle: PomodoroCycleState(
            completedFocusesInCycle: completedBefore,
            nextSuggestedKind: kind
        ))
        let session = try harness.start(kind)
        harness.clock.advance(by: 30)
        try harness.engine.pause()

        try harness.engine.skipBreak()

        #expect(session.state == .skipped)
        #expect(session.actualActiveDuration == 30)
        #expect(harness.cycle.nextSuggestedKind == expectedNext)
        #expect(harness.cycle.completedFocusesInCycle == expectedCompleted)
        #expect(harness.liveActivities.events.last == .ended)
        #expect(harness.completionSound.playbacks.isEmpty)
    }

    @Test("Starting focus instead of a suggested break follows the user's choice")
    func focusOverridesSuggestedBreak() throws {
        let longBreak = TimerEngineHarness(cycle: PomodoroCycleState(
            completedFocusesInCycle: 4,
            nextSuggestedKind: .longBreak
        ))
        try longBreak.engine.startFocus()
        #expect(longBreak.cycle.completedFocusesInCycle == 0)
        #expect(longBreak.cycle.nextSuggestedKind == .focus)

        let shortBreak = TimerEngineHarness(cycle: PomodoroCycleState(
            completedFocusesInCycle: 2,
            nextSuggestedKind: .shortBreak
        ))
        try shortBreak.engine.startFocus()
        #expect(shortBreak.cycle.completedFocusesInCycle == 2)
        #expect(shortBreak.cycle.nextSuggestedKind == .focus)
    }

    @Test("Invalid commands are rejected without side effects")
    func rejectsInvalidCommands() throws {
        let harness = TimerEngineHarness()
        #expect(throws: TimerEngineError.noActiveSession) { try harness.engine.pause() }
        #expect(throws: TimerEngineError.noActiveSession) { try harness.engine.resume() }
        #expect(throws: TimerEngineError.noActiveSession) { try harness.engine.cancel() }
        #expect(throws: TimerEngineError.noActiveSession) { try harness.engine.skipBreak() }

        try harness.engine.startFocus()
        #expect(throws: TimerEngineError.activeSessionExists) {
            try harness.engine.startShortBreak()
        }
        #expect(throws: TimerEngineError.invalidTransition(from: .running)) {
            try harness.engine.resume()
        }
        #expect(throws: TimerEngineError.focusSessionCannotBeSkipped) {
            try harness.engine.skipBreak()
        }

        try harness.engine.pause()
        #expect(throws: TimerEngineError.invalidTransition(from: .paused)) {
            try harness.engine.pause()
        }

        try harness.engine.cancel()
        #expect(throws: TimerEngineError.invalidTransition(from: .cancelled)) {
            try harness.engine.cancel()
        }
        #expect(harness.store.sessions.count == 1)
    }

    @Test("A late command completes the expired session instead", arguments: [
        "pause", "cancel", "skip",
    ])
    func lateCommandCompletesExpiredSession(command: String) throws {
        let harness = TimerEngineHarness(settings: PomodoroSettings(shortBreakDuration: 60))
        let session = try harness.engine.startShortBreak()
        harness.clock.advance(by: 60)

        switch command {
        case "pause": try harness.engine.pause()
        case "cancel": try harness.engine.cancel()
        default: try harness.engine.skipBreak()
        }

        #expect(session.state == .completed)
        #expect(session.actualActiveDuration == 60)
        #expect(harness.completionSound.playbacks.map(\.id) == [session.id])
    }

    @Test("Haptic feedback follows the user preference")
    func respectsHapticPreference() throws {
        let harness = TimerEngineHarness(settings: PomodoroSettings(hapticsEnabled: false))
        try harness.engine.startFocus()
        try harness.engine.pause()
        try harness.engine.resume()
        try harness.engine.cancel()

        #expect(harness.feedback.events.isEmpty)
    }
}
