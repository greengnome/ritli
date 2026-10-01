import AVFAudio
import OSLog
import UIKit

@MainActor
protocol TimerCompletionSoundPlaying: AnyObject {
    @discardableResult
    func playCompletion(id: UUID, sound: TimerSound, hasScheduledNotification: Bool) -> Bool
}

@MainActor
final class TimerCompletionSoundPlayer: TimerCompletionSoundPlaying {
    static let shared = TimerCompletionSoundPlayer()

    private let soundPlayer: TimerSoundPlayer
    private let isApplicationActive: @MainActor () -> Bool
    private var playedSessionIDs: [UUID] = []
    private let logger = Logger(subsystem: "com.kirillgl.Ritli", category: "TimerSound")
    private(set) var playbackTask: Task<Void, Never>?

    var audioPlayer: AVAudioPlayer? { soundPlayer.audioPlayer }

    init(
        soundPlayer: TimerSoundPlayer? = nil,
        isApplicationActive: @escaping @MainActor () -> Bool = { UIApplication.shared.applicationState == .active }
    ) {
        self.soundPlayer = soundPlayer ?? TimerSoundPlayer()
        self.isApplicationActive = isApplicationActive
    }

    @discardableResult
    func playCompletion(id: UUID, sound: TimerSound, hasScheduledNotification: Bool) -> Bool {
        guard isApplicationActive(), sound != .silent else { return false }
        // The notification system plays the user's default tone when an alert is already scheduled.
        guard sound != .systemDefault || !hasScheduledNotification else { return false }
        guard !playedSessionIDs.contains(id) else { return true }
        playedSessionIDs.append(id)
        if playedSessionIDs.count > 32 { playedSessionIDs.removeFirst() }

        playbackTask?.cancel()
        playbackTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await soundPlayer.play(
                    sound,
                    notificationTitle: String(localized: "home.timer.status.complete", defaultValue: "Complete")
                )
                logger.info("Started completion sound \(sound.rawValue, privacy: .public) for session \(id.uuidString, privacy: .public)")
            } catch {
                if !Task.isCancelled {
                    logger.error("Could not play completion sound: \(error.localizedDescription, privacy: .public)")
                }
            }
        }
        return true
    }

    func stop() {
        playbackTask?.cancel()
        playbackTask = nil
        soundPlayer.stop()
    }
}

@MainActor
final class NoOpTimerCompletionSoundPlayer: TimerCompletionSoundPlaying {
    func playCompletion(id: UUID, sound: TimerSound, hasScheduledNotification: Bool) -> Bool { false }
}
