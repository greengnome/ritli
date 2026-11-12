import SwiftData
import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(TimerEngine.self) private var timerEngine
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationPermissionService.self) private var notificationPermissionService
    @Environment(\.locale) private var locale
    @Environment(\.openURL) private var openURL
    @Query private var sessions: [FocusSession]

    @State private var errorMessage: String?
    @State private var isClearHistoryConfirmationPresented = false
    @State private var isNotificationSettingsAlertPresented = false
    @Bindable private var settings: PomodoroSettings

    init(settings: PomodoroSettings) {
        self.settings = settings
    }

    var body: some View {
        NavigationStack {
            Form {
                timerSection
                cycleSection
                feedbackSection
                privacySection
                appearanceSection
                languageSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(.background)
            .navigationTitle(String(localized: .appTabSettings))
            .accessibilityIdentifier("settings.screen")
        }
        .alert(
            String(
                localized: "settings.alert.unavailable",
                defaultValue: "Settings unavailable"
            ),
            isPresented: errorIsPresented
        ) {
            Button(String(localized: .commonActionOk), role: .cancel) {}
        } message: {
            Text(errorMessage ?? String(localized: .commonErrorTryAgain))
        }
        .notificationsOffAlert(isPresented: $isNotificationSettingsAlertPresented)
        .confirmationDialog(
            String(localized: "settings.data.clear_confirmation.title", defaultValue: "Clear focus history?"),
            isPresented: $isClearHistoryConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button(
                String(
                    localized: "settings.data.clear_confirmation.action",
                    defaultValue: "Clear History"
                ),
                role: .destructive
            ) {
                clearHistory()
            }
            Button(String(localized: .commonActionCancel), role: .cancel) {}
        } message: {
            Text(
                String(
                    localized: "settings.data.clear_confirmation.message",
                    defaultValue: "Recorded sessions will be permanently deleted. Your tasks and preferences will be kept."
                )
            )
        }
    }

    private var timerSection: some View {
        Section {
            MinutesPicker(
                title: String(localized: "settings.timer.focus", defaultValue: "Focus"),
                selection: durationBinding(\.focusDuration),
                options: TimerDurationOptions.focusMinutes,
                identifier: "settings.focusDuration"
            )
            MinutesPicker(
                title: String(localized: "settings.timer.short_break", defaultValue: "Short break"),
                selection: durationBinding(\.shortBreakDuration),
                options: TimerDurationOptions.shortBreakMinutes,
                identifier: "settings.shortBreakDuration"
            )
            MinutesPicker(
                title: String(localized: "settings.timer.long_break", defaultValue: "Long break"),
                selection: durationBinding(\.longBreakDuration),
                options: TimerDurationOptions.longBreakMinutes,
                identifier: "settings.longBreakDuration"
            )
        } header: {
            Text(String(localized: "settings.timer.section", defaultValue: "Timer"))
        } footer: {
            Text(
                String(
                    localized: "settings.timer.footer",
                    defaultValue: "Duration changes apply to the next session, never one already in progress."
                )
            )
        }
    }

    private var cycleSection: some View {
        Section(String(localized: "settings.cycle.section", defaultValue: "Cycle")) {
            Picker(
                String(
                    localized: "settings.cycle.long_break_frequency",
                    defaultValue: "Long break frequency"
                ),
                selection: settingBinding(\.longBreakEvery)
            ) {
                ForEach(TimerDurationOptions.longBreakIntervals, id: \.self) { count in
                    Text(verbatim: SettingsPresentation.longBreakInterval(count)).tag(count)
                }
            }
            .accessibilityIdentifier("settings.longBreakEvery")

            Toggle(
                String(localized: "settings.cycle.auto_start_breaks", defaultValue: "Auto-start breaks"),
                isOn: settingBinding(\.autoStartBreaks)
            )
            .accessibilityIdentifier("settings.autoStartBreaks")
            .accessibilityValue(SettingsPresentation.toggleState(isOn: settings.autoStartBreaks))

            Toggle(
                String(localized: "settings.cycle.auto_start_focus", defaultValue: "Auto-start focus"),
                isOn: settingBinding(\.autoStartFocus)
            )
            .accessibilityIdentifier("settings.autoStartFocus")
            .accessibilityValue(SettingsPresentation.toggleState(isOn: settings.autoStartFocus))
        }
    }

    private var feedbackSection: some View {
        Section(String(localized: "settings.feedback.section", defaultValue: "Feedback")) {
            NavigationLink {
                TimerSoundPickerView(selectedSound: settings.timerSound) { sound in
                    try timerEngine.setTimerSound(sound)
                }
            } label: {
                LabeledContent(
                    String(localized: "settings.timer_sound.title", defaultValue: "Timer sound"),
                    value: String(localized: settings.timerSound.title)
                )
            }
            .accessibilityIdentifier("settings.timerSound")

            Toggle(
                String(
                    localized: "settings.feedback.haptics",
                    defaultValue: "Haptics"
                ),
                isOn: settingBinding(\.hapticsEnabled)
            )
                .accessibilityIdentifier("settings.haptics")
                .accessibilityValue(SettingsPresentation.toggleState(isOn: settings.hapticsEnabled))

            Toggle(
                String(
                    localized: "settings.feedback.notifications",
                    defaultValue: "Notifications"
                ),
                isOn: notificationsBinding
            )
                .accessibilityIdentifier("settings.notifications")
                .accessibilityValue(SettingsPresentation.toggleState(isOn: settings.notificationsEnabled))
        }
    }

    private var aboutSection: some View {
        Section(String(localized: "settings.about.section", defaultValue: "About")) {
            if let privacyPolicyURL = AppExternalLinks.privacyPolicyURL {
                Link(destination: privacyPolicyURL) {
                    externalLinkLabel(
                        String(
                            localized: "settings.about.privacy_policy",
                            defaultValue: "Privacy Policy"
                        )
                    )
                }
                .accessibilityIdentifier("settings.privacyPolicy")
            }

            if let supportURL = AppExternalLinks.supportURL {
                Link(destination: supportURL) {
                    externalLinkLabel(
                        String(
                            localized: "settings.about.support",
                            defaultValue: "Support"
                        )
                    )
                }
                .accessibilityIdentifier("settings.support")
            }

            LabeledContent(String(localized: "settings.about.version", defaultValue: "Version"), value: appVersion)
        }
    }

    private func externalLinkLabel(_ title: String) -> some View {
        HStack {
            Text(verbatim: title)
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var privacySection: some View {
        Section {
            Toggle(
                String(
                    localized: "settings.privacy.show_task_titles",
                    defaultValue: "Show task names on Lock Screen"
                ),
                isOn: showTaskTitlesOnLockScreenBinding
            )
            .accessibilityIdentifier("settings.showTaskTitlesOnLockScreen")
            .accessibilityValue(
                SettingsPresentation.toggleState(
                    isOn: settings.showTaskTitlesOnLockScreen
                )
            )
        } header: {
            Text(
                String(
                    localized: "settings.privacy.section",
                    defaultValue: "Privacy"
                )
            )
        } footer: {
            Text(
                String(
                    localized: "settings.privacy.footer",
                    defaultValue: "When off, Live Activities show the timer without your task name."
                )
            )
        }
    }

    private var appearanceSection: some View {
        Section(String(localized: "settings.appearance.section", defaultValue: "Appearance")) {
            Picker(
                String(
                    localized: "settings.appearance.theme",
                    defaultValue: "Theme"
                ),
                selection: appearanceBinding
            ) {
                ForEach(AppAppearance.allCases) { appearance in
                    Text(verbatim: appearance.title()).tag(appearance)
                }
            }
            .accessibilityIdentifier("settings.appearance")
        }
    }

    private var languageSection: some View {
        Section {
            Button {
                guard let url = AppLanguagePresentation.settingsURL else { return }
                openURL(url)
            } label: {
                HStack(spacing: 12) {
                    Label(
                        String(
                            localized: "settings.language.app_language",
                            defaultValue: "App language"
                        ),
                        systemImage: "globe"
                    )

                    Spacer()

                    Text(
                        verbatim: AppLanguagePresentation.currentLanguageName(
                            locale: locale
                        )
                    )
                    .foregroundStyle(.secondary)

                    Image(systemName: "arrow.up.forward.app")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityIdentifier("settings.language")
        } header: {
            Text(
                String(
                    localized: "settings.language.section",
                    defaultValue: "Language"
                )
            )
        } footer: {
            Text(
                String(
                    localized: "settings.language.footer",
                    defaultValue: "Choose a language in iOS Settings."
                )
            )
        }
    }

    private var dataSection: some View {
        Section {
            LabeledContent(String(localized: "settings.data.recorded_sessions", defaultValue: "Recorded sessions")) {
                Text("\(recordedSessionCount)")
                    .accessibilityIdentifier("settings.historyCount")
            }

            Button(String(localized: "settings.data.clear", defaultValue: "Clear focus history"), role: .destructive) {
                isClearHistoryConfirmationPresented = true
            }
            .disabled(recordedSessionCount == 0)
            .accessibilityIdentifier("settings.clearHistory")
        } header: {
            Text(String(localized: "settings.data.section", defaultValue: "Data"))
        } footer: {
            Text(String(localized: "settings.data.footer", defaultValue: "An active or paused timer is never removed."))
        }
    }

    private var appVersion: String {
        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String
        let build = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String

        return switch (version, build) {
        case let (.some(version), .some(build)):
            "\(version) (\(build))"
        case let (.some(version), .none):
            version
        default:
            "—"
        }
    }

    private var recordedSessionCount: Int {
        sessions.count { $0.state.isTerminal }
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(isPresenting: $errorMessage)
    }

    private func persistSettings() {
        do {
            try modelContext.save()
            timerEngine.applySettingsChanges()
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
        }
    }

    private func durationBinding(
        _ keyPath: ReferenceWritableKeyPath<PomodoroSettings, TimeInterval>
    ) -> Binding<Int> {
        Binding(
            get: {
                TimerDurationOptions.minutes(from: settings[keyPath: keyPath])
            },
            set: { minutes in
                settings[keyPath: keyPath] = TimerDurationOptions.duration(fromMinutes: minutes)
                persistSettings()
            }
        )
    }

    private func settingBinding<Value>(
        _ keyPath: ReferenceWritableKeyPath<PomodoroSettings, Value>
    ) -> Binding<Value> {
        Binding(
            get: { settings[keyPath: keyPath] },
            set: { value in
                settings[keyPath: keyPath] = value
                persistSettings()
            }
        )
    }

    private var notificationsBinding: Binding<Bool> {
        Binding(
            get: { settings.notificationsEnabled },
            set: { isEnabled in
                do {
                    try timerEngine.setNotificationsEnabled(isEnabled)
                    if isEnabled { requestNotificationPermission() }
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        )
    }

    private var showTaskTitlesOnLockScreenBinding: Binding<Bool> {
        Binding(
            get: { settings.showTaskTitlesOnLockScreen },
            set: { isEnabled in
                do {
                    try timerEngine.setShowTaskTitlesOnLockScreen(isEnabled)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        )
    }

    private var appearanceBinding: Binding<AppAppearance> {
        Binding(
            get: { settings.appearance },
            set: { appearance in
                settings.appearance = appearance
                persistSettings()
            }
        )
    }

    private func requestNotificationPermission() {
        Task { @MainActor in
            do {
                let isAuthorized = try await notificationPermissionService
                    .requestAuthorizationIfNeeded()
                try timerEngine.setNotificationsEnabled(isAuthorized)
                if !isAuthorized {
                    isNotificationSettingsAlertPresented = true
                }
            } catch {
                try? timerEngine.setNotificationsEnabled(false)
                errorMessage = error.localizedDescription
            }
        }
    }

    private func clearHistory() {
        do {
            // The engine keeps the last finished session; let it go first.
            timerEngine.releaseFinishedSession()
            try FocusHistoryCleaner.clearRecordedSessions(in: modelContext)
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
        }
    }
}
