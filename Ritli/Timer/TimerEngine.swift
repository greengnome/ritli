import Foundation
import Observation

enum TimerEngineError: Error, Equatable {
    case activeSessionExists
    case noActiveSession
    case invalidTransition(from: SessionState)
    case focusSessionCannotBeSkipped
}

@MainActor
@Observable
final class TimerEngine {
    private(set) var currentSession: FocusSession?
    private(set) var settings: PomodoroSettings
    private(set) var cycleState: PomodoroCycleState

    private let store: any TimerSessionStore
    private let dateProvider: any DateProviding
    private let notifications: any TimerNotificationScheduling
    private let liveActivities: any TimerLiveActivityCoordinating
    private let feedback: any TimerFeedbackPlaying

    var remainingTime: TimeInterval {
        remainingTime(at: dateProvider.now)
    }

    var progress: Double {
        guard let session = currentSession, session.plannedDuration > 0 else {
            return 0
        }

        let elapsed: TimeInterval
        switch session.state {
        case .running, .paused:
            elapsed = session.plannedDuration - remainingTime
        case .completed:
            elapsed = session.plannedDuration
        case .cancelled, .skipped:
            elapsed = session.actualActiveDuration
        }

        return min(1, max(0, elapsed / session.plannedDuration))
    }

    var hasActiveSession: Bool {
        guard let state = currentSession?.state else { return false }
        return state == .running || state == .paused
    }

    init(
        store: any TimerSessionStore,
        settings: PomodoroSettings,
        cycleState: PomodoroCycleState,
        dateProvider: any DateProviding,
        notifications: any TimerNotificationScheduling,
        liveActivities: any TimerLiveActivityCoordinating,
        feedback: any TimerFeedbackPlaying
    ) {
        self.store = store
        self.settings = settings
        self.cycleState = cycleState
        self.dateProvider = dateProvider
        self.notifications = notifications
        self.liveActivities = liveActivities
        self.feedback = feedback
    }

    convenience init(
        store: any TimerSessionStore,
        settings: PomodoroSettings,
        cycleState: PomodoroCycleState
    ) {
        self.init(
            store: store,
            settings: settings,
            cycleState: cycleState,
            dateProvider: SystemDateProvider(),
            notifications: NoOpTimerNotificationScheduler(),
            liveActivities: NoOpTimerLiveActivityCoordinator(),
            feedback: NoOpTimerFeedbackPlayer()
        )
    }

    @discardableResult
    func startFocus(task: FocusTask? = nil) throws -> FocusSession {
        try start(kind: .focus, task: task, updatesPreferredFocusTask: true)
    }

    @discardableResult
    func startShortBreak() throws -> FocusSession {
        try start(kind: .shortBreak)
    }

    @discardableResult
    func startLongBreak() throws -> FocusSession {
        try start(kind: .longBreak)
    }

    func pause() throws {
        guard try !synchronizeCompletionIfNeeded() else { return }
        guard let session = currentSession else {
            throw TimerEngineError.noActiveSession
        }
        guard session.state == .running else {
            throw TimerEngineError.invalidTransition(from: session.state)
        }

        let now = dateProvider.now
        let remaining = remainingTime(at: now)
        guard remaining > 0 else {
            try finishCurrentSession(at: now)
            return
        }

        session.actualActiveDuration = activeDuration(of: session, at: now)
        session.state = .paused
        session.pausedAt = now
        session.pausedRemainingTime = remaining
        session.endDate = nil
        notifications.cancelSessionEnd(id: session.id)
        try store.save()
        synchronizeLiveActivity()
        playFeedback(.paused)
    }

    func resume() throws {
        guard let session = currentSession else {
            throw TimerEngineError.noActiveSession
        }
        guard session.state == .paused else {
            throw TimerEngineError.invalidTransition(from: session.state)
        }

        let now = dateProvider.now
        closePause(on: session, at: now)
        let remaining = max(0, session.pausedRemainingTime ?? 0)
        session.pausedRemainingTime = nil
        session.state = .running
        session.endDate = now.addingTimeInterval(remaining)

        if let endDate = session.endDate {
            scheduleSessionEndIfEnabled(
                id: session.id,
                kind: session.kind,
                at: endDate
            )
        }
        try store.save()
        synchronizeLiveActivity()
        playFeedback(.resumed)
    }

    func cancel() throws {
        guard try !synchronizeCompletionIfNeeded() else { return }
        guard let session = currentSession else {
            throw TimerEngineError.noActiveSession
        }
        guard session.state == .running || session.state == .paused else {
            throw TimerEngineError.invalidTransition(from: session.state)
        }

        let now = dateProvider.now
        closePause(on: session, at: now)
        session.actualActiveDuration = activeDuration(of: session, at: now)
        makeTerminal(session, state: .cancelled, at: now)
        try store.save()
        synchronizeLiveActivity()
        playFeedback(.cancelled)
    }

