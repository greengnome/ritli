import Foundation

nonisolated struct TimerLiveActivityDescriptor: Equatable, Sendable {
    let attributes: TimerLiveActivityAttributes
    let contentState: TimerLiveActivityAttributes.ContentState

    @MainActor
    init?(session: FocusSession, showTaskTitle: Bool = false) {
        let contentState: TimerLiveActivityAttributes.ContentState

        switch session.state {
        case .running:
            guard let endDate = session.endDate else { return nil }
            contentState = .init(
                phase: .running(endDate: endDate),
                taskTitle: showTaskTitle ? session.task?.title : nil
            )
        case .paused:
            contentState = .init(
                phase: .paused(
                    remainingTime: max(0, session.pausedRemainingTime ?? 0)
                ),
                taskTitle: showTaskTitle ? session.task?.title : nil
            )
        case .completed, .cancelled, .skipped:
            return nil
        }

        attributes = .init(
            sessionID: session.id,
            kind: .init(sessionKind: session.kind),
            startedAt: session.startedAt,
            plannedDuration: session.plannedDuration
        )
        self.contentState = contentState
    }
}

private extension TimerLiveActivityAttributes.Kind {
    init(sessionKind: SessionKind) {
        switch sessionKind {
        case .focus:
            self = .focus
        case .shortBreak:
            self = .shortBreak
        case .longBreak:
            self = .longBreak
        }
    }
}
