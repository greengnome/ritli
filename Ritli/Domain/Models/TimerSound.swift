import Foundation

enum TimerSound: String, CaseIterable, Identifiable, Sendable {
    case systemDefault
    case gentleBell
    case clearChime
    case softPulse
    case silent

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .systemDefault:
            LocalizedStringResource("settings.timer_sound.system_default", defaultValue: "System default")
        case .gentleBell:
            LocalizedStringResource("settings.timer_sound.gentle_bell", defaultValue: "Gentle bell")
        case .clearChime:
            LocalizedStringResource("settings.timer_sound.clear_chime", defaultValue: "Clear chime")
        case .softPulse:
            LocalizedStringResource("settings.timer_sound.soft_pulse", defaultValue: "Soft pulse")
        case .silent:
            LocalizedStringResource("settings.timer_sound.silent", defaultValue: "Silent")
        }
    }

    var fileName: String? {
        switch self {
        case .gentleBell: "ritli-gentle-bell.wav"
        case .clearChime: "ritli-clear-chime.wav"
        case .softPulse: "ritli-soft-pulse.wav"
        case .systemDefault, .silent: nil
        }
    }
}
