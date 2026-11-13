import SwiftUI

struct FocusHistorySummaryCard: View {
    let day: FocusHistoryDay

    var body: some View {
        HStack(spacing: 0) {
            metric(
                value: TimerDisplayFormatter.focusedTime(day.focusTime),
                title: String(localized: .historySummaryFocused),
                identifier: "history.focusTime.value"
            )

            divider

            metric(
                value: "\(day.completedSessions)",
                title: String(localized: .homeSummarySessions),
                identifier: "history.sessions.value"
            )

            divider

            metric(
                value: "\(day.completedTasks)",
                title: String(localized: .appTabTasks),
                identifier: "history.tasks.value"
            )
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(
            RitliTheme.surface,
            in: RoundedRectangle(cornerRadius: RitliTheme.cardRadius)
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(RitliTheme.hairline)
            .frame(width: 1, height: 44)
    }

    private func metric(
        value: String,
        title: String,
        identifier: String
    ) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(RitliTheme.ink)
                .accessibilityIdentifier(identifier)

            Text(title)
                .font(.caption)
                .foregroundStyle(RitliTheme.stone)
        }
        .frame(maxWidth: .infinity)
    }
}
