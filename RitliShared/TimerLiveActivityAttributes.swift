import ActivityKit
import Foundation

nonisolated struct TimerLiveActivityAttributes: ActivityAttributes, Hashable, Sendable {
    struct ContentState: Codable, Hashable, Sendable {
        enum Phase: Codable, Hashable, Sendable {
            case running(endDate: Date)
            case paused(remainingTime: TimeInterval)
        }

        let phase: Phase
        let taskTitle: String?

        var isPaused: Bool {
            if case .paused = phase {
                return true
            }

            return false
        }

        func remainingTime(at date: Date) -> TimeInterval {
            switch phase {
            case let .running(endDate):
                max(0, endDate.timeIntervalSince(date))
            case let .paused(remainingTime):
                max(0, remainingTime)
            }
        }
    }

    enum Kind: String, Codable, Hashable, Sendable {
        case focus
        case shortBreak
        case longBreak
    }

    let sessionID: UUID
    let kind: Kind
    let startedAt: Date
    let plannedDuration: TimeInterval
}
