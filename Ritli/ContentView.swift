import Foundation
import SwiftUI

struct ContentView: View {
    @Environment(TimerEngine.self) private var timerEngine
    @Environment(NotificationPermissionService.self) private var notificationPermissionService
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedTab: AppTab
    @State private var timerError: String?
    @State private var isNotificationsOffAlertPresented = false

    init() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        let initialTab: AppTab

        if arguments.contains("--ui-testing-show-stats") {
            initialTab = .stats
        } else if arguments.contains("--ui-testing-show-tasks") {
            initialTab = .tasks
        } else {
            initialTab = .home
        }

        _selectedTab = State(initialValue: initialTab)
        #else
        _selectedTab = State(initialValue: .home)
        #endif
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView {
                selectedTab = .settings
            }
            .tint(RitliTheme.accent)
            .tabItem {
                Label {
                    Text(.appTabHome)
                } icon: {
                    RitliTabIcon.home.image
                }
            }
            .tag(AppTab.home)

            StatsView()
                .tint(RitliTheme.accent)
                .tabItem {
                    Label {
                        Text(.appTabStats)
                    } icon: {
                        RitliTabIcon.stats.image
                    }
                }
                .tag(AppTab.stats)

            TasksView(
                canStartFocus: !timerEngine.hasActiveSession,
                onStartFocus: startFocus
            )
                .tint(RitliTheme.accent)
                .tabItem {
                    Label {
                        Text(.appTabTasks)
                    } icon: {
                        RitliTabIcon.tasks.image
                    }
                }
                .tag(AppTab.tasks)

            SettingsView(settings: timerEngine.settings)
                .tint(RitliTheme.accent)
                .tabItem {
                    Label {
                        Text(.appTabSettings)
                    } icon: {
                        RitliTabIcon.settings.image
                    }
                }
                .tag(AppTab.settings)
        }
        // The selected tab is neutral, and its colour follows the bar, not the
        // screen behind it: the bar is system material in the current
        // appearance (light glass even over a session colour), so the light
        // session text would vanish on it.
        .tint(RitliTheme.ink)
        .preferredColorScheme(timerEngine.settings.appearance.preferredColorScheme)
        .alert(
            String(localized: .homeAlertTimerUnavailable),
            isPresented: timerErrorIsPresented
        ) {
            Button(String(localized: .commonActionOk), role: .cancel) {}
        } message: {
            Text(timerError ?? String(localized: .commonErrorTryAgain))
        }
        .notificationsOffAlert(isPresented: $isNotificationsOffAlertPresented)
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await TimerRefreshLoop().run(engine: timerEngine) { error in
                timerError = error.localizedDescription
            }
        }
        // Separate from the refresh loop: the permission query can be slow,
        // and a timer that ran out must be reconciled without waiting for it.
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await synchronizeNotificationPreference()
        }
    }

    private var timerErrorIsPresented: Binding<Bool> {
        Binding(isPresenting: $timerError)
    }

    private func startFocus(on task: FocusTask) {
        Task { @MainActor in
            do {
                let readiness = try await TimerNotificationPreference.prepareForTimerStart(
                    permissions: notificationPermissionService,
                    engine: timerEngine
                )
                isNotificationsOffAlertPresented = readiness == .permissionDenied
            } catch {
                timerError = error.localizedDescription
            }

            do {
                try timerEngine.startFocus(task: task)
                selectedTab = .home
            } catch {
                timerError = error.localizedDescription
            }
        }
    }

    private func synchronizeNotificationPreference() async {
        do {
            try await TimerNotificationPreference.disableIfDenied(
                permissions: notificationPermissionService,
                engine: timerEngine
            )
        } catch {
            timerError = error.localizedDescription
        }
    }
}

private enum AppTab: Hashable {
    case home
    case stats
    case tasks
    case settings
}
