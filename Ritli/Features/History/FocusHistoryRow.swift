import SwiftUI

struct FocusHistoryRow: View {
    let entry: FocusHistoryEntry

    var body: some View {
        HStack(spacing: 14) {
            Text(entry.startedAt, format: .dateTime.hour().minute())
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(RitliTheme.stone)
                .frame(width: 56, alignment: .leading)

            Circle()
                .fill(RitliTheme.categoryColor(for: entry.categoryColorToken))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: FocusHistoryEntryPresentation.taskTitle(for: entry))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RitliTheme.ink)
                    .lineLimit(1)

                Text(verbatim: FocusHistoryEntryPresentation.detail(for: entry))
                    .font(.caption)
                    .foregroundStyle(RitliTheme.stone)
                    .lineLimit(1)
            }

            Spacer(minLength: 10)

            Text(TimerDisplayFormatter.focusedTime(entry.focusTime))
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .monospacedDigit()
                .foregroundStyle(RitliTheme.ink)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            FocusHistoryEntryPresentation.accessibilityLabel(for: entry)
        )
    }
}
