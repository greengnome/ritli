import AVFAudio
import Foundation
import Testing
@testable import Ritli

@MainActor
@Suite(.serialized)
struct TimerSoundPreviewPlayerTests {
    @Test("Each custom preview starts playback of its own bundled audio", arguments: [
        (TimerSound.gentleBell, "ritli-gentle-bell.wav", 2.0),
        (TimerSound.clearChime, "ritli-clear-chime.wav", 2.2),
        (TimerSound.softPulse, "ritli-soft-pulse.wav", 1.3),
    ])
    func playsSelectedFile(sound: TimerSound, fileName: String, duration: Double) async throws {
        let preview = TimerSoundPreviewPlayer()
        defer { preview.stop() }

        try await preview.play(sound)
        let player = try #require(preview.audioPlayer)
        #expect(player.url?.lastPathComponent == fileName)
        #expect(abs(player.duration - duration) < 0.01)
        #expect(player.isPlaying)
        try await Task.sleep(for: .milliseconds(100))
        #expect(player.currentTime > 0)
        let category = await Task.detached { AVAudioSession.sharedInstance().category }.value
        #expect(category == .ambient)
    }

    @Test("Switching previews stops the previous tone; Silent stops all playback")
    func switchesAndStopsPlayback() async throws {
        let preview = TimerSoundPreviewPlayer()
        defer { preview.stop() }

        try await preview.play(.gentleBell)
        let bell = try #require(preview.audioPlayer)
        try await preview.play(.clearChime)
        let chime = try #require(preview.audioPlayer)
        #expect(!bell.isPlaying)
        #expect(chime.isPlaying)

        try await preview.play(.silent)
        #expect(!chime.isPlaying)
        #expect(preview.audioPlayer == nil)
    }

    @Test("Leaving the picker stops playback")
    func stopsPlayback() async throws {
        let preview = TimerSoundPreviewPlayer()
        try await preview.play(.softPulse)
        let player = try #require(preview.audioPlayer)
        preview.stop()
        #expect(!player.isPlaying)
        #expect(preview.audioPlayer == nil)
    }

    @Test("A missing custom sound reports an error instead of playing the default tone")
    func rejectsMissingAudio() async throws {
        let preview = TimerSoundPreviewPlayer(bundle: Bundle(for: PreviewTestBundle.self))
        await #expect(throws: (any Error).self) {
            try await preview.play(.gentleBell)
        }
        #expect(preview.audioPlayer == nil)
    }

    @Test("A canceled preview cannot stop a newer sound")
    func ignoresCanceledPlayback() async throws {
        let preview = TimerSoundPreviewPlayer()
        defer { preview.stop() }
        try await preview.play(.softPulse)
        let player = try #require(preview.audioPlayer)

        let canceledPreview = Task { try await preview.play(.gentleBell) }
        canceledPreview.cancel()
        await #expect(throws: CancellationError.self) {
            try await canceledPreview.value
        }
        #expect(player.isPlaying)
        #expect(preview.audioPlayer === player)
    }
}

private final class PreviewTestBundle: NSObject {}
