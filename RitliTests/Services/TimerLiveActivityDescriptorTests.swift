import Foundation
import Testing
@testable import Ritli

@MainActor
struct TimerLiveActivityDescriptorTests {
    @Test("A running focus session maps immutable and countdown data")
    func mapsRunningFocusSession() throws {
        let id = UUID()
        let startedAt = Date(timeIntervalSince1970: 1_000)
        let endDate = Date(timeIntervalSince1970: 2_500)
        let task = FocusTask(title: "Prepare release")
        let session = FocusSession(
            id: id,
            kind: .focus,
            startedAt: startedAt,
            plannedDuration: 1_500,
            endDate: endDate,
            task: task
        )

        let descriptor = try #require(
            TimerLiveActivityDescriptor(
                session: session,
                showTaskTitle: true
            )
        )

        #expect(descriptor.attributes.sessionID == id)
        #expect(descriptor.attributes.kind == .focus)
        #expect(descriptor.attributes.startedAt == startedAt)
        #expect(descriptor.attributes.plannedDuration == 1_500)
        #expect(descriptor.contentState.taskTitle == "Prepare release")
        #expect(descriptor.contentState.phase == .running(endDate: endDate))
    }

    @Test("Task titles are private by default")
    func redactsTaskTitleByDefault() throws {
        let session = FocusSession(
            kind: .focus,
            plannedDuration: 1_500,
            endDate: Date(timeIntervalSince1970: 2_500),
            task: FocusTask(title: "Confidential plan")
        )

        let descriptor = try #require(
            TimerLiveActivityDescriptor(session: session)
        )

        #expect(descriptor.contentState.taskTitle == nil)
    }

    @Test("A paused session maps frozen remaining time and no task")
    func mapsPausedSession() throws {
        let session = FocusSession(
            kind: .shortBreak,
            state: .paused,
            plannedDuration: 300,
            pausedRemainingTime: 125
        )

        let descriptor = try #require(TimerLiveActivityDescriptor(session: session))

        #expect(descriptor.contentState.taskTitle == nil)
        #expect(descriptor.contentState.phase == .paused(remainingTime: 125))
    }

    @Test("Terminal sessions cannot produce Live Activity content", arguments: [
        SessionState.completed,
        SessionState.cancelled,
        SessionState.skipped,
    ])
    func rejectsTerminalSession(state: SessionState) {
        let session = FocusSession(
            kind: .focus,
            state: state,
            plannedDuration: 1_500
        )

        #expect(TimerLiveActivityDescriptor(session: session) == nil)
    }
}
