import SwiftUI

/// The top of Home during a focus session: the task being worked on, set
/// as a title on the session colour, with its session progress beneath.
struct CurrentTaskBanner: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let task: FocusTask
    let style: HomeStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(.homeTaskWorkingOn)
                .font(.footnote)
                .foregroundStyle(style.secondary)

            Text(verbatim: task.title)
                .font(.system(.title, design: .rounded).weight(.heavy))
                .foregroundStyle(style.foreground)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                .fixedSize(horizontal: false, vertical: true)

            if let note = task.trimmedNote {
                Text(verbatim: note)
                    .font(.subheadline)
                    .foregroundStyle(style.secondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }

            Text(verbatim: progressText)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(style.secondary)
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
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
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

    private var progressText: String {
        if let category = task.category {
            return "\(category.displayName) · \(task.completedPomodoros) / \(task.estimatedPomodoros)"
        }
        return "\(task.completedPomodoros) / \(task.estimatedPomodoros)"
    }
}