    func skipBreak() throws {
        guard try !synchronizeCompletionIfNeeded() else { return }
        guard let session = currentSession else {
            throw TimerEngineError.noActiveSession
        }
        guard session.kind != .focus else {
            throw TimerEngineError.focusSessionCannotBeSkipped
        }
        guard session.state == .running || session.state == .paused else {
            throw TimerEngineError.invalidTransition(from: session.state)
        }

        let now = dateProvider.now
        closePause(on: session, at: now)
        session.actualActiveDuration = activeDuration(of: session, at: now)
        makeTerminal(session, state: .skipped, at: now)
        advanceCycle(after: session)
        try store.save()
        synchronizeLiveActivity()
        playFeedback(.skipped)
    }

    func resetCycle() throws {
        cycleState.reset()
        try store.save()
    }

    func selectFocusTask(_ task: FocusTask?) throws {
        let previousTask = cycleState.preferredFocusTask
        cycleState.preferredFocusTask = task

        do {
            try store.save()
        } catch {
            cycleState.preferredFocusTask = previousTask
            throw error
        }
    }

    func previewDuration(
        for kind: SessionKind,
        task: FocusTask? = nil
    ) -> TimeInterval {
        if kind == .focus {
            return resolvedRoutine(for: task).duration(for: kind)
        }

        return activeRoutine.duration(for: kind)
    }

    func setNotificationsEnabled(_ isEnabled: Bool) throws {
        let previousValue = settings.notificationsEnabled
        settings.notificationsEnabled = isEnabled

        do {
            try store.save()
        } catch {
            settings.notificationsEnabled = previousValue
            throw error
        }
    }

    func setShowTaskTitlesOnLockScreen(_ isEnabled: Bool) throws {
        let previousValue = settings.showTaskTitlesOnLockScreen
        settings.showTaskTitlesOnLockScreen = isEnabled

        do {
            try store.save()
        } catch {
            settings.showTaskTitlesOnLockScreen = previousValue
            throw error
        }

        synchronizeLiveActivity()
    }

    func restore() throws {
        currentSession = try store.fetchActiveSession()
        if clearUnavailablePreferredFocusTask() {
            try store.save()
        }
        guard let session = currentSession else {
            synchronizeLiveActivity()
            return
        }

        if session.state == .running {
            if remainingTime(at: dateProvider.now) <= 0 {
                try finishCurrentSession(at: dateProvider.now)
                return
            } else if let endDate = session.endDate {
                scheduleSessionEndIfEnabled(
                    id: session.id,
                    kind: session.kind,
                    at: endDate
                )
            }
        }

        synchronizeLiveActivity()
    }

    @discardableResult
    func refresh() throws -> Bool {
        try synchronizeCompletionIfNeeded()
    }

    func remainingTime(at date: Date) -> TimeInterval {
        guard let session = currentSession else { return 0 }

        switch session.state {
        case .running:
            guard let endDate = session.endDate else { return 0 }
            return max(0, endDate.timeIntervalSince(date))
        case .paused:
            return max(0, session.pausedRemainingTime ?? 0)
        case .completed, .cancelled, .skipped:
            return 0
        }
    }

    @discardableResult
    private func start(
        kind: SessionKind,
        task: FocusTask? = nil,
        updatesPreferredFocusTask: Bool = false
    ) throws -> FocusSession {
        try synchronizeCompletionIfNeeded()
        guard !hasActiveSession else {
            throw TimerEngineError.activeSessionExists
        }

        resolveSkippedRecommendationIfNeeded(starting: kind)

        if updatesPreferredFocusTask {
            cycleState.preferredFocusTask = task
        }

        if kind == .focus {
            cycleState.routineSnapshot = resolvedRoutine(for: task)
        } else if cycleState.routineSnapshot == nil {
            cycleState.routineSnapshot = TimerRoutineSnapshot(settings: settings)
        }

        let now = dateProvider.now
        let duration = activeRoutine.duration(for: kind)
        let session = FocusSession(
            kind: kind,
            startedAt: now,
            plannedDuration: duration,
            endDate: now.addingTimeInterval(duration),
            task: kind == .focus ? task : nil
        )

        currentSession = session
        store.insert(session)
        scheduleSessionEndIfEnabled(
            id: session.id,
            kind: kind,
            at: session.endDate!
        )
        try store.save()
        synchronizeLiveActivity()
        playFeedback(.started)
        return session
    }

    @discardableResult
    private func synchronizeCompletionIfNeeded() throws -> Bool {
        guard
            let session = currentSession,
            session.state == .running,
            remainingTime(at: dateProvider.now) <= 0
        else {
            return false
        }

        try finishCurrentSession(at: dateProvider.now)
        return true
    }

