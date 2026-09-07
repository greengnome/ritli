import UIKit

enum TimerFeedbackEvent: Equatable, Sendable {
    case started
    case paused
    case resumed
    case completed
    case cancelled
    case skipped
}

@MainActor
protocol TimerFeedbackPlaying: AnyObject {
    func play(_ event: TimerFeedbackEvent)
}

@MainActor
final class SystemTimerFeedbackPlayer: TimerFeedbackPlaying {
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    init() {
        prepareGenerators()
    }

    func play(_ event: TimerFeedbackEvent) {
#if targetEnvironment(simulator)
        return
#else
        switch event {
        case .started, .resumed:
            lightImpactGenerator.prepare()
            lightImpactGenerator.impactOccurred()
        case .paused:
            mediumImpactGenerator.prepare()
            mediumImpactGenerator.impactOccurred()
        case .completed:
            notificationGenerator.prepare()
            notificationGenerator.notificationOccurred(.success)
        case .cancelled, .skipped:
            notificationGenerator.prepare()
            notificationGenerator.notificationOccurred(.warning)
        }
#endif
    }

    private func prepareGenerators() {
#if !targetEnvironment(simulator)
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        notificationGenerator.prepare()
#endif
    }
}

@MainActor
final class NoOpTimerFeedbackPlayer: TimerFeedbackPlaying {
    func play(_ event: TimerFeedbackEvent) {}
}
