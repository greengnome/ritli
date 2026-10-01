import AVFAudio
import Foundation
import UserNotifications

@MainActor
final class TimerSoundPlayer {
    nonisolated static let notificationIdentifier = "ritli.timer.sound-playback"

    private let center = UNUserNotificationCenter.current()
    private let bundle: Bundle
    private var currentIdentifier: String?
    private var playbackID = UUID()
    private(set) var audioPlayer: AVAudioPlayer?

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func play(
        _ sound: TimerSound,
        notificationTitle: String = String(localized: "settings.timer_sound.preview", defaultValue: "Sound preview")
    ) async throws {
        try Task.checkCancellation()
        stop()
        guard sound != .silent else { return }
        let playbackID = playbackID

        if let fileName = sound.fileName {
            guard let url = bundle.url(forResource: fileName, withExtension: nil) else {
                throw PreviewError.audioUnavailable
            }
            do {
                let player = try await Self.prepareAudioPlayer(at: url)
                try Task.checkCancellation()
                guard playbackID == self.playbackID else { return }
                guard player.play() else { throw PreviewError.audioUnavailable }
                audioPlayer = player
            } catch {
                throw PreviewError.audioUnavailable
            }
            return
        }

        // iOS exposes the user's default notification tone through notifications.
        let settings = await center.notificationSettings()
        try Task.checkCancellation()
        guard playbackID == self.playbackID else { return }
        guard [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus),
              settings.soundSetting == .enabled
        else {
            throw PreviewError.soundsDisabled
        }

        let content = UNMutableNotificationContent()
        content.title = notificationTitle
        content.sound = .default
        let identifier = "\(Self.notificationIdentifier).\(UUID().uuidString)"
        currentIdentifier = identifier
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )
        try await center.add(request)
        if Task.isCancelled || playbackID != self.playbackID {
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            center.removeDeliveredNotifications(withIdentifiers: [identifier])
        }
    }

    func stop() {
        playbackID = UUID()
        audioPlayer?.stop()
        audioPlayer = nil
        if let identifier = currentIdentifier {
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            center.removeDeliveredNotifications(withIdentifiers: [identifier])
        }
        currentIdentifier = nil
    }

    @concurrent
    private static func prepareAudioPlayer(at url: URL) async throws -> sending AVAudioPlayer {
        // Audio session setup can block, so keep it off the UI thread.
        // Ambient playback respects Silent mode and mixes with other audio.
        let session = AVAudioSession.sharedInstance()
        if session.category != .ambient {
            try session.setCategory(.ambient)
        }
        try session.setActive(true)
        let player = try AVAudioPlayer(contentsOf: url)
        guard player.prepareToPlay() else { throw PreviewError.audioUnavailable }
        return player
    }

    private enum PreviewError: LocalizedError {
        case soundsDisabled
        case audioUnavailable

        var errorDescription: String? {
            switch self {
            case .soundsDisabled:
                String(
                    localized: "settings.timer_sound.preview_requires_permission",
                    defaultValue: "Enable notification sounds for Ritli in iPhone Settings to preview the system default sound."
                )
            case .audioUnavailable:
                String(
                    localized: "settings.timer_sound.preview_unavailable",
                    defaultValue: "This sound couldn't be played. Please try again."
                )
            }
        }
    }
}
