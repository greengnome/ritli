import SwiftData
import SwiftUI
import UIKit

struct HomeView: View {
    @Environment(TimerEngine.self) private var timerEngine
    @Environment(NotificationPermissionService.self) private var notificationPermissionService
    @Query private var sessions: [FocusSession]
    @Query private var tasks: [FocusTask]

    @State private var selectedKind = SessionKind.focus
    @State private var selectedTaskID: UUID?
    @State private var isTaskPickerPresented = false
    @State private var isHistoryPresented = false
    @State private var errorMessage: String?
    @State private var isNotificationsOffAlertPresented = false
    @State private var isStartingSession = false
    /// Re-read at midnight and on appearance so "Today" never shows yesterday.
    @State private var summaryDate = Date.now

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

                    HomeTimerCard(
                        kind: displayedKind,
                        state: timerEngine.currentSession?.state,
                        remainingTime: displayedRemainingTime,
                        duration: displayedDuration,
                        isModeSelectionEnabled: !timerEngine.hasActiveSession,
                        onSelectMode: selectMode,
                        onPrimaryAction: primaryAction,
                        onCancel: cancelSession,
                        onSkipBreak: skipBreak
                    )

                    TodaySummaryView(
                        summary: TodaySummary(
                            sessions: sessions,
                            tasks: tasks,
                            now: summaryDate
                        ),
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
            summaryDate = .now
            selectedTaskID = timerEngine.cycleState.preferredFocusTask?.id
            synchronizeSuggestedKind()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIApplication.significantTimeChangeNotification
            )
        ) { _ in
            summaryDate = .now
        }
        .onChange(of: selectedTaskID) {
            persistSelectedTask()
        }
        .onChange(of: timerEngine.cycleState.preferredFocusTask?.id) {
            selectedTaskID = timerEngine.cycleState.preferredFocusTask?.id
        }
        .onChange(of: timerEngine.currentSession?.state) {
            synchronizeSuggestedKind()
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
        .notificationsOffAlert(isPresented: $isNotificationsOffAlertPresented)
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
        Binding(isPresenting: $errorMessage)
    }

    private func displayedRemainingTime(at date: Date) -> TimeInterval {
        if timerEngine.hasActiveSession {
            return timerEngine.remainingTime(at: date)
        }
        return displayedDuration
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
        // Starting waits for the permission check; ignore repeated taps.
        guard !isStartingSession else { return }
        isStartingSession = true
        let kind = selectedKind
        let task = selectedTask

        Task { @MainActor in
            defer { isStartingSession = false }

            do {
                let readiness = try await TimerNotificationPreference.prepareForTimerStart(
                    permissions: notificationPermissionService,
                    engine: timerEngine
                )
                isNotificationsOffAlertPresented = readiness == .permissionDenied
            } catch {
                errorMessage = error.localizedDescription
            }

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

    private func synchronizeSuggestedKind() {
        // With no session in memory (e.g. after a relaunch) the persisted
        // suggestion still applies; otherwise Start would discard it.
        switch timerEngine.currentSession?.state {
        case .none, .completed, .skipped:
            selectedKind = timerEngine.cycleState.nextSuggestedKind
        case .running, .paused, .cancelled:
            break
        }
    }

    private func persistSelectedTask() {
        do {
            try timerEngine.selectFocusTask(selectedTask)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
