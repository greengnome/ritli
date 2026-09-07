import Foundation
@testable import Ritli

final class MutableDateProvider: DateProviding, @unchecked Sendable {
    var now: Date

    init(now: Date) {
        self.now = now
    }

    func advance(by interval: TimeInterval) {
        now = now.addingTimeInterval(interval)
    }
}

@MainActor
final class InMemoryTimerSessionStore: TimerSessionStore {
    var sessions: [FocusSession]
    private(set) var saveCount = 0

    init(sessions: [FocusSession] = []) {
        self.sessions = sessions
    }

    func insert(_ session: FocusSession) {
        sessions.append(session)
        if
            let task = session.task,
            !task.sessions.contains(where: { $0.id == session.id })
        {
            task.sessions.append(session)
        }
    }

    func fetchActiveSession() throws -> FocusSession? {
        sessions
            .sorted { $0.startedAt > $1.startedAt }
            .first { $0.state == .running || $0.state == .paused }
    }

    func save() throws {
        saveCount += 1
    }
}

final class TimerNotificationSchedulerSpy: TimerNotificationScheduling {
    struct Schedule: Equatable {
        let id: UUID
        let kind: SessionKind
        let date: Date
        let soundEnabled: Bool
    }

    private(set) var schedules: [Schedule] = []
    private(set) var cancellations: [UUID] = []

    func scheduleSessionEnd(
        id: UUID,
        kind: SessionKind,
        at date: Date,
        soundEnabled: Bool
    ) {
        schedules.append(
            Schedule(
                id: id,
                kind: kind,
                date: date,
                soundEnabled: soundEnabled
            )
        )
    }

    func cancelSessionEnd(id: UUID) {
        cancellations.append(id)
    }
}

@MainActor
final class TimerFeedbackPlayerSpy: TimerFeedbackPlaying {
    private(set) var events: [TimerFeedbackEvent] = []

    func play(_ event: TimerFeedbackEvent) {
        events.append(event)
    }
}

@MainActor
final class TimerLiveActivityCoordinatorSpy: TimerLiveActivityCoordinating {
    enum Event: Equatable {
        case active(TimerLiveActivityDescriptor)
        case ended
    }

    private(set) var events: [Event] = []

    func synchronize(with descriptor: TimerLiveActivityDescriptor?) {
        events.append(descriptor.map(Event.active) ?? .ended)
    }
}

@MainActor
struct TimerEngineHarness {
    let startDate: Date
    let clock: MutableDateProvider
    let store: InMemoryTimerSessionStore
    let notifications: TimerNotificationSchedulerSpy
    let liveActivities: TimerLiveActivityCoordinatorSpy
    let feedback: TimerFeedbackPlayerSpy
    let settings: PomodoroSettings
    let cycle: PomodoroCycleState
    let engine: TimerEngine

    init(
        startDate: Date = Date(timeIntervalSince1970: 10_000),
        settings: PomodoroSettings = PomodoroSettings(),
        cycle: PomodoroCycleState = PomodoroCycleState(),
        sessions: [FocusSession] = []
    ) {
        self.startDate = startDate
        self.clock = MutableDateProvider(now: startDate)
        self.store = InMemoryTimerSessionStore(sessions: sessions)
        self.notifications = TimerNotificationSchedulerSpy()
        self.liveActivities = TimerLiveActivityCoordinatorSpy()
        self.feedback = TimerFeedbackPlayerSpy()
        self.settings = settings
        self.cycle = cycle
        self.engine = TimerEngine(
            store: store,
            settings: settings,
            cycleState: cycle,
            dateProvider: clock,
            notifications: notifications,
            liveActivities: liveActivities,
            feedback: feedback
        )
    }
}
