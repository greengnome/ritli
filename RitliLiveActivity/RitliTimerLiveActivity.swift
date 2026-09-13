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
                    TimerKindLabel(
                        kind: context.attributes.kind,
                        isFinished: context.isFinished
                    )
                }

                DynamicIslandExpandedRegion(.trailing) {
                    TimerCountdownView(context: context)
                        .font(.title3.weight(.semibold))
                        .frame(width: 64, alignment: .trailing)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        TimerTaskLabel(
                            taskTitle: context.state.taskTitle,
                            state: context.state,
                            isFinished: context.isFinished
                        )
                        .foregroundStyle(.secondary)
                        TimerProgressView(context: context)
                    }
                }
            } compactLeading: {
                Image(systemName: context.attributes.kind.systemImage)
                    .foregroundStyle(context.attributes.kind.accentColor)
            } compactTrailing: {
                TimerCountdownView(context: context)
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: 48)
            } minimal: {
                TimerCountdownView(context: context)
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
                    Text(context.attributes.kind.titleKey(isFinished: context.isFinished))
                        .font(.headline)

                    TimerTaskLabel(
                        taskTitle: context.state.taskTitle,
                        state: context.state,
                        isFinished: context.isFinished
                    )
                    .foregroundStyle(Color(theme.secondaryText))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                TimerCountdownView(context: context)
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
    let isFinished: Bool

    var body: some View {
        Label(kind.titleKey(isFinished: isFinished), systemImage: kind.systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(kind.accentColor)
    }
}

private struct TimerTaskLabel: View {
    let taskTitle: String?
    let state: TimerLiveActivityAttributes.ContentState
    let isFinished: Bool

    var body: some View {
        HStack(spacing: 5) {
            if state.isPaused {
                Image(systemName: "pause.fill")
                Text("live_activity.paused")
            } else if let taskTitle, !taskTitle.isEmpty {
                Text(taskTitle)
                    .lineLimit(1)
            } else if !isFinished {
                Text("live_activity.stay_focused")
            }
        }
        .font(.caption)
    }
}

private struct TimerCountdownView: View {
    let context: ActivityViewContext<TimerLiveActivityAttributes>

    var body: some View {
        Group {
            if context.isFinished {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(context.attributes.kind.accentColor)
                    .accessibilityLabel(Text("live_activity.finished"))
            } else {
                countdown
            }
        }
        .monospacedDigit()
        .contentTransition(.numericText(countsDown: true))
    }

    @ViewBuilder
    private var countdown: some View {
        switch context.state.phase {
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
}

private struct TimerProgressView: View {
    let context: ActivityViewContext<TimerLiveActivityAttributes>

    var body: some View {
        Group {
            if context.isFinished {
                ProgressView(value: 1)
            } else {
                progress
            }
        }
        .labelsHidden()
        .tint(context.attributes.kind.accentColor)
    }

    @ViewBuilder
    private var progress: some View {
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
}

private extension ActivityViewContext where Attributes == TimerLiveActivityAttributes {
    var isFinished: Bool {
        TimerLiveActivityPresentation.isFinished(
            state: state,
            isStale: isStale,
            at: .now
        )
    }
}

private extension TimerLiveActivityAttributes.Kind {
    func titleKey(isFinished: Bool) -> LocalizedStringKey {
        switch self {
        case .focus:
            isFinished ? "live_activity.focus_finished" : "live_activity.focus"
        case .shortBreak:
            isFinished ? "live_activity.short_break_finished" : "live_activity.short_break"
        case .longBreak:
            isFinished ? "live_activity.long_break_finished" : "live_activity.long_break"
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
    static let previewFinished = TimerLiveActivityAttributes.ContentState(
        phase: .running(endDate: .now.addingTimeInterval(-60)),
        taskTitle: "Prepare release"
    )
}

#Preview("Lock Screen", as: .content, using: TimerLiveActivityAttributes.preview) {
    RitliTimerLiveActivity()
} contentStates: {
    TimerLiveActivityAttributes.ContentState.previewRunning
    TimerLiveActivityAttributes.ContentState.previewPaused
    TimerLiveActivityAttributes.ContentState.previewFinished
}

#Preview("Dynamic Island", as: .dynamicIsland(.expanded), using: TimerLiveActivityAttributes.preview) {
    RitliTimerLiveActivity()
} contentStates: {
    TimerLiveActivityAttributes.ContentState.previewRunning
    TimerLiveActivityAttributes.ContentState.previewPaused
    TimerLiveActivityAttributes.ContentState.previewFinished
}
