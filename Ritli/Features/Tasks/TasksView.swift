import SwiftData
import SwiftUI

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [FocusTask]
    @Query private var categories: [FocusCategory]

    @State private var selectedFilter = TaskListFilter.all
    @State private var editorDestination: TaskEditorDestination?
    @State private var isArchivedTasksPresented = false
    @State private var errorMessage: String?

    let canStartFocus: Bool
    let onStartFocus: (FocusTask) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar

                if visibleTasks.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(visibleTasks) { task in
                            TaskRow(
                                task: task,
                                canStartFocus: canStartFocus,
                                onToggleCompletion: { toggleCompletion(of: task) },
                                onStartFocus: { onStartFocus(task) },
                                onEdit: { editorDestination = .edit(task) },
                                onArchive: { archive(task) }
                            )
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(RitliTheme.background)
            .navigationTitle(Text(.appTabTasks))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isArchivedTasksPresented = true
                    } label: {
                        Label(
                            String(
                                localized: "tasks.archived.title",
                                defaultValue: "Archived Tasks"
                            ),
                            systemImage: "archivebox"
                        )
                    }
                    .accessibilityIdentifier("tasks.archived")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editorDestination = .create
                    } label: {
                        Label {
                            Text(.tasksActionAdd)
                        } icon: {
                            Image(systemName: "plus")
                        }
                    }
                    .accessibilityIdentifier("tasks.add")
                }
            }
        }
        .sheet(item: $editorDestination) { destination in
            TaskEditorView(
                task: destination.task,
                categories: activeCategories
            )
        }
        .sheet(isPresented: $isArchivedTasksPresented) {
            NavigationStack {
                ArchivedTasksView()
            }
        }
        .alert(
            String(localized: .tasksAlertUnavailable),
            isPresented: errorIsPresented
        ) {
            Button(String(localized: .commonActionOk), role: .cancel) {}
        } message: {
            Text(errorMessage ?? String(localized: .commonErrorTryAgain))
        }
    }

    private var activeCategories: [FocusCategory] {
        categories
            .filter { !$0.isArchived }
            .sorted {
                if $0.sortOrder == $1.sortOrder {
                    return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
                return $0.sortOrder < $1.sortOrder
            }
    }

    private var visibleTasks: [FocusTask] {
        TaskListPresentation.visibleTasks(from: tasks, filter: selectedFilter)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                filterButton(
                    title: String(localized: .tasksFilterAll),
                    identifier: "tasks.filter.all",
                    filter: .all,
                    color: RitliTheme.accent
                )

                ForEach(activeCategories) { category in
                    filterButton(
                        title: category.displayName,
                        identifier: "tasks.filter.category.\(category.id)",
                        filter: .category(category.id),
                        color: category.presentationColor
                    )
                }
            }
            .padding(.horizontal, RitliTheme.screenPadding)
            .padding(.vertical, 12)
        }
        .background(.background)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(emptyTitle, systemImage: "checklist")
        } description: {
            Text(emptyDescription)
        } actions: {
            Button {
                editorDestination = .create
            } label: {
                Text(.tasksActionCreate)
            }
            .buttonStyle(.borderedProminent)
            .tint(RitliTheme.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("tasks.empty")
    }

    private var emptyTitle: LocalizedStringResource {
        selectedFilter == .all
            ? .tasksEmptyAllTitle
            : .tasksEmptyCategoryTitle
    }

    private var emptyDescription: LocalizedStringResource {
        selectedFilter == .all
            ? .tasksEmptyAllDescription
            : .tasksEmptyCategoryDescription
    }

    private func filterButton(
        title: String,
        identifier: String,
        filter: TaskListFilter,
        color: Color
    ) -> some View {
        let isSelected = selectedFilter == filter

        return Button {
            selectedFilter = filter
        } label: {
            Text(verbatim: title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 17)
                .padding(.vertical, 9)
                .background(isSelected ? color : Color.secondary.opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func toggleCompletion(of task: FocusTask) {
        if task.isCompleted {
            task.reopen()
        } else {
            task.complete()
        }
        saveChanges()
    }

    private func archive(_ task: FocusTask) {
        task.isArchived = true
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

private enum TaskEditorDestination: Identifiable {
    case create
    case edit(FocusTask)

    var id: String {
        switch self {
        case .create:
            "create"
        case .edit(let task):
            task.id.uuidString
        }
    }

    var task: FocusTask? {
        switch self {
        case .create:
            nil
        case .edit(let task):
            task
        }
    }
}
