import SwiftData
import SwiftUI

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var routines: [TimerRoutine]
    @Query private var settings: [PomodoroSettings]

    let task: FocusTask?
    let categories: [FocusCategory]

    @State private var draft: TaskEditorDraft
    @State private var errorMessage: String?
    @State private var routineEditorDestination: RoutineEditorDestination?

    init(task: FocusTask?, categories: [FocusCategory]) {
        self.task = task
        self.categories = categories
        _draft = State(initialValue: TaskEditorDraft(task: task))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        String(localized: .tasksEditorTitlePlaceholder),
                        text: $draft.title
                    )
                        .accessibilityIdentifier("tasks.editor.title")
                } header: {
                    Text(.tasksEditorTaskSection)
                }

                Section {
                    Picker(
                        String(localized: .tasksEditorCategory),
                        selection: $draft.categoryID
                    ) {
                        Text(.commonCategoryNone).tag(nil as UUID?)
                        ForEach(categories) { category in
                            Label {
                                Text(verbatim: category.displayName)
                            } icon: {
                                Image(systemName: category.iconName ?? "tag.fill")
                            }
                                .tag(category.id as UUID?)
                        }
                    }

                    Stepper(
                        focusEstimateLabel,
                        value: $draft.estimatedPomodoros,
                        in: 1...24
                    )
                    .accessibilityIdentifier("tasks.editor.estimate")

                    Picker(
                        String(localized: .tasksEditorPriority),
                        selection: $draft.priority
                    ) {
                        Text(.tasksPriorityLow).tag(TaskPriority.low)
                        Text(.tasksPriorityNormal).tag(TaskPriority.normal)
                        Text(.tasksPriorityHigh).tag(TaskPriority.high)
                    }

                    Toggle(
                        String(localized: .tasksEditorDueDate),
                        isOn: $draft.includesDueDate
                    )

                    if draft.includesDueDate {
                        DatePicker(
                            String(localized: .tasksEditorDate),
                            selection: $draft.dueDate,
                            displayedComponents: .date
                        )
                    }
                } header: {
                    Text(.tasksEditorPlanSection)
                }

                timerRoutineSection

                Section {
                    TextField(
                        String(localized: .tasksEditorNotesPlaceholder),
                        text: $draft.notes,
                        axis: .vertical
                    )
                        .lineLimit(3...6)
                        .accessibilityIdentifier("tasks.editor.notes")
                } header: {
                    Text(.tasksEditorNotesSection)
                }
            }
            .navigationTitle(
                Text(task == nil ? .tasksEditorNewTitle : .tasksEditorEditTitle)
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text(.commonActionCancel)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        save()
                    } label: {
                        Text(task == nil ? .tasksActionAddShort : .tasksActionSave)
                    }
                    .disabled(!draft.canSave)
                    .accessibilityLabel(
                        Text(
                            task == nil
                                ? .tasksActionAdd
                                : .tasksActionSaveAccessibility
                        )
                    )
                    .accessibilityIdentifier("tasks.editor.save")
                }
            }
            .alert(
                String(localized: .tasksAlertSaveFailed),
                isPresented: errorIsPresented
            ) {
                Button(String(localized: .commonActionOk), role: .cancel) {}
            } message: {
                Text(errorMessage ?? String(localized: .commonErrorTryAgain))
            }
            .sheet(item: $routineEditorDestination) { destination in
                TimerRoutineEditorView(
                    routine: destination.routine,
                    defaults: settings.first
                ) { savedRoutine in
                    draft.timerRoutineID = savedRoutine.id
                }
            }
        }
    }

    private var timerRoutineSection: some View {
        Section {
            Picker(
                String(
                    localized: "tasks.editor.routine.picker",
                    defaultValue: "Routine"
                ),
                selection: $draft.timerRoutineID
            ) {
                Text(
                    String(
                        localized: "tasks.editor.routine.app_defaults",
                        defaultValue: "App Defaults"
                    )
                )
                .tag(nil as UUID?)

                ForEach(sortedRoutines) { routine in
                    Text(verbatim: routine.name)
                        .tag(routine.id as UUID?)
                }
            }
            .accessibilityIdentifier("tasks.editor.routinePicker")

            if let selectedRoutine {
                LabeledContent(
                    String(
                        localized: "settings.timer.focus",
                        defaultValue: "Focus"
                    ),
                    value: SettingsPresentation.minutes(
                        Int((selectedRoutine.focusDuration / 60).rounded())
                    )
                )

                LabeledContent(
                    String(
                        localized: "settings.timer.short_break",
                        defaultValue: "Short break"
                    ),
                    value: SettingsPresentation.minutes(
                        Int((selectedRoutine.shortBreakDuration / 60).rounded())
                    )
                )

                Button {
                    routineEditorDestination = .edit(selectedRoutine)
                } label: {
                    Text(
                        String(
                            localized: "tasks.editor.routine.edit",
                            defaultValue: "Edit Routine"
                        )
                    )
                }
                .accessibilityIdentifier("tasks.editor.routineEdit")
            }

            Button {
                routineEditorDestination = .create
            } label: {
                Label(
                    String(
                        localized: "tasks.editor.routine.create",
                        defaultValue: "Create Custom Routine"
                    ),
                    systemImage: "plus.circle"
                )
            }
            .accessibilityIdentifier("tasks.editor.routineCreate")
        } header: {
            Text(
                String(
                    localized: "tasks.editor.routine.section",
                    defaultValue: "Timer Routine"
                )
            )
        } footer: {
            Text(
                String(
                    localized: "tasks.editor.routine.footer",
                    defaultValue: "App Defaults follow Settings. Custom routines can be reused by other tasks."
                )
            )
        }
    }

    private var sortedRoutines: [TimerRoutine] {
        routines.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private var selectedRoutine: TimerRoutine? {
        sortedRoutines.first { $0.id == draft.timerRoutineID }
    }

    private var focusEstimateLabel: String {
        let count = TimerDisplayFormatter.sessionCount(draft.estimatedPomodoros)
        return String(
            localized: "tasks.editor.focus_estimate",
            defaultValue: "Focus estimate: \(count)"
        )
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func save() {
        guard draft.canSave else { return }

        if let task {
            draft.apply(
                to: task,
                categories: categories,
                routines: routines
            )
        } else {
            let nextSortOrder = (try? modelContext.fetchCount(FetchDescriptor<FocusTask>())) ?? 0
            modelContext.insert(
                draft.makeTask(
                    categories: categories,
                    routines: routines,
                    sortOrder: nextSortOrder
                )
            )
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
        }
    }
}

private enum RoutineEditorDestination: Identifiable {
    case create
    case edit(TimerRoutine)

    var id: String {
        switch self {
        case .create:
            "create"
        case .edit(let routine):
            routine.id.uuidString
        }
    }

    var routine: TimerRoutine? {
        switch self {
        case .create:
            nil
        case .edit(let routine):
            routine
        }
    }
}
