import Foundation
import SwiftData

enum SessionKind: String, Codable, CaseIterable, Sendable {
    case focus
    case shortBreak
    case longBreak
}

enum SessionState: String, Codable, CaseIterable, Sendable {
    case running
    case paused
    case completed
    case cancelled
    case skipped

    var isTerminal: Bool {
        switch self {
        case .completed, .cancelled, .skipped:
            true
        case .running, .paused:
            false
        }
    }
}

@Model
final class FocusSession {
    @Attribute(.unique) var id: UUID
    private var kindRawValue: String
    private var stateRawValue: String
    var startedAt: Date
    var finishedAt: Date?
    var plannedDuration: TimeInterval
    var actualActiveDuration: TimeInterval
    var totalPausedDuration: TimeInterval
    var endDate: Date?
    var pausedAt: Date?
    var pausedRemainingTime: TimeInterval?
    var task: FocusTask?
    var category: FocusCategory?
    var categoryNameSnapshot: String?
    var categoryColorTokenSnapshot: String?
    var timeZoneIdentifier: String

    var kind: SessionKind {
        get { SessionKind(rawValue: kindRawValue) ?? .focus }
        set { kindRawValue = newValue.rawValue }
    }

    var state: SessionState {
        get { SessionState(rawValue: stateRawValue) ?? .cancelled }
        set { stateRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        kind: SessionKind,
        state: SessionState = .running,
        startedAt: Date = .now,
        finishedAt: Date? = nil,
        plannedDuration: TimeInterval,
        actualActiveDuration: TimeInterval = 0,
        totalPausedDuration: TimeInterval = 0,
        endDate: Date? = nil,
        pausedAt: Date? = nil,
        pausedRemainingTime: TimeInterval? = nil,
        task: FocusTask? = nil,
        category: FocusCategory? = nil,
        timeZone: TimeZone = .current
    ) {
        let resolvedCategory = category ?? task?.category

        self.id = id
        self.kindRawValue = kind.rawValue
        self.stateRawValue = state.rawValue
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.plannedDuration = max(0, plannedDuration)
        self.actualActiveDuration = max(0, actualActiveDuration)
        self.totalPausedDuration = max(0, totalPausedDuration)
        self.endDate = endDate
        self.pausedAt = pausedAt
        self.pausedRemainingTime = pausedRemainingTime
        self.task = task
        self.category = resolvedCategory
        self.categoryNameSnapshot = resolvedCategory?.name
        self.categoryColorTokenSnapshot = resolvedCategory?.colorToken
        self.timeZoneIdentifier = timeZone.identifier
    }
}
