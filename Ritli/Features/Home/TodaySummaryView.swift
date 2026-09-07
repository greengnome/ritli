import SwiftUI

struct TodaySummaryView: View {
    let summary: TodaySummary
    let onViewAll: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text(.homeSummaryToday)
                    .font(.headline)
                Spacer()
                Button(action: onViewAll) {
                    Text(.homeSummaryViewAll)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("home.summary.viewAll")
            }

            HStack {
                metric(
                    value: "\(summary.completedSessions)",
                    title: .homeSummarySessions,
                    systemImage: "clock",
                    color: RitliTheme.accent,
                    identifier: "home.summary.sessions"
                )
                metric(
                    value: TimerDisplayFormatter.focusedTime(summary.focusTime),
                    title: .homeSummaryFocusTime,
                    systemImage: "scope",
                    color: .orange,
                    identifier: "home.summary.focusTime"
                )
                metric(
                    value: "\(summary.completedTasks)",
                    title: .homeSummaryTasksDone,
                    systemImage: "checkmark.circle",
                    color: RitliTheme.success,
                    identifier: "home.summary.tasks"
                )
            }
        }
    }

    private func metric(
        value: String,
        title: LocalizedStringResource,
        systemImage: String,
        color: Color,
        identifier: String
    ) -> some View {
        VStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(color)
            Text(verbatim: value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .accessibilityIdentifier(identifier)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
