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
        } else if arguments.contains("--ui-testing-show-settings") {
            initialTab = .settings
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
            .tabItem {
                Label {
                    Text(.appTabHome)
                } icon: {
                    Image(systemName: "house.fill")
                }
            }
            .tag(AppTab.home)

            StatsView()
                .tabItem {
                    Label {
                        Text(.appTabStats)
                    } icon: {
                        Image(systemName: "chart.bar.fill")
                    }
                }
                .tag(AppTab.stats)

            TasksView(
                canStartFocus: !timerEngine.hasActiveSession,
                onStartFocus: startFocus
            )
                .tabItem {
                    Label {
                        Text(.appTabTasks)
                    } icon: {
                        Image(systemName: "checklist")
                    }
                }
                .tag(AppTab.tasks)

            SettingsView(settings: timerEngine.settings)
                .tabItem {
                    Label {
                        Text(.appTabSettings)
                    } icon: {
                        Image(systemName: "gearshape.fill")
                    }
                }
                .tag(AppTab.settings)
        }
        .tint(RitliTheme.accent)
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
            await synchronizeNotificationPreference()
            await TimerRefreshLoop().run(engine: timerEngine) { error in
                timerError = error.localizedDescription
            }
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
