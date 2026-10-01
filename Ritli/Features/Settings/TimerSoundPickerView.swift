import SwiftUI

struct TimerSoundPickerView: View {
    @Environment(\.scenePhase) private var scenePhase
    let selectedSound: TimerSound
    let onSelect: (TimerSound) throws -> Void

    @State private var previewPlayer = TimerSoundPlayer()
    @State private var previewTask: Task<Void, Never>?
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                ForEach(TimerSound.allCases) { sound in
                    HStack(spacing: 16) {
                        Button {
                            do {
                                try onSelect(sound)
                                if sound == .silent { stopPreview() }
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: sound == selectedSound ? "checkmark" : "circle")
                                    .foregroundStyle(sound == selectedSound ? RitliTheme.accent : .secondary)
                                    .accessibilityHidden(true)
                                Text(sound.title)
                                    .foregroundStyle(.primary)
                                Spacer(minLength: 0)
                            }
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("settings.timerSound.\(sound.rawValue)")
                        .accessibilityAddTraits(sound == selectedSound ? [.isSelected] : [])

                        if sound != .silent {
                            Button {
                                stopPreview()
                                previewTask = Task { @MainActor in
                                    do {
                                        try await previewPlayer.play(sound)
                                    } catch {
                                        if !Task.isCancelled { errorMessage = error.localizedDescription }
                                    }
                                }
                            } label: {
                                Image(systemName: "speaker.wave.2")
                                    .frame(minWidth: 44, minHeight: 44)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(RitliTheme.accent)
                            .accessibilityLabel(Text(String(
                                localized: "settings.timer_sound.preview_named",
                                defaultValue: "Preview \(String(localized: sound.title))"
                            )))
                            .accessibilityIdentifier("settings.timerSound.preview.\(sound.rawValue)")
                        }
                    }
                }
            } footer: {
                Text(String(
                    localized: "settings.timer_sound.footer",
                    defaultValue: "Tap the speaker to preview a sound. Sounds respect Silent mode. Turn on Notifications for alerts when Ritli is in the background."
                ))
            }
        }
        .navigationTitle(String(localized: "settings.timer_sound.title", defaultValue: "Timer sound"))
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("settings.timerSound.screen")
        .onDisappear(perform: stopPreview)
        .onChange(of: scenePhase) {
            if scenePhase != .active { stopPreview() }
        }
        .alert(String(localized: "settings.timer_sound.preview", defaultValue: "Sound preview"), isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button(String(localized: .commonActionOk), role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func stopPreview() {
        previewTask?.cancel()
        previewTask = nil
        previewPlayer.stop()
    }
}
