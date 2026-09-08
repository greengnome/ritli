import SwiftUI

struct HomeTaskPickerButton: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let task: FocusTask?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            contentLayout {
                Image(systemName: task?.category?.iconName ?? "checklist")
                    .font(.system(size: 20))
                    .foregroundStyle(task?.category?.presentationColor ?? RitliTheme.accent)
                    .frame(width: 38, height: 38)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Circle())
                    .accessibilityHidden(true)

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
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                    .fixedSize(horizontal: false, vertical: true)
                }

                if !dynamicTypeSize.isAccessibilitySize {
                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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

    private var contentLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))
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
