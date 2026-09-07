import SwiftUI

struct FocusHistoryRow: View {
    let entry: FocusHistoryEntry

    var body: some View {
        HStack(spacing: 14) {
            Text(entry.startedAt, format: .dateTime.hour().minute())
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 56, alignment: .leading)

            Circle()
                .fill(RitliTheme.categoryColor(for: entry.categoryColorToken))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: FocusHistoryEntryPresentation.taskTitle(for: entry))
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Text(verbatim: FocusHistoryEntryPresentation.detail(for: entry))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 10)

            Text(TimerDisplayFormatter.focusedTime(entry.focusTime))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            FocusHistoryEntryPresentation.accessibilityLabel(for: entry)
        )
    }
}
