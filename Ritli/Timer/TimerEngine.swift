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
    private let completionSound: any TimerCompletionSoundPlaying

    /// How a session that ran out is being reconciled.
    private enum CompletionTrigger {
        /// The app observed the end as it happened: play sound and haptics.
        case live
        /// The end happened while the app was away (relaunch or returning to
        /// the foreground): the notification already alerted the user.
        case catchUp
    }

    var remainingTime: TimeInterval {
        remainingTime(at: dateProvider.now)
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
        feedback: any TimerFeedbackPlaying,
        completionSound: (any TimerCompletionSoundPlaying)? = nil
    ) {
        self.store = store
        self.settings = settings
        self.cycleState = cycleState
        self.dateProvider = dateProvider
        self.notifications = notifications
        self.liveActivities = liveActivities
        self.feedback = feedback
        self.completionSound = completionSound ?? NoOpTimerCompletionSoundPlayer()
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

    // MARK: - Session transitions

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
            try finishCurrentSession(at: now, trigger: .live)
            return
        }

        let checkpoint = makeCheckpoint()
        session.actualActiveDuration = activeDuration(of: session, at: now)
        session.state = .paused
        session.pausedAt = now
        session.pausedRemainingTime = remaining
        session.endDate = nil
        try saveChanges(restoring: checkpoint)

        cancelNotifications(for: session)
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
        let checkpoint = makeCheckpoint()
        closePause(on: session, at: now)
        let remaining = max(0, session.pausedRemainingTime ?? 0)
        session.pausedRemainingTime = nil
        session.state = .running
        session.endDate = now.addingTimeInterval(remaining)
        try saveChanges(restoring: checkpoint)

        scheduleNotifications(for: session)
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
        let checkpoint = makeCheckpoint()
        closePause(on: session, at: now)
        session.actualActiveDuration = activeDuration(of: session, at: now)
        makeTerminal(session, state: .cancelled, at: now)
        try saveChanges(restoring: checkpoint)

        cancelNotifications(for: session)
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
        let checkpoint = makeCheckpoint()
        closePause(on: session, at: now)
        session.actualActiveDuration = activeDuration(of: session, at: now)
        makeTerminal(session, state: .skipped, at: now)
        advanceCycle(after: session)
        try saveChanges(restoring: checkpoint)

        cancelNotifications(for: session)
        synchronizeLiveActivity()
        playFeedback(.skipped)
    }

    // MARK: - Preferences

    func selectFocusTask(_ task: FocusTask?) throws {
        let previousTask = cycleState.preferredFocusTask
        cycleState.preferredFocusTask = task

        do {
            try saveChanges()
        } catch {
            cycleState.preferredFocusTask = previousTask
            throw error
        }

        // A focus that auto-starts after the current break uses this task.
        updatePendingSessionNotifications()
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

    /// How many focus sessions come before the long break in the cycle the
    /// session belongs to: the running session's frozen routine, or for an
    /// idle preview, the routine that session would use (the task's own for
    /// focus, as in `previewDuration`).
    func cycleLength(
        previewing kind: SessionKind? = nil,
        task: FocusTask? = nil
    ) -> Int {
        if kind == .focus, !hasActiveSession {
            return resolvedRoutine(for: task).longBreakEvery
        }

        return activeRoutine.longBreakEvery
    }

    func setNotificationsEnabled(_ isEnabled: Bool) throws {
        let previousValue = settings.notificationsEnabled
        settings.notificationsEnabled = isEnabled

        do {
            try saveChanges()
        } catch {
            settings.notificationsEnabled = previousValue
            throw error
        }

        updatePendingSessionNotifications()
    }

    func setTimerSound(_ sound: TimerSound) throws {
        let previousRawValue = settings.timerSoundRawValue
        let previousEnabled = settings.soundEnabled
        settings.timerSound = sound

        do {
            try saveChanges()
        } catch {
            settings.timerSoundRawValue = previousRawValue
            settings.soundEnabled = previousEnabled
            throw error
        }

        updatePendingSessionNotifications()
    }

    func setShowTaskTitlesOnLockScreen(_ isEnabled: Bool) throws {
        let previousValue = settings.showTaskTitlesOnLockScreen
        settings.showTaskTitlesOnLockScreen = isEnabled

        do {
            try saveChanges()
        } catch {
            settings.showTaskTitlesOnLockScreen = previousValue
            throw error
        }

        synchronizeLiveActivity()
    }

    /// Call after timer settings were edited and saved elsewhere, so alerts
    /// for an auto-starting next phase match the new durations and flags.
    func applySettingsChanges() {
        updatePendingSessionNotifications()
    }

    // MARK: - Lifecycle

    func restore() throws {
        currentSession = try store.fetchActiveSession()
        if clearUnavailablePreferredFocusTask() {
            try saveChanges()
        }
        guard let session = currentSession else {
            synchronizeLiveActivity()
            return
        }

        if session.state == .running, remainingTime(at: dateProvider.now) <= 0 {
            try finishCurrentSession(at: dateProvider.now, trigger: .catchUp)
            return
        }

        scheduleNotifications(for: session)
        synchronizeLiveActivity()
    }

    /// Reconciles a session that ran out. Pass `catchingUp: true` for the
    /// first check after returning to the app: the notification already
    /// alerted the user, so the completion sound and haptics are skipped.
    @discardableResult
    func refresh(catchingUp: Bool = false) throws -> Bool {
        try synchronizeCompletionIfNeeded(catchingUp ? .catchUp : .live)
    }

    /// Re-applies the current session to the Live Activity, e.g. after
    /// returning to the foreground when an earlier request could not start.
    func resynchronizeLiveActivity() {
        synchronizeLiveActivity()
    }

    /// Drops the reference to a finished session before its record is
    /// deleted, so the engine never reads a deleted model.
    func releaseFinishedSession() {
        guard let session = currentSession, session.state.isTerminal else {
            return
        }
        currentSession = nil
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

    // MARK: - Starting and finishing

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

        let checkpoint = makeCheckpoint()
        if updatesPreferredFocusTask {
            cycleState.preferredFocusTask = task
        }

        let session = beginSession(
            kind: kind,
            task: task,
            startedAt: dateProvider.now,
            id: UUID()
        )
        try saveChanges(restoring: checkpoint)

        scheduleNotifications(for: session)
        synchronizeLiveActivity()
        playFeedback(.started)
        return session
    }

    /// Creates the session and updates the cycle. The caller saves.
    private func beginSession(
        kind: SessionKind,
        task: FocusTask?,
        startedAt: Date,
        id: UUID
    ) -> FocusSession {
        resolveSkippedRecommendationIfNeeded(starting: kind)

        if kind == .focus {
            // Only a task's own routine is frozen for the cycle. Without one,
            // the cycle follows the global settings, so edits apply to the
            // next session as Settings promises.
            cycleState.routineSnapshot = task?.timerRoutine
                .map(TimerRoutineSnapshot.init(routine:))
        }

        let duration = activeRoutine.duration(for: kind)
        let session = FocusSession(
            id: id,
            kind: kind,
            startedAt: startedAt,
            plannedDuration: duration,
            endDate: startedAt.addingTimeInterval(duration),
            task: kind == .focus ? task : nil
        )

        currentSession = session
        store.insert(session)
        return session
    }

    @discardableResult
    private func synchronizeCompletionIfNeeded(
        _ trigger: CompletionTrigger = .live
    ) throws -> Bool {
        guard
            let session = currentSession,
            session.state == .running,
            remainingTime(at: dateProvider.now) <= 0
        else {
            return false
        }

        try finishCurrentSession(at: dateProvider.now, trigger: trigger)
        return true
    }

    private func finishCurrentSession(
        at date: Date,
        trigger: CompletionTrigger
    ) throws {
        guard let session = currentSession, !session.state.isTerminal else {
            return
        }

        let completedRoutine = activeRoutine
        let completionDate = session.endDate ?? date
        let checkpoint = makeCheckpoint()
        complete(session, at: date)
        try saveChanges(restoring: checkpoint)

        synchronizeLiveActivity()
        if trigger == .live {
            playFeedback(.completed)
            completionSound.playCompletion(
                id: session.id,
                sound: settings.timerSound,
                hasScheduledNotification: settings.notificationsEnabled
            )
        }

        guard let nextKind = autoStartKind(after: completedRoutine) else {
            notifications.cancelSessionEnd(id: FocusSession.followUpID(after: session.id))
            return
        }

        try startAutomatically(
            nextKind,
            after: session,
            at: completionDate,
            trigger: trigger
        )
    }

    /// Starts the next phase from the moment the previous one ended, so a
    /// break that ran while the phone was locked keeps its real timing.
    /// If that phase also ran out while the app was away, it is recorded as
    /// completed and nothing further auto-starts: alerts are only scheduled
    /// one phase ahead, and later phases must not be invented.
    private func startAutomatically(
        _ kind: SessionKind,
        after previous: FocusSession,
        at startDate: Date,
        trigger: CompletionTrigger
    ) throws {
        let now = dateProvider.now
        let checkpoint = makeCheckpoint()
        let session = beginSession(
            kind: kind,
            task: kind == .focus ? preferredFocusTaskForNextSession : nil,
            startedAt: startDate,
            id: FocusSession.followUpID(after: previous.id)
        )
        let hasElapsed = (session.endDate ?? now) <= now
        if hasElapsed {
            complete(session, at: now)
        }

        try saveChanges(restoring: checkpoint)

        if !hasElapsed {
            scheduleNotifications(for: session)
            if trigger == .live {
                playFeedback(.started)
            }
        }
        synchronizeLiveActivity()
    }

    /// Applies every model change of a natural completion. The caller saves.
    private func complete(_ session: FocusSession, at date: Date) {
        let completionDate = session.endDate ?? date
        closePause(on: session, at: date)
        session.actualActiveDuration = session.plannedDuration
        makeTerminal(session, state: .completed, at: completionDate)
        if session.kind == .focus {
            session.task?.completeIfEstimateReached()
        }
        advanceCycle(after: session)
        clearUnavailablePreferredFocusTask()
    }

    private func autoStartKind(after routine: TimerRoutineSnapshot) -> SessionKind? {
        switch cycleState.nextSuggestedKind {
        case .focus where routine.autoStartFocus:
            .focus
        case .shortBreak where routine.autoStartBreaks:
            .shortBreak
        case .longBreak where routine.autoStartBreaks:
            .longBreak
        default:
            nil
        }
    }

    /// The phase that will auto-start when `session` completes, mirroring
    /// `advanceCycle(after:)` and `autoStartKind(after:)`.
    private func plannedFollowUp(
        after session: FocusSession
    ) -> (kind: SessionKind, duration: TimeInterval)? {
        let routine = activeRoutine

        switch session.kind {
        case .focus:
            guard routine.autoStartBreaks else { return nil }
            let kind: SessionKind =
                cycleState.completedFocusesInCycle + 1 >= routine.longBreakEvery
                ? .longBreak
                : .shortBreak
            return (kind, routine.duration(for: kind))
        case .shortBreak, .longBreak:
            guard routine.autoStartFocus else { return nil }
            let focusRoutine = resolvedRoutine(for: preferredFocusTaskForNextSession)
            return (.focus, focusRoutine.duration(for: .focus))
        }
    }

    private func makeTerminal(
        _ session: FocusSession,
        state: SessionState,
        at date: Date
    ) {
        session.state = state
        session.finishedAt = date
        session.endDate = nil
        session.pausedAt = nil
        session.pausedRemainingTime = nil
    }

    // MARK: - Side effects

    /// Saves, or discards the unsaved changes so memory matches the store.
    private func saveChanges() throws {
        do {
            try store.save()
        } catch {
            store.rollback()
            throw error
        }
    }

    /// Saves a transition, or puts back everything it changed.
    /// `ModelContext.rollback()` discards an unsaved insert, but on iOS 26
    /// and earlier it leaves the changed properties of models already in
    /// memory, so the engine restores those itself.
    private func saveChanges(restoring checkpoint: Checkpoint) throws {
        do {
            try store.save()
        } catch {
            store.rollback()
            restore(checkpoint)
            throw error
        }
    }

    /// The values a single transition can change.
    private struct Checkpoint {
        struct SessionValues {
            let state: SessionState
            let finishedAt: Date?
            let endDate: Date?
            let pausedAt: Date?
            let pausedRemainingTime: TimeInterval?
            let actualActiveDuration: TimeInterval
            let totalPausedDuration: TimeInterval
            let taskCompletedAt: Date?
        }

        let currentSession: FocusSession?
        let sessionValues: SessionValues?
        let completedFocusesInCycle: Int
        let nextSuggestedKind: SessionKind
        let preferredFocusTask: FocusTask?
        let routineSnapshot: TimerRoutineSnapshot?
    }

    private func makeCheckpoint() -> Checkpoint {
        Checkpoint(
            currentSession: currentSession,
            sessionValues: currentSession.map { session in
                Checkpoint.SessionValues(
                    state: session.state,
                    finishedAt: session.finishedAt,
                    endDate: session.endDate,
                    pausedAt: session.pausedAt,
                    pausedRemainingTime: session.pausedRemainingTime,
                    actualActiveDuration: session.actualActiveDuration,
                    totalPausedDuration: session.totalPausedDuration,
                    taskCompletedAt: session.task?.completedAt
                )
            },
            completedFocusesInCycle: cycleState.completedFocusesInCycle,
            nextSuggestedKind: cycleState.nextSuggestedKind,
            preferredFocusTask: cycleState.preferredFocusTask,
            routineSnapshot: cycleState.routineSnapshot
        )
    }

    private func restore(_ checkpoint: Checkpoint) {
        currentSession = checkpoint.currentSession
        if let session = checkpoint.currentSession, let values = checkpoint.sessionValues {
            session.state = values.state
            session.finishedAt = values.finishedAt
            session.endDate = values.endDate
            session.pausedAt = values.pausedAt
            session.pausedRemainingTime = values.pausedRemainingTime
            session.actualActiveDuration = values.actualActiveDuration
            session.totalPausedDuration = values.totalPausedDuration
            session.task?.completedAt = values.taskCompletedAt
        }
        cycleState.completedFocusesInCycle = checkpoint.completedFocusesInCycle
        cycleState.nextSuggestedKind = checkpoint.nextSuggestedKind
        cycleState.preferredFocusTask = checkpoint.preferredFocusTask
        cycleState.routineSnapshot = checkpoint.routineSnapshot
    }

    private func scheduleNotifications(for session: FocusSession) {
        guard
            settings.notificationsEnabled,
            session.state == .running,
            let endDate = session.endDate,
            endDate > dateProvider.now
        else {
            return
        }

        notifications.scheduleSessionEnd(
            id: session.id,
            kind: session.kind,
            at: endDate,
            soundEnabled: settings.soundEnabled,
            sound: settings.timerSound
        )

        let followUpID = FocusSession.followUpID(after: session.id)
        if let followUp = plannedFollowUp(after: session) {
            notifications.scheduleSessionEnd(
                id: followUpID,
                kind: followUp.kind,
                at: endDate.addingTimeInterval(followUp.duration),
                soundEnabled: settings.soundEnabled,
                sound: settings.timerSound
            )
        } else {
            notifications.cancelSessionEnd(id: followUpID)
        }
    }

    private func cancelNotifications(for session: FocusSession) {
        notifications.cancelSessionEnd(id: session.id)
        notifications.cancelSessionEnd(id: FocusSession.followUpID(after: session.id))
    }

    private func updatePendingSessionNotifications() {
        guard let session = currentSession, session.state == .running else {
            return
        }

        if settings.notificationsEnabled {
            // Reusing the identifiers replaces the pending alerts.
            scheduleNotifications(for: session)
        } else {
            cancelNotifications(for: session)
        }
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

    // MARK: - Cycle

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
