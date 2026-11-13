import SwiftUI

struct TaskRow: View {
    let task: FocusTask
    let canStartFocus: Bool
    let onToggleCompletion: () -> Void
    let onStartFocus: () -> Void
    let onEdit: () -> Void
    let onArchive: () -> Void

    /// Beyond this many sessions the dots stop being readable at a glance,
    /// so the row falls back to the "x / y sessions" text.
    private static let maximumProgressDots = 8

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: onToggleCompletion) {
                completionMark
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(completionToggleLabel)

            Button(action: onEdit) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.system(size: 17, weight: .semibold))
                        .strikethrough(task.isCompleted)
                        .foregroundStyle(task.isCompleted ? RitliTheme.stone : RitliTheme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 6) {
                        if let category = task.category {
                            Circle()
                                .fill(category.presentationColor)
                                .frame(width: 8, height: 8)
                                .accessibilityHidden(true)
                        }

                        Text(verbatim: metaLine)
                            .font(.subheadline)
                            .foregroundStyle(RitliTheme.stone)
                    }

                    sessionProgress
                }
                .padding(.vertical, 4)
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
                    Image(systemName: "play.fill")
                }
                .buttonStyle(
                    RitliIconButtonStyle(
                        foreground: canStartFocus ? RitliTheme.tomatoInk : RitliTheme.stone
                    )
                )
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
        .padding(.vertical, 6)
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
            .tint(RitliTheme.stone)
        }
    }

    @ViewBuilder
    private var completionMark: some View {
        if task.isCompleted {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(RitliTheme.leafFill, in: Circle())
        } else {
            Circle()
                .strokeBorder(RitliTheme.stone, lineWidth: 2)
                .frame(width: 22, height: 22)
        }
    }

    /// Category, priority (when important) and due date on one line.
    private var metaLine: String {
        var parts: [String] = [
            task.category?.displayName ?? String(localized: .commonCategoryNone)
        ]
        if task.priority == .high {
            parts.append(String(localized: .tasksPriorityHigh))
        }
        if let dueDate = task.dueDate {
            parts.append(dueDate.formatted(date: .abbreviated, time: .omitted))
        }
        return parts.joined(separator: " · ")
    }

    private var sessionsText: String {
        "\(task.completedPomodoros) / \(TimerDisplayFormatter.sessionCount(task.estimatedPomodoros))"
    }

    private var showsProgressDots: Bool {
        task.estimatedPomodoros > 0
            && task.estimatedPomodoros <= Self.maximumProgressDots
            && task.completedPomodoros <= task.estimatedPomodoros
    }

    @ViewBuilder
    private var sessionProgress: some View {
        if showsProgressDots {
            HStack(spacing: 5) {
                ForEach(0..<task.estimatedPomodoros, id: \.self) { index in
                    if index < task.completedPomodoros {
                        Circle()
                            .fill(RitliTheme.tomato)
                            .frame(width: 8, height: 8)
                    } else {
                        Circle()
                            .strokeBorder(RitliTheme.stone, lineWidth: 1.5)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .padding(.top, 2)
            .accessibilityRepresentation {
                Text(verbatim: sessionsText)
            }
        } else {
            Text(verbatim: sessionsText)
                .font(.subheadline)
                .foregroundStyle(RitliTheme.stone)
        }
    }

    /// Separate literal keys (rather than a ternary) so string extraction
    /// doesn't add the English defaults to the catalog as keys of their own.
    private var completionToggleLabel: Text {
        if task.isCompleted {
            Text(LocalizedStringResource(
                "tasks.row.reopen.accessibility",
                defaultValue: "Reopen \(task.title)",
                comment: "VoiceOver label for changing a task's completion state."
            ))
        } else {
            Text(LocalizedStringResource(
                "tasks.row.complete.accessibility",
                defaultValue: "Mark \(task.title) complete",
                comment: "VoiceOver label for changing a task's completion state."
            ))
        }
    }
}