    private func finishCurrentSession(
        at date: Date,
        autoStart: Bool = true
    ) throws {
        guard let session = currentSession, !session.state.isTerminal else {
            return
        }

        let completedRoutine = activeRoutine
        let completionDate = session.endDate ?? date
        closePause(on: session, at: date)
        session.actualActiveDuration = session.plannedDuration
        makeTerminal(
            session,
            state: .completed,
            at: completionDate,
            cancelNotification: false
        )
        advanceCycle(after: session)
        clearUnavailablePreferredFocusTask()
        try store.save()
        synchronizeLiveActivity()
        playFeedback(.completed)

        guard autoStart else { return }

        switch cycleState.nextSuggestedKind {
        case .focus where completedRoutine.autoStartFocus:
            try start(kind: .focus, task: preferredFocusTaskForNextSession)
        case .shortBreak where completedRoutine.autoStartBreaks:
            try start(kind: .shortBreak)
        case .longBreak where completedRoutine.autoStartBreaks:
            try start(kind: .longBreak)
        default:
            break
        }
    }

    private func makeTerminal(
        _ session: FocusSession,
        state: SessionState,
        at date: Date,
        cancelNotification: Bool = true
    ) {
        session.state = state
        session.finishedAt = date
        session.endDate = nil
        session.pausedAt = nil
        session.pausedRemainingTime = nil
        if cancelNotification {
            notifications.cancelSessionEnd(id: session.id)
        }
    }

    private func scheduleSessionEndIfEnabled(
        id: UUID,
        kind: SessionKind,
        at date: Date
    ) {
        guard settings.notificationsEnabled else { return }
        notifications.scheduleSessionEnd(
            id: id,
            kind: kind,
            at: date,
            soundEnabled: settings.soundEnabled
        )
    }

    private func synchronizeLiveActivity() {
        liveActivities.synchronize(
            with: currentSession.flatMap {
                TimerLiveActivityDescriptor(
                    session: $0,
                    showTaskTitle: settings.showTaskTitlesOnLockScreen
                )
            }
        )
    }

    private func playFeedback(_ event: TimerFeedbackEvent) {
        guard settings.hapticsEnabled else { return }
        feedback.play(event)
    }

    private var activeRoutine: TimerRoutineSnapshot {
        cycleState.routineSnapshot ?? TimerRoutineSnapshot(settings: settings)
    }

    private func resolvedRoutine(for task: FocusTask?) -> TimerRoutineSnapshot {
        task?.timerRoutine.map(TimerRoutineSnapshot.init(routine:))
            ?? TimerRoutineSnapshot(settings: settings)
    }

    private var preferredFocusTaskForNextSession: FocusTask? {
        guard
            let task = cycleState.preferredFocusTask,
            !task.isArchived,
            !task.isCompleted,
            task.completedPomodoros < task.estimatedPomodoros
        else {
            return nil
        }

        return task
    }

    @discardableResult
    private func clearUnavailablePreferredFocusTask() -> Bool {
        guard let task = cycleState.preferredFocusTask else { return false }
        guard
            task.isArchived
                || task.isCompleted
                || task.completedPomodoros >= task.estimatedPomodoros
        else {
            return false
        }

        cycleState.preferredFocusTask = nil
        return true
    }

    private func closePause(on session: FocusSession, at date: Date) {
        guard let pausedAt = session.pausedAt else { return }
        session.totalPausedDuration += max(0, date.timeIntervalSince(pausedAt))
        session.pausedAt = nil
    }

    private func activeDuration(
        of session: FocusSession,
        at date: Date
    ) -> TimeInterval {
        let elapsed = date.timeIntervalSince(session.startedAt)
        return min(
            session.plannedDuration,
            max(0, elapsed - session.totalPausedDuration)
        )
    }

    private func advanceCycle(after session: FocusSession) {
        switch session.kind {
        case .focus where session.state == .completed:
            cycleState.completedFocusesInCycle += 1
            cycleState.nextSuggestedKind =
                cycleState.completedFocusesInCycle >= activeRoutine.longBreakEvery
                ? .longBreak
                : .shortBreak
        case .shortBreak:
            cycleState.nextSuggestedKind = .focus
        case .longBreak:
            cycleState.reset()
        default:
            break
        }
    }

    private func resolveSkippedRecommendationIfNeeded(starting kind: SessionKind) {
        guard kind == .focus else { return }

        if cycleState.nextSuggestedKind == .longBreak {
            cycleState.reset()
        } else if cycleState.nextSuggestedKind == .shortBreak {
            cycleState.nextSuggestedKind = .focus
        }
    }
}
