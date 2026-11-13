import CryptoKit
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
    private(set) var stateRawValue: String
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
    /// Keeps history readable after the task itself is deleted.
    var taskTitleSnapshot: String?
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
        self.taskTitleSnapshot = task?.title
        self.timeZoneIdentifier = timeZone.identifier
    }
}

extension FocusSession {
    /// The identifier reserved for the session that auto-starts after `id`.
    ///
    /// Its end notification is scheduled while `id` is still running, so the
    /// alert fires even if the app stays suspended. Reusing the identifier
    /// when that session really starts replaces the pending alert instead of
    /// duplicating it.
    nonisolated static func followUpID(after id: UUID) -> UUID {
        let digest = SHA256.hash(data: Data("\(id.uuidString).follow-up".utf8))
        var bytes = Array(digest.prefix(16))
        bytes[6] = (bytes[6] & 0x0F) | 0x50 // name-based UUID version
        bytes[8] = (bytes[8] & 0x3F) | 0x80 // RFC 4122 variant
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}
