import Foundation

@MainActor
protocol TimerLiveActivityCoordinating: AnyObject {
    func synchronize(with descriptor: TimerLiveActivityDescriptor?)
}

@MainActor
final class NoOpTimerLiveActivityCoordinator: TimerLiveActivityCoordinating {
    func synchronize(with descriptor: TimerLiveActivityDescriptor?) {}
}
