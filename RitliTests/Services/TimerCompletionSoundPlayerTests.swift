import Foundation
import Testing
@testable import Ritli

/// The rules that decide whether the app plays a completion sound itself.
/// Actual audio output isn't tested: simulators can't play it reliably.
@MainActor
struct TimerCompletionSoundPlayerTests {
    @Test("A session's completion sound starts once, whoever reports it first")
    func playsEachCompletionOnce() {
        let playback = TimerCompletionSoundPlayer(isApplicationActive: { true })
        defer { playback.stop() }
        let id = UUID()

        #expect(playback.playCompletion(id: id, sound: .clearChime, hasScheduledNotification: true))
        let firstPlayback = playback.playbackTask
        #expect(playback.playCompletion(id: id, sound: .clearChime, hasScheduledNotification: false))

        #expect(firstPlayback != nil)
        #expect(playback.playbackTask == firstPlayback)
    }

    @Test("Silent and background completions do not start direct audio")
    func respectsSilenceAndBackground() {
        let silent = TimerCompletionSoundPlayer(isApplicationActive: { true })
        #expect(!silent.playCompletion(id: UUID(), sound: .silent, hasScheduledNotification: false))
        #expect(silent.playbackTask == nil)

        let background = TimerCompletionSoundPlayer(isApplicationActive: { false })
        #expect(!background.playCompletion(id: UUID(), sound: .gentleBell, hasScheduledNotification: true))
        #expect(background.playbackTask == nil)
    }

    @Test("The default sound is left to the scheduled notification")
    func leavesScheduledSystemSoundToNotifications() {
        let playback = TimerCompletionSoundPlayer(isApplicationActive: { true })
        #expect(!playback.playCompletion(id: UUID(), sound: .systemDefault, hasScheduledNotification: true))
        #expect(playback.playbackTask == nil)
    }
}
