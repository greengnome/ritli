import SwiftUI

struct CurrentTaskBanner: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let task: FocusTask

    var body: some View {
        contentLayout {
            Image(systemName: task.category?.iconName ?? "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(task.category?.presentationColor ?? RitliTheme.accent)
                .frame(width: 38, height: 38)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(.homeTaskWorkingOn)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(verbatim: task.title)
                    .font(.headline)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !dynamicTypeSize.isAccessibilitySize {
                Spacer()
            }

            Text(verbatim: "\(task.completedPomodoros) / \(task.estimatedPomodoros)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityLabel(
                    Text(
                        LocalizedStringResource(
                            "home.task.progress.accessibility",
                            defaultValue: "Completed: \(task.completedPomodoros) of \(task.estimatedPomodoros)",
                            comment: "VoiceOver description of completed and estimated sessions for the current task."
                        )
                    )
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            Text(
                LocalizedStringResource(
                    "home.task.working_on.accessibility",
                    defaultValue: "Working on \(task.title)",
                    comment: "VoiceOver label for the task attached to the active focus session."
                )
            )
        )
        .accessibilityIdentifier("home.currentTask")
    }

    private var contentLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))
    }
}
