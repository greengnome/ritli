import SwiftData
import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(TimerEngine.self) private var timerEngine
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationPermissionService.self) private var notificationPermissionService
    @Environment(\.locale) private var locale
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
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
        .alert(
            String(
                localized: "settings.notifications.permission_required.title",
                defaultValue: "Notifications are off"
            ),
            isPresented: $isNotificationSettingsAlertPresented
        ) {
            Button(
                String(
                    localized: "settings.notifications.open_settings",
                    defaultValue: "Open Settings"
                )
            ) {
                guard let url = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                openURL(url)
            }
            Button(String(localized: .commonActionCancel), role: .cancel) {}
        } message: {
            Text(
                String(
                    localized: "settings.notifications.permission_required",
                    defaultValue: "Enable notifications for Ritli in System Settings to receive timer alerts."
                )
            )
        }
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
        .task {
            await synchronizeNotificationPreference()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                Task { await synchronizeNotificationPreference() }
            }
        }
    }

    private var timerSection: some View {
        Section {
            durationPicker(
                title: String(localized: "settings.timer.focus", defaultValue: "Focus"),
                selection: durationBinding(\.focusDuration),
                options: TimerSettingsDraft.focusMinuteOptions,
                identifier: "settings.focusDuration"
            )
            durationPicker(
                title: String(localized: "settings.timer.short_break", defaultValue: "Short break"),
                selection: durationBinding(\.shortBreakDuration),
                options: TimerSettingsDraft.shortBreakMinuteOptions,
                identifier: "settings.shortBreakDuration"
            )
            durationPicker(
                title: String(localized: "settings.timer.long_break", defaultValue: "Long break"),
                selection: durationBinding(\.longBreakDuration),
                options: TimerSettingsDraft.longBreakMinuteOptions,
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
                String(localized: "settings.timer.long_break", defaultValue: "Long break"),
                selection: settingBinding(\.longBreakEvery)
            ) {
                ForEach(TimerSettingsDraft.longBreakIntervalOptions, id: \.self) { count in
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
            Toggle(
                String(
                    localized: "settings.feedback.sounds",
                    defaultValue: "Sounds"
                ),
                isOn: settingBinding(\.soundEnabled)
            )
                .accessibilityIdentifier("settings.sound")
                .accessibilityValue(SettingsPresentation.toggleState(isOn: settings.soundEnabled))

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

    private func durationPicker(
        title: String,
        selection: Binding<Int>,
        options: [Int],
        identifier: String
    ) -> some View {
        Picker(title, selection: selection) {
            ForEach(options, id: \.self) { minutes in
                Text(verbatim: SettingsPresentation.minutes(minutes)).tag(minutes)
            }
        }
        .accessibilityIdentifier(identifier)
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
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func persistSettings() {
        do {
            try modelContext.save()
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
                max(1, Int((settings[keyPath: keyPath] / 60).rounded()))
            },
            set: { minutes in
                settings[keyPath: keyPath] = TimeInterval(max(1, minutes) * 60)
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
                settings.notificationsEnabled = isEnabled
                persistSettings()
                if isEnabled {
                    requestNotificationPermission()
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
                if !isAuthorized {
                    settings.notificationsEnabled = false
                    persistSettings()
                    isNotificationSettingsAlertPresented = true
                }
            } catch {
                settings.notificationsEnabled = false
                persistSettings()
                errorMessage = error.localizedDescription
            }
        }
    }

    private func synchronizeNotificationPreference() async {
        await notificationPermissionService.refreshAuthorizationStatus()
        guard
            notificationPermissionService.isDenied,
            settings.notificationsEnabled
        else {
            return
        }

        settings.notificationsEnabled = false
        persistSettings()
    }

    private func clearHistory() {
        do {
            try FocusHistoryCleaner.clearRecordedSessions(in: modelContext)
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
        }
    }
}
