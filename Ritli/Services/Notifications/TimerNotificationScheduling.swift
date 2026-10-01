import Foundation

protocol TimerNotificationScheduling: AnyObject {
    func scheduleSessionEnd(
        id: UUID,
        kind: SessionKind,
        at date: Date,
        soundEnabled: Bool,
        sound: TimerSound
    )
    func cancelSessionEnd(id: UUID)
}

final class NoOpTimerNotificationScheduler: TimerNotificationScheduling {
    func scheduleSessionEnd(
        id: UUID,
        kind: SessionKind,
        at date: Date,
        soundEnabled: Bool,
        sound: TimerSound
    ) {}
    func cancelSessionEnd(id: UUID) {}
}
