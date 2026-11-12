import Foundation
import SwiftData
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

/// One ordered record of every collaborator call, so tests can assert the
/// engine's documented order: save → notifications → Live Activity → feedback.
@MainActor
final class TimerCallLog {
    enum Call: Equatable {
        case save
        case saveFailed
        case rollback
        case schedule(SessionKind)
        case cancelNotification
        case liveActivity
        case feedback(TimerFeedbackEvent)
        case sound
    }

    private(set) var calls: [Call] = []

    func record(_ call: Call) {
        calls.append(call)
    }

    func reset() {
        calls.removeAll()
    }
}

@MainActor
final class InMemoryTimerSessionStore: TimerSessionStore {
    var sessions: [FocusSession]
    private(set) var saveCount = 0
    private(set) var rollbackCount = 0
    var saveError: Error?
    var log: TimerCallLog?
    private var unsavedInsertions: [FocusSession] = []

    init(sessions: [FocusSession] = []) {
        self.sessions = sessions
    }

    func insert(_ session: FocusSession) {
        sessions.append(session)
        unsavedInsertions.append(session)
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
        if let saveError {
            log?.record(.saveFailed)
            throw saveError
        }
        saveCount += 1
        unsavedInsertions.removeAll()
        log?.record(.save)
    }

    /// Drops unsaved insertions. Property changes on plain model objects
    /// can't be reverted here; `SwiftDataTimerHarness` covers that.
    func rollback() {
        rollbackCount += 1
        log?.record(.rollback)
        let discarded = Set(unsavedInsertions.map(\.id))
        sessions.removeAll { discarded.contains($0.id) }
        for session in unsavedInsertions {
            session.task?.sessions.removeAll { $0.id == session.id }
        }
        unsavedInsertions.removeAll()
    }
}

@MainActor
final class TimerNotificationSchedulerSpy: TimerNotificationScheduling {
    struct Schedule: Equatable {
        let id: UUID
        let kind: SessionKind
        let date: Date
        let soundEnabled: Bool
        var sound: TimerSound = .systemDefault
    }

    private(set) var schedules: [Schedule] = []
    private(set) var cancellations: [UUID] = []
    /// What the system would hold: scheduling an identifier again replaces
    /// its request, and cancelling removes it.
    private(set) var pending: [UUID: Schedule] = [:]
    var log: TimerCallLog?

    func scheduleSessionEnd(
        id: UUID,
        kind: SessionKind,
        at date: Date,
        soundEnabled: Bool,
        sound: TimerSound
    ) {
        let schedule = Schedule(
            id: id,
            kind: kind,
            date: date,
            soundEnabled: soundEnabled,
            sound: sound
        )
        schedules.append(schedule)
        pending[id] = schedule
        log?.record(.schedule(kind))
    }

    func cancelSessionEnd(id: UUID) {
        cancellations.append(id)
        pending[id] = nil
        log?.record(.cancelNotification)
    }
}

@MainActor
final class TimerFeedbackPlayerSpy: TimerFeedbackPlaying {
    private(set) var events: [TimerFeedbackEvent] = []
    var log: TimerCallLog?

    func play(_ event: TimerFeedbackEvent) {
        events.append(event)
        log?.record(.feedback(event))
    }
}

@MainActor
final class TimerLiveActivityCoordinatorSpy: TimerLiveActivityCoordinating {
    enum Event: Equatable {
        case active(TimerLiveActivityDescriptor)
        case ended
    }

    private(set) var events: [Event] = []
    var log: TimerCallLog?

    var lastDescriptor: TimerLiveActivityDescriptor? {
        guard case let .active(descriptor) = events.last else { return nil }
        return descriptor
    }

    func synchronize(with descriptor: TimerLiveActivityDescriptor?) {
        events.append(descriptor.map(Event.active) ?? .ended)
        log?.record(.liveActivity)
    }
}

@MainActor
final class TimerCompletionSoundPlayerSpy: TimerCompletionSoundPlaying {
    struct Playback: Equatable {
        let id: UUID
        let sound: TimerSound
        let hasScheduledNotification: Bool
    }

    private(set) var playbacks: [Playback] = []
    var log: TimerCallLog?

    @discardableResult
    func playCompletion(id: UUID, sound: TimerSound, hasScheduledNotification: Bool) -> Bool {
        playbacks.append(.init(id: id, sound: sound, hasScheduledNotification: hasScheduledNotification))
        log?.record(.sound)
        return true
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
    let completionSound: TimerCompletionSoundPlayerSpy
    let log: TimerCallLog
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
        self.completionSound = TimerCompletionSoundPlayerSpy()
        self.log = TimerCallLog()
        self.settings = settings
        self.cycle = cycle
        store.log = log
        notifications.log = log
        liveActivities.log = log
        feedback.log = log
        completionSound.log = log
        self.engine = TimerEngine(
            store: store,
            settings: settings,
            cycleState: cycle,
            dateProvider: clock,
            notifications: notifications,
            liveActivities: liveActivities,
            feedback: feedback,
            completionSound: completionSound
        )
    }

    @discardableResult
    func start(_ kind: SessionKind, task: FocusTask? = nil) throws -> FocusSession {
        switch kind {
        case .focus:
            return try engine.startFocus(task: task)
        case .shortBreak:
            return try engine.startShortBreak()
        case .longBreak:
            return try engine.startLongBreak()
        }
    }

    /// Lets the current session run out and observes it live.
    func completeCurrent() throws {
        clock.advance(by: engine.remainingTime)
        try engine.refresh()
    }
}

/// An engine backed by a real in-memory SwiftData context, for behaviour the
/// plain fake can't model, such as rolling back changes after a failed save.
@MainActor
struct SwiftDataTimerHarness {
    @MainActor
    final class Store: TimerSessionStore {
        let context: ModelContext
        /// How many upcoming saves throw before saving works again.
        var failingSaves = 0
        var failsNextSave: Bool {
            get { failingSaves > 0 }
            set { failingSaves = newValue ? 1 : 0 }
        }

        init(context: ModelContext) {
            self.context = context
        }

        func insert(_ session: FocusSession) {
            context.insert(session)
        }

        func fetchActiveSession() throws -> FocusSession? {
            try SwiftDataTimerSessionStore(context: context).fetchActiveSession()
        }

        func save() throws {
            if failingSaves > 0 {
                failingSaves -= 1
                throw CocoaError(.fileWriteUnknown)
            }
            try context.save()
        }

        func rollback() {
            context.rollback()
        }
    }

    let container: ModelContainer
    let clock: MutableDateProvider
    let store: Store
    let notifications = TimerNotificationSchedulerSpy()
    let liveActivities = TimerLiveActivityCoordinatorSpy()
    let settings: PomodoroSettings
    let cycle: PomodoroCycleState
    let engine: TimerEngine

    init(
        startDate: Date = Date(timeIntervalSince1970: 10_000),
        settings: PomodoroSettings = PomodoroSettings()
    ) throws {
        container = try AppModelContainer.make(inMemory: true)
        let context = container.mainContext
        clock = MutableDateProvider(now: startDate)
        store = Store(context: context)
        self.settings = settings
        cycle = PomodoroCycleState()
        context.insert(settings)
        context.insert(cycle)
        try context.save()
        engine = TimerEngine(
            store: store,
            settings: settings,
            cycleState: cycle,
            dateProvider: clock,
            notifications: notifications,
            liveActivities: liveActivities,
            feedback: NoOpTimerFeedbackPlayer()
        )
    }

    func sessions() throws -> [FocusSession] {
        try store.context.fetch(FetchDescriptor<FocusSession>())
    }
}
