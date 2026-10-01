import AVFAudio
import Foundation
import SwiftData
import Testing
@testable import Ritli

@MainActor
struct TimerSoundTests {
    @Test("Existing on/off preferences resolve to system default or silent")
    func preservesLegacyPreferences() {
        #expect(PomodoroSettings().timerSound == .systemDefault)
        #expect(PomodoroSettings(soundEnabled: false).timerSound == .silent)
    }

    @Test("An unrecognized stored sound falls back to system default")
    func handlesUnknownSound() {
        let settings = PomodoroSettings()
        settings.timerSoundRawValue = "a-future-sound"
        #expect(settings.timerSound == .systemDefault)
        settings.soundEnabled = false
        #expect(settings.timerSound == .silent)
    }

    @Test("Custom tone resources are bundled, readable PCM audio shorter than thirty seconds", arguments: [
        TimerSound.gentleBell, .clearChime, .softPulse,
    ])
    func includesValidAudio(sound: TimerSound) throws {
        let fileName = try #require(sound.fileName)
        let url = try #require(Bundle.main.url(forResource: fileName, withExtension: nil))
        let audio = try AVAudioFile(forReading: url)
        let duration = Double(audio.length) / audio.fileFormat.sampleRate

        #expect(duration > 0)
        #expect(duration < 30)
        #expect(audio.fileFormat.channelCount == 1)
        #expect(audio.fileFormat.streamDescription.pointee.mFormatID == kAudioFormatLinearPCM)
    }

    @Test("The selected sound persists alongside other timer preferences")
    func persistsSelection() throws {
        let container = try AppModelContainer.make(inMemory: true)
        let settings = PomodoroSettings(timerSound: .softPulse)
        container.mainContext.insert(settings)
        try container.mainContext.save()

        let verificationContext = ModelContext(container)
        let saved = try #require(verificationContext.fetch(FetchDescriptor<PomodoroSettings>()).first)
        #expect(saved.timerSound == .softPulse)
        #expect(saved.focusDuration == 1_500)
        #expect(saved.soundEnabled)
    }
}
