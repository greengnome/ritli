import SwiftData
import SwiftUI

struct ArchivedTasksView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [FocusTask]

    @State private var taskPendingDeletion: FocusTask?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if archivedTasks.isEmpty {
                ContentUnavailableView {
                    Label(
                        String(
                            localized: "tasks.archived.empty.title",
                            defaultValue: "No archived tasks"
                        ),
                        systemImage: "archivebox"
                    )
                } description: {
                    Text(
                        String(
                            localized: "tasks.archived.empty.description",
                            defaultValue: "Tasks you archive will appear here."
                        )
                    )
                }
            } else {
                List(archivedTasks) { task in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(task.title)
                            .font(.headline)

                        if let category = task.category {
                            Text(verbatim: category.displayName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            taskPendingDeletion = task
                        } label: {
                            Label(
                                String(
                                    localized: "tasks.archived.delete",
                                    defaultValue: "Delete"
                                ),
                                systemImage: "trash"
                            )
                        }

                        Button {
                            restore(task)
                        } label: {
                            Label(
                                String(
                                    localized: "tasks.archived.restore",
                                    defaultValue: "Restore"
                                ),
                                systemImage: "arrow.uturn.backward"
                            )
                        }
                        .tint(.blue)
                    }
                    .accessibilityIdentifier("tasks.archived.row.\(task.id)")
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(
            String(
                localized: "tasks.archived.title",
                defaultValue: "Archived Tasks"
            )
        )
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized: "common.action.done", defaultValue: "Done")) {
                    dismiss()
                }
            }
        }
        .confirmationDialog(
            String(
                localized: "tasks.archived.delete_confirmation.title",
                defaultValue: "Delete this task permanently?"
            ),
            isPresented: deletionConfirmationIsPresented,
            titleVisibility: .visible
        ) {
            Button(
                String(
                    localized: "tasks.archived.delete_confirmation.action",
                    defaultValue: "Delete Task"
                ),
                role: .destructive
            ) {
                deletePendingTask()
            }
            Button(String(localized: .commonActionCancel), role: .cancel) {
                taskPendingDeletion = nil
            }
        } message: {
            Text(
                String(
                    localized: "tasks.archived.delete_confirmation.message",
                    defaultValue: "Its recorded focus sessions will remain in your history."
                )
            )
        }
        .alert(
            String(localized: .tasksAlertUnavailable),
            isPresented: errorIsPresented
        ) {
            Button(String(localized: .commonActionOk), role: .cancel) {}
        } message: {
            Text(errorMessage ?? String(localized: .commonErrorTryAgain))
        }
        .accessibilityIdentifier("tasks.archived.screen")
    }

    private var archivedTasks: [FocusTask] {
        TaskListPresentation.archivedTasks(from: tasks)
    }

    private var deletionConfirmationIsPresented: Binding<Bool> {
        Binding(
            get: { taskPendingDeletion != nil },
            set: { if !$0 { taskPendingDeletion = nil } }
        )
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func restore(_ task: FocusTask) {
        task.isArchived = false
        saveChanges()
    }

    private func deletePendingTask() {
        guard let task = taskPendingDeletion else { return }
        taskPendingDeletion = nil
        modelContext.delete(task)
        saveChanges()
    }

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
        }
    }
}
