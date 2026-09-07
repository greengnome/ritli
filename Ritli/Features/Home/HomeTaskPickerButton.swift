import SwiftUI

struct HomeTaskPickerButton: View {
    let task: FocusTask?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: task?.category?.iconName ?? "checklist")
                    .font(.title3)
                    .foregroundStyle(task?.category?.presentationColor ?? RitliTheme.accent)
                    .frame(width: 38, height: 38)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(.homeTaskWorkingOn)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Group {
                        if let task {
                            Text(verbatim: task.title)
                        } else {
                            Text(.homeTaskChooseOptional)
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(Text(.homeTaskPickerHint))
        .accessibilityIdentifier("home.taskSelector")
    }

    private var accessibilityLabel: Text {
        guard let task else {
            return Text(.homeTaskChoose)
        }

        return Text(
            LocalizedStringResource(
                "home.task.working_on.accessibility",
                defaultValue: "Working on \(task.title)",
                comment: "VoiceOver label for a selected task on Home."
            )
        )
    }
}
