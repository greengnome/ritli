import SwiftUI

struct TaskRow: View {
    let task: FocusTask
    let canStartFocus: Bool
    let onToggleCompletion: () -> Void
    let onStartFocus: () -> Void
    let onEdit: () -> Void
    let onArchive: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Button(action: onToggleCompletion) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isCompleted ? .green : RitliTheme.accent)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                Text(
                    LocalizedStringResource(
                        task.isCompleted
                            ? "tasks.row.reopen.accessibility"
                            : "tasks.row.complete.accessibility",
                        defaultValue: task.isCompleted
                            ? "Reopen \(task.title)"
                            : "Mark \(task.title) complete",
                        comment: "VoiceOver label for changing a task's completion state."
                    )
                )
            )

            Button(action: onEdit) {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(task.title)
                            .font(.headline)
                            .strikethrough(task.isCompleted)
                            .foregroundStyle(task.isCompleted ? .secondary : .primary)

                        Spacer(minLength: 12)

                        if task.priority == .high {
                            Image(systemName: "flag.fill")
                                .foregroundStyle(RitliTheme.accent)
                                .accessibilityLabel(Text(.tasksPriorityHighAccessibility))
                        }
                    }

                    HStack(spacing: 8) {
                        if let category = task.category {
                            Label {
                                Text(verbatim: category.displayName)
                            } icon: {
                                Circle()
                                    .fill(category.presentationColor)
                                    .frame(width: 8, height: 8)
                            }
                        } else {
                            Text(.commonCategoryNone)
                        }

                        Text(verbatim: "•")

                        Text(
                            verbatim: "\(task.completedPomodoros) / \(TimerDisplayFormatter.sessionCount(task.estimatedPomodoros))"
                        )
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    if let dueDate = task.dueDate {
                        Label {
                            Text(dueDate, style: .date)
                        } icon: {
                            Image(systemName: "calendar")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                Text(
                    LocalizedStringResource(
                        "tasks.row.edit.accessibility",
                        defaultValue: "Edit \(task.title)",
                        comment: "VoiceOver label for opening a task editor."
                    )
                )
            )

            if !task.isCompleted {
                Button(action: onStartFocus) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(canStartFocus ? RitliTheme.accent : Color.secondary)
                }
                .buttonStyle(.plain)
                .disabled(!canStartFocus)
                .accessibilityLabel(
                    Text(
                        LocalizedStringResource(
                            "tasks.row.start_focus.accessibility",
                            defaultValue: "Start focus on \(task.title)",
                            comment: "VoiceOver label for starting focus from a task."
                        )
                    )
                )
                .accessibilityHint(
                    Text(
                        canStartFocus
                            ? .tasksRowStartFocusHint
                            : .tasksRowTimerActiveHint
                    )
                )
            }
        }
        .padding(.vertical, 8)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onArchive()
            } label: {
                Label {
                    Text(.tasksActionArchive)
                } icon: {
                    Image(systemName: "archivebox")
                }
            }

            Button {
                onEdit()
            } label: {
                Label {
                    Text(.tasksActionEdit)
                } icon: {
                    Image(systemName: "pencil")
                }
            }
            .tint(.blue)
        }
    }
}
