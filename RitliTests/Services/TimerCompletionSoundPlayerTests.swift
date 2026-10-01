import AVFAudio
import Foundation
import Testing
@testable import Ritli

@MainActor
@Suite(.serialized)
struct TimerCompletionSoundPlayerTests {
    @Test("Real focus and break completions start their selected audio files", arguments: [
        (SessionKind.focus, TimerSound.gentleBell, "ritli-gentle-bell.wav"),
        (SessionKind.shortBreak, TimerSound.clearChime, "ritli-clear-chime.wav"),
        (SessionKind.longBreak, TimerSound.softPulse, "ritli-soft-pulse.wav"),
    ])
    func playsOnCompletion(kind: SessionKind, sound: TimerSound, fileName: String) async throws {
        let playback = TimerCompletionSoundPlayer(isApplicationActive: { true })
        defer { playback.stop() }
        let clock = MutableDateProvider(now: Date(timeIntervalSince1970: 10_000))
        let settings = PomodoroSettings(
            focusDuration: 1, shortBreakDuration: 1, longBreakDuration: 1,
            timerSound: sound, hapticsEnabled: false, notificationsEnabled: false
        )
        let engine = TimerEngine(
            store: InMemoryTimerSessionStore(), settings: settings, cycleState: PomodoroCycleState(),
            dateProvider: clock, notifications: NoOpTimerNotificationScheduler(),
            liveActivities: NoOpTimerLiveActivityCoordinator(), feedback: NoOpTimerFeedbackPlayer(),
            completionSound: playback
        )
        let session: FocusSession
        switch kind {
        case .focus: session = try engine.startFocus()
        case .shortBreak: session = try engine.startShortBreak()
        case .longBreak: session = try engine.startLongBreak()
        }
        #expect(playback.audioPlayer == nil)
        clock.advance(by: 1)
        try engine.refresh()
        await playback.playbackTask?.value
        let player = try #require(playback.audioPlayer)
        #expect(player.url?.lastPathComponent == fileName)
        #expect(player.isPlaying)
        try await Task.sleep(for: .milliseconds(100))
        #expect(player.currentTime > 0)

        // The notification delegate can arrive before or after the engine's refresh.
        #expect(playback.playCompletion(id: session.id, sound: sound, hasScheduledNotification: true))
        await playback.playbackTask?.value
        #expect(playback.audioPlayer === player)
    }

    @Test("A foreground notification and engine completion share one playback", arguments: [true, false])
    func preventsDuplicatePlayback(notificationArrivesFirst: Bool) async throws {
        let playback = TimerCompletionSoundPlayer(isApplicationActive: { true })
        defer { playback.stop() }
        let id = UUID()
        #expect(playback.playCompletion(id: id, sound: .clearChime, hasScheduledNotification: notificationArrivesFirst))
        await playback.playbackTask?.value
        let player = try #require(playback.audioPlayer)
        #expect(playback.playCompletion(id: id, sound: .clearChime, hasScheduledNotification: !notificationArrivesFirst))
        await playback.playbackTask?.value
        #expect(playback.audioPlayer === player)
        #expect(player.isPlaying)
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

    @Test("The default sound uses the already-scheduled notification once")
    func leavesScheduledSystemSoundToNotifications() {
        let playback = TimerCompletionSoundPlayer(isApplicationActive: { true })
        #expect(!playback.playCompletion(id: UUID(), sound: .systemDefault, hasScheduledNotification: true))
        #expect(playback.playbackTask == nil)
    }
}
