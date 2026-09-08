import Foundation
import SwiftUI

struct ContentView: View {
    @Environment(TimerEngine.self) private var timerEngine
    @Environment(NotificationPermissionService.self) private var notificationPermissionService
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedTab: AppTab
    @State private var startFocusError: String?

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
            String(
                localized: "app.alert.focus_start_failed",
                defaultValue: "Focus could not start"
            ),
            isPresented: startFocusErrorIsPresented
        ) {
            Button(String(localized: .commonActionOk), role: .cancel) {}
        } message: {
            Text(startFocusError ?? String(localized: .commonErrorTryAgain))
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

    private var startFocusErrorIsPresented: Binding<Bool> {
        Binding(
            get: { startFocusError != nil },
            set: { if !$0 { startFocusError = nil } }
        )
    }

    private func startFocus(on task: FocusTask) {
        Task { @MainActor in
            await requestNotificationPermissionIfNeeded()

            do {
                try timerEngine.startFocus(task: task)
                selectedTab = .home
            } catch {
                startFocusError = error.localizedDescription
            }
        }
    }

    private func requestNotificationPermissionIfNeeded() async {
        guard timerEngine.settings.notificationsEnabled else { return }

        do {
            let isAuthorized = try await notificationPermissionService
                .requestAuthorizationIfNeeded()
            if !isAuthorized {
                try timerEngine.setNotificationsEnabled(false)
            }
        } catch {
            try? timerEngine.setNotificationsEnabled(false)
            startFocusError = error.localizedDescription
        }
    }

    private func synchronizeNotificationPreference() async {
        await notificationPermissionService.refreshAuthorizationStatus()
        guard
            notificationPermissionService.isDenied,
            timerEngine.settings.notificationsEnabled
        else {
            return
        }

        do {
            try timerEngine.setNotificationsEnabled(false)
        } catch {
            startFocusError = error.localizedDescription
        }
    }
}

private enum AppTab: Hashable {
    case home
    case stats
    case tasks
    case settings
}
