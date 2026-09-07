import SwiftUI

struct HomeTaskPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let tasks: [FocusTask]
    @Binding var selectedTaskID: UUID?

    var body: some View {
        NavigationStack {
            List {
                Button {
                    select(nil)
                } label: {
                    selectionRow(
                        title: Text(.homeTaskPickerNoTask),
                        subtitle: Text(.homeTaskPickerNoTaskDescription),
                        iconName: "minus.circle",
                        color: .secondary,
                        isSelected: selectedTaskID == nil
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(.homeTaskPickerSelectNoTask))

                if tasks.isEmpty {
                    ContentUnavailableView(
                        String(localized: .homeTaskPickerEmptyTitle),
                        systemImage: "checklist",
                        description: Text(.homeTaskPickerEmptyDescription)
                    )
                    .listRowBackground(Color.clear)
                } else {
                    Section {
                        ForEach(tasks) { task in
                            Button {
                                select(task.id)
                            } label: {
                                selectionRow(
                                    title: Text(verbatim: task.title),
                                    subtitle: Text(verbatim: taskSubtitle(task)),
                                    iconName: task.category?.iconName ?? "checkmark.circle",
                                    color: task.category?.presentationColor ?? RitliTheme.accent,
                                    isSelected: selectedTaskID == task.id
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(
                                Text(
                                    LocalizedStringResource(
                                        "home.task_picker.select.accessibility",
                                        defaultValue: "Select \(task.title)",
                                        comment: "VoiceOver label for selecting a task from the Home task picker."
                                    )
                                )
                            )
                        }
                    } header: {
                        Text(.homeTaskPickerActiveTasks)
                    }
                }
            }
            .navigationTitle(Text(.homeTaskPickerTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text(.commonActionCancel)
                    }
                }
            }
        }
    }

    private func selectionRow(
        title: Text,
        subtitle: Text,
        iconName: String,
        color: Color,
        isSelected: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                title
                    .foregroundStyle(.primary)
                subtitle
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(RitliTheme.accent)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }

    private func taskSubtitle(_ task: FocusTask) -> String {
        let categoryName = task.category?.displayName
            ?? String(localized: .commonCategoryNone)
        let sessionCount = TimerDisplayFormatter.sessionCount(
            task.estimatedPomodoros
        )
        return "\(categoryName) • \(task.completedPomodoros) / \(sessionCount)"
    }

    private func select(_ taskID: UUID?) {
        selectedTaskID = taskID
        dismiss()
    }
}
