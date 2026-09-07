import ActivityKit
import SwiftUI
import WidgetKit

struct RitliTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerLiveActivityAttributes.self) { context in
            TimerLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    TimerKindLabel(kind: context.attributes.kind)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    TimerCountdownView(state: context.state)
                        .font(.title3.weight(.semibold))
                        .frame(width: 64, alignment: .trailing)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        TimerTaskLabel(
                            taskTitle: context.state.taskTitle,
                            state: context.state
                        )
                        .foregroundStyle(.secondary)
                        TimerProgressView(context: context)
                    }
                }
            } compactLeading: {
                Image(systemName: context.attributes.kind.systemImage)
                    .foregroundStyle(context.attributes.kind.accentColor)
            } compactTrailing: {
                TimerCountdownView(state: context.state)
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: 48)
            } minimal: {
                TimerCountdownView(state: context.state)
                    .font(.caption2.weight(.bold))
                    .minimumScaleFactor(0.45)
            }
            .keylineTint(context.attributes.kind.accentColor)
        }
    }
}

private struct TimerLockScreenView: View {
    @Environment(\.colorScheme) private var colorScheme

    let context: ActivityViewContext<TimerLiveActivityAttributes>

    private var theme: TimerLiveActivityTheme {
        colorScheme == .dark ? .dark : .light
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: context.attributes.kind.systemImage)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(
                        context.attributes.kind.accentColor,
                        in: Circle()
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(context.attributes.kind.titleKey)
                        .font(.headline)

                    TimerTaskLabel(
                        taskTitle: context.state.taskTitle,
                        state: context.state
                    )
                    .foregroundStyle(Color(theme.secondaryText))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                TimerCountdownView(state: context.state)
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .frame(width: 76, alignment: .trailing)
                    .layoutPriority(1)
            }

            TimerProgressView(context: context)
        }
        .foregroundStyle(Color(theme.primaryText))
        .padding(16)
        .activityBackgroundTint(Color(theme.background))
        .activitySystemActionForegroundColor(.ritliCoral)
    }
}

private struct TimerKindLabel: View {
    let kind: TimerLiveActivityAttributes.Kind

    var body: some View {
        Label(kind.titleKey, systemImage: kind.systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(kind.accentColor)
    }
}

private struct TimerTaskLabel: View {
    let taskTitle: String?
    let state: TimerLiveActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 5) {
            if state.isPaused {
                Image(systemName: "pause.fill")
                Text("live_activity.paused")
            } else if let taskTitle, !taskTitle.isEmpty {
                Text(taskTitle)
                    .lineLimit(1)
            } else {
                Text("live_activity.stay_focused")
            }
        }
        .font(.caption)
    }
}

private struct TimerCountdownView: View {
    let state: TimerLiveActivityAttributes.ContentState

    var body: some View {
        Group {
            switch state.phase {
            case let .running(endDate):
                let now = Date.now
                Text(
                    timerInterval: now...max(now, endDate),
                    countsDown: true,
                    showsHours: false
                )
            case let .paused(remainingTime):
                Text(
                    verbatim: TimerLiveActivityPresentation.pausedCountdown(
                        remainingTime
                    )
                )
            }
        }
        .monospacedDigit()
        .contentTransition(.numericText(countsDown: true))
    }
}

private struct TimerProgressView: View {
    let context: ActivityViewContext<TimerLiveActivityAttributes>

    var body: some View {
        Group {
            switch context.state.phase {
            case let .running(endDate):
                let timerInterval = endDate.addingTimeInterval(
                    -context.attributes.plannedDuration
                )...endDate
                ProgressView(
                    timerInterval: timerInterval,
                    countsDown: false
                )
            case let .paused(remainingTime):
                ProgressView(
                    value: TimerLiveActivityPresentation.progress(
                        remainingTime: remainingTime,
                        plannedDuration: context.attributes.plannedDuration
                    )
                )
            }
        }
        .labelsHidden()
        .tint(context.attributes.kind.accentColor)
    }
}

private extension TimerLiveActivityAttributes.Kind {
    var titleKey: LocalizedStringKey {
        switch self {
        case .focus:
            "live_activity.focus"
        case .shortBreak:
            "live_activity.short_break"
        case .longBreak:
            "live_activity.long_break"
        }
    }

    var systemImage: String {
        switch self {
        case .focus:
            "scope"
        case .shortBreak:
            "cup.and.saucer.fill"
        case .longBreak:
            "leaf.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .focus:
            .ritliCoral
        case .shortBreak:
            .ritliGreen
        case .longBreak:
            .ritliBlue
        }
    }
}

private extension Color {
    init(_ components: TimerLiveActivityColorComponents) {
        self.init(
            red: components.red,
            green: components.green,
            blue: components.blue
        )
    }

    static let ritliCoral = Color(red: 1, green: 0.36, blue: 0.29)
    static let ritliGreen = Color(red: 0.31, green: 0.75, blue: 0.45)
    static let ritliBlue = Color(red: 0.27, green: 0.55, blue: 0.96)
}

private extension TimerLiveActivityAttributes {
    static let preview = TimerLiveActivityAttributes(
        sessionID: UUID(),
        kind: .focus,
        startedAt: .now,
        plannedDuration: 1_500
    )
}

private extension TimerLiveActivityAttributes.ContentState {
    static let previewRunning = TimerLiveActivityAttributes.ContentState(
        phase: .running(endDate: .now.addingTimeInterval(1_245)),
        taskTitle: "Prepare release"
    )
    static let previewPaused = TimerLiveActivityAttributes.ContentState(
        phase: .paused(remainingTime: 625),
        taskTitle: "Prepare release"
    )
}

#Preview("Lock Screen", as: .content, using: TimerLiveActivityAttributes.preview) {
    RitliTimerLiveActivity()
} contentStates: {
    TimerLiveActivityAttributes.ContentState.previewRunning
    TimerLiveActivityAttributes.ContentState.previewPaused
}

#Preview("Dynamic Island", as: .dynamicIsland(.expanded), using: TimerLiveActivityAttributes.preview) {
    RitliTimerLiveActivity()
} contentStates: {
    TimerLiveActivityAttributes.ContentState.previewRunning
    TimerLiveActivityAttributes.ContentState.previewPaused
}
