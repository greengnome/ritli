import AVFAudio
import Foundation
import Testing
@testable import Ritli

/// Both audio suites share `AVAudioSession`, so they run one test at a time
/// under this parent rather than each being serialized only internally.
@MainActor
@Suite(.serialized)
struct AudioPlaybackTests {}

extension AudioPlaybackTests {
@MainActor
@Suite
struct TimerSoundPlayerTests {
    @Test("Each custom preview starts playback of its own bundled audio", arguments: [
        (TimerSound.gentleBell, "ritli-gentle-bell.wav"),
        (TimerSound.clearChime, "ritli-clear-chime.wav"),
        (TimerSound.softPulse, "ritli-soft-pulse.wav"),
    ])
    func playsSelectedFile(sound: TimerSound, fileName: String) async throws {
        let preview = TimerSoundPlayer()
        defer { preview.stop() }

        try await preview.play(sound)
        let player = try #require(preview.audioPlayer)
        #expect(player.url?.lastPathComponent == fileName)
        // A short cue, without pinning the generated file's exact length.
        #expect(player.duration > 0.5 && player.duration < 5)
        #expect(player.isPlaying)
        #expect(await waitUntil { player.currentTime > 0 })
        let category = await Task.detached { AVAudioSession.sharedInstance().category }.value
        #expect(category == .ambient)
    }

    @Test("Switching previews stops the previous tone; Silent stops all playback")
    func switchesAndStopsPlayback() async throws {
        let preview = TimerSoundPlayer()
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
        let preview = TimerSoundPlayer()
        try await preview.play(.softPulse)
        let player = try #require(preview.audioPlayer)
        preview.stop()
        #expect(!player.isPlaying)
        #expect(preview.audioPlayer == nil)
    }

    @Test("A missing custom sound reports an error instead of playing the default tone")
    func rejectsMissingAudio() async throws {
        let preview = TimerSoundPlayer(bundle: Bundle(for: PreviewTestBundle.self))
        await #expect(throws: (any Error).self) {
            try await preview.play(.gentleBell)
        }
        #expect(preview.audioPlayer == nil)
    }

    @Test("A canceled preview cannot stop a newer sound")
    func ignoresCanceledPlayback() async throws {
        let preview = TimerSoundPlayer()
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
}

private final class PreviewTestBundle: NSObject {}
