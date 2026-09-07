import SwiftUI

struct CurrentTaskBanner: View {
    let task: FocusTask

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.category?.iconName ?? "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(task.category?.presentationColor ?? RitliTheme.accent)
                .frame(width: 38, height: 38)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(.homeTaskWorkingOn)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(verbatim: task.title)
                    .font(.headline)
                    .lineLimit(1)
            }

            Spacer()

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
}
