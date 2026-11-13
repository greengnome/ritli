import ActivityKit
import SwiftUI
import WidgetKit

/// The Lock Screen card takes the session's colour (tomato for focus, leaf
/// for breaks), matching Home while a session runs. The Dynamic Island uses
/// one small progress ring as its signature in every presentation.
struct RitliTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerLiveActivityAttributes.self) { context in
            TimerLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    TimerRing(context: context, tint: context.attributes.kind.islandTint)
                        .frame(width: 44, height: 44)
                        .padding(.leading, 6)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    TimerCountdownView(context: context)
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.ritliOnAccent)
                        .frame(maxWidth: 140, alignment: .trailing)
                        .padding(.trailing, 6)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        TimerHeadline(context: context)
                            .font(.system(.headline, design: .rounded).weight(.heavy))
                            .foregroundStyle(Color.ritliOnAccent)
                        TimerSubtitle(context: context)
                            .font(.footnote)
                            .foregroundStyle(Color.ritliIslandSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 6)
                }
            } compactLeading: {
                TimerRing(context: context, tint: context.attributes.kind.islandTint)
                    .frame(width: 20, height: 20)
            } compactTrailing: {
                TimerCountdownView(context: context)
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(context.attributes.kind.islandTint)
                    .frame(maxWidth: 52)
            } minimal: {
                TimerRing(context: context, tint: context.attributes.kind.islandTint)
                    .frame(width: 20, height: 20)
            }
            .keylineTint(context.attributes.kind.islandTint)
        }
    }
}

private struct TimerLockScreenView: View {
    @Environment(\.colorScheme) private var colorScheme

    let context: ActivityViewContext<TimerLiveActivityAttributes>

    var body: some View {
        if context.isFinished {
            finished
        } else {
            running
        }
    }

    private var running: some View {
        HStack(spacing: 14) {
            TimerRing(context: context, tint: .ritliOnAccent)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                TimerHeadline(context: context)
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .lineLimit(1)
                TimerSubtitle(context: context)
                    .font(.footnote)
                    .foregroundStyle(Color.ritliOnAccent.opacity(0.88))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            TimerCountdownView(context: context)
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .frame(minWidth: 96, alignment: .trailing)
                .layoutPriority(1)
        }
        .foregroundStyle(Color.ritliOnAccent)
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .activityBackgroundTint(context.attributes.kind.fill)
        .activitySystemActionForegroundColor(.ritliOnAccent)
    }

    private var finished: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Color.ritliLeafFill, in: Circle())
                .accessibilityHidden(true)

            Text(context.attributes.kind.titleKey(isFinished: true))
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(colorScheme == .dark ? Color.ritliOnAccent : Color.ritliInk)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .activityBackgroundTint(colorScheme == .dark ? Color.ritliPaperDark : Color.ritliPaper)
        .activitySystemActionForegroundColor(colorScheme == .dark ? .ritliOnAccent : .ritliInk)
    }
}

/// The task when there is one (and the user allows it on the Lock Screen),
/// otherwise the session kind.
private struct TimerHeadline: View {
    let context: ActivityViewContext<TimerLiveActivityAttributes>

    var body: some View {
        if context.isFinished {
            Text(context.attributes.kind.titleKey(isFinished: true))
        } else if let taskTitle = context.state.taskTitle, !taskTitle.isEmpty {
            Text(verbatim: taskTitle)
        } else {
            Text(context.attributes.kind.titleKey(isFinished: false))
        }
    }
}

/// "Focus · 10:24" while running, "Paused" while paused.
private struct TimerSubtitle: View {
    let context: ActivityViewContext<TimerLiveActivityAttributes>

    var body: some View {
        switch context.state.phase {
        case .paused:
            Text("live_activity.paused")
        case let .running(endDate):
            if hasTaskTitle {
                HStack(spacing: 0) {
                    Text(context.attributes.kind.titleKey(isFinished: false))
                    Text(verbatim: " · ")
                    Text(endDate, style: .time)
                }
            } else {
                Text(endDate, style: .time)
            }
        }
    }

    private var hasTaskTitle: Bool {
        guard let taskTitle = context.state.taskTitle else { return false }
        return !taskTitle.isEmpty
    }
}

/// Time left in the session as a ring. It is the app icon's outer ring,
/// and the one shape the Island keeps when it shrinks to a dot.
private struct TimerRing: View {
    let context: ActivityViewContext<TimerLiveActivityAttributes>
    let tint: Color

    var body: some View {
        Group {
            if context.isFinished {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(tint)
            } else {
                progress
                    .progressViewStyle(.circular)
                    .tint(tint)
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var progress: some View {
        switch context.state.phase {
        case let .running(endDate):
            ProgressView(
                timerInterval: endDate.addingTimeInterval(
                    -context.attributes.plannedDuration
                )...endDate,
                countsDown: true,
                label: { EmptyView() },
                currentValueLabel: { EmptyView() }
            )
        case let .paused(remainingTime):
            ProgressView(
                value: 1 - TimerLiveActivityPresentation.progress(
                    remainingTime: remainingTime,
                    plannedDuration: context.attributes.plannedDuration
                )
            )
        }
    }
}

private struct TimerCountdownView: View {
    let context: ActivityViewContext<TimerLiveActivityAttributes>

    var body: some View {
        Group {
            if context.isFinished {
                Image(systemName: "checkmark")
                    .accessibilityLabel(Text("live_activity.finished"))
            } else {
                countdown
            }
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .multilineTextAlignment(.trailing)
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

    /// The Lock Screen card's fill. White text on it passes 4.5:1.
    var fill: Color {
        switch self {
        case .focus:
            .ritliTomatoFill
        case .shortBreak, .longBreak:
            .ritliLeafFill
        }
    }

    /// Colour on the Island's black: brighter versions of the same two hues.
    var islandTint: Color {
        switch self {
        case .focus:
            .ritliTomato
        case .shortBreak, .longBreak:
            .ritliLeafBright
        }
    }
}

// The extension can't see the app's RitliTheme, so it carries the few
// values it needs. Keep them in step with Ritli/DesignSystem/RitliTheme.swift.
private extension Color {
    static let ritliTomato = Color(red: 1, green: 0.361, blue: 0.290)        // #FF5C4A
    static let ritliTomatoFill = Color(red: 0.812, green: 0.227, blue: 0.141) // #CF3A24
    static let ritliLeafFill = Color(red: 0.173, green: 0.420, blue: 0.290)   // #2C6B4A
    static let ritliLeafBright = Color(red: 0.424, green: 0.780, blue: 0.565) // #6CC790
    static let ritliOnAccent = Color(red: 1, green: 0.965, blue: 0.925)       // #FFF6EC
    static let ritliInk = Color(red: 0.122, green: 0.102, blue: 0.090)        // #1F1A17
    static let ritliPaper = Color(red: 0.980, green: 0.969, blue: 0.949)      // #FAF7F2
    static let ritliPaperDark = Color(red: 0.090, green: 0.078, blue: 0.071)  // #171412
    static let ritliIslandSecondary = Color(red: 0.788, green: 0.741, blue: 0.682) // #C9BDAE
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
