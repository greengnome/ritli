import SwiftUI

/// Today's totals as one quiet row under the timer: numbers and words, no
/// icons, and a link to the full history.
struct TodaySummaryView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let summary: TodaySummary
    let style: HomeStyle
    let onViewAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(.homeSummaryToday)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(style.foreground)

                Spacer(minLength: 12)

                Button(action: onViewAll) {
                    HStack(spacing: 4) {
                        Text(.homeSummaryViewAll)
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.bold))
                            .accessibilityHidden(true)
                    }
                    .font(.subheadline)
                    .foregroundStyle(style.secondary)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("home.summary.viewAll")
            }

            metricsLayout {
                metric(
                    value: "\(summary.completedSessions)",
                    title: .homeSummarySessions,
                    identifier: "home.summary.sessions"
                )
                metric(
                    value: TimerDisplayFormatter.focusedTime(summary.focusTime),
                    title: .homeSummaryFocusTime,
                    identifier: "home.summary.focusTime"
                )
                metric(
                    value: "\(summary.completedTasks)",
                    title: .homeSummaryTasksDone,
                    identifier: "home.summary.tasks"
                )
            }
        }
        .padding(.top, 12)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(style == .resting ? RitliTheme.hairline : style.track)
                .frame(height: 1)
        }
    }

    private var metricsLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 16))
    }

    private func metric(
        value: String,
        title: LocalizedStringResource,
        identifier: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: value)
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .monospacedDigit()
                .foregroundStyle(style.foreground)
                .accessibilityIdentifier(identifier)
            Text(title)
                .font(.footnote)
                .foregroundStyle(style.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
