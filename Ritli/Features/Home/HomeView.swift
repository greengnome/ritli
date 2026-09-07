import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(TimerEngine.self) private var timerEngine
    @Environment(NotificationPermissionService.self) private var notificationPermissionService
    @Environment(\.scenePhase) private var scenePhase
    @Query private var sessions: [FocusSession]
    @Query private var tasks: [FocusTask]

    @State private var selectedKind = SessionKind.focus
    @State private var selectedTaskID: UUID?
    @State private var isTaskPickerPresented = false
    @State private var isHistoryPresented = false
    @State private var errorMessage: String?

    let onOpenSettings: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 26) {
                    if let task = activeTask {
                        CurrentTaskBanner(task: task)
                    } else if showsTaskSelector {
                        HomeTaskPickerButton(task: selectedTask) {
                            isTaskPickerPresented = true
                        }
                    }

                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        HomeTimerCard(
                            kind: displayedKind,
                            state: timerEngine.currentSession?.state,
                            remainingTime: displayedRemainingTime(at: context.date),
                            progress: displayedProgress(at: context.date),
                            duration: displayedDuration,
                            isModeSelectionEnabled: !timerEngine.hasActiveSession,
                            onSelectMode: selectMode,
                            onPrimaryAction: primaryAction,
                            onCancel: cancelSession,
                            onSkipBreak: skipBreak
                        )
                    }

                    TodaySummaryView(
                        summary: TodaySummary(sessions: sessions, tasks: tasks),
                        onViewAll: { isHistoryPresented = true }
                    )
                }
                .padding(.horizontal, RitliTheme.screenPadding)
                .padding(.bottom, 24)
            }
            .background(RitliTheme.background)
            .navigationTitle(Text(verbatim: "Ritli"))
            .navigationDestination(isPresented: $isHistoryPresented) {
                FocusHistoryView()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onOpenSettings) {
                        Label {
                            Text(.appTabSettings)
                        } icon: {
                            Image(systemName: "slider.horizontal.3")
                        }
                    }
                    .accessibilityIdentifier("home.settings")
                }
            }
        }
        .task {
            selectedTaskID = timerEngine.cycleState.preferredFocusTask?.id
            await monitorTimer()
        }
        .onChange(of: selectedTaskID) {
            persistSelectedTask()
        }
        .onChange(of: timerEngine.cycleState.preferredFocusTask?.id) {
            selectedTaskID = timerEngine.cycleState.preferredFocusTask?.id
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                refreshTimer()
            }
        }
        .sheet(isPresented: $isTaskPickerPresented) {
            HomeTaskPickerView(
                tasks: selectableTasks,
                selectedTaskID: $selectedTaskID
            )
            .presentationDetents([.medium, .large])
        }
        .alert(
            String(localized: .homeAlertTimerUnavailable),
            isPresented: errorIsPresented
        ) {
            Button(String(localized: .commonActionOk), role: .cancel) {}
        } message: {
            Text(errorMessage ?? String(localized: .commonErrorTryAgain))
        }
    }

    private var displayedKind: SessionKind {
        timerEngine.hasActiveSession
            ? timerEngine.currentSession?.kind ?? selectedKind
            : selectedKind
    }

    private var activeTask: FocusTask? {
        guard timerEngine.hasActiveSession else { return nil }
        return timerEngine.currentSession?.task
    }

    private var selectableTasks: [FocusTask] {
        HomeTaskPickerPresentation.selectableTasks(from: tasks)
    }

    private var selectedTask: FocusTask? {
        selectableTasks.first { $0.id == selectedTaskID }
    }

    private var showsTaskSelector: Bool {
        !timerEngine.hasActiveSession && selectedKind == .focus
    }

    private var displayedDuration: TimeInterval {
        if timerEngine.hasActiveSession {
            return timerEngine.currentSession?.plannedDuration ?? 0
        }
        return timerEngine.previewDuration(
            for: selectedKind,
            task: selectedKind == .focus ? selectedTask : nil
        )
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func displayedRemainingTime(at date: Date) -> TimeInterval {
        if timerEngine.hasActiveSession {
            return timerEngine.remainingTime(at: date)
        }
        return displayedDuration
    }

    private func displayedProgress(at date: Date) -> Double {
        guard
            timerEngine.hasActiveSession,
            let session = timerEngine.currentSession,
            session.plannedDuration > 0
        else {
            return 0
        }

        return min(
            1,
            max(0, 1 - timerEngine.remainingTime(at: date) / session.plannedDuration)
        )
    }

    private func selectMode(_ kind: SessionKind) {
        selectedKind = kind
    }

    private func primaryAction() {
        do {
            switch timerEngine.currentSession?.state {
            case .running:
                try timerEngine.pause()
            case .paused:
                try timerEngine.resume()
            case .completed, .cancelled, .skipped, .none:
                startSelectedMode()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startSelectedMode() {
        let kind = selectedKind
        let task = selectedTask

        Task { @MainActor in
            await requestNotificationPermissionIfNeeded()

            do {
                switch kind {
                case .focus:
                    try timerEngine.startFocus(task: task)
                case .shortBreak:
                    try timerEngine.startShortBreak()
                case .longBreak:
                    try timerEngine.startLongBreak()
                }
            } catch {
                errorMessage = error.localizedDescription
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
                errorMessage = String(
                    localized: "settings.notifications.permission_required",
                    defaultValue: "Enable notifications for Ritli in System Settings to receive timer alerts."
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func cancelSession() {
        do {
            try timerEngine.cancel()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func skipBreak() {
        do {
            try timerEngine.skipBreak()
            selectedKind = timerEngine.cycleState.nextSuggestedKind
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshTimer() {
        do {
            if try timerEngine.refresh(), !timerEngine.hasActiveSession {
                selectedKind = timerEngine.cycleState.nextSuggestedKind
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func persistSelectedTask() {
        do {
            try timerEngine.selectFocusTask(selectedTask)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func monitorTimer() async {
        refreshTimer()

        while !Task.isCancelled {
            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                return
            }

            refreshTimer()
        }
    }
}
