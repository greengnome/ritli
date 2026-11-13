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
    @State private var isPickingDate = false
    @State private var showsNotes: Bool
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isNotesFocused: Bool

    init(task: FocusTask?, categories: [FocusCategory]) {
        self.task = task
        self.categories = categories
        let draft = TaskEditorDraft(task: task)
        _draft = State(initialValue: draft)
        _showsNotes = State(initialValue: !draft.notes.isEmpty)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    EditorSection(Text(.tasksEditorTaskSection)) {
                        EditorTitleField(
                            placeholder: String(localized: .tasksEditorTitlePlaceholder),
                            text: $draft.title,
                            focus: $isTitleFocused,
                            identifier: "tasks.editor.title"
                        )
                    }

                    categorySection
                    sessionsSection
                    prioritySection
                    dueSection
                    timerRoutineSection
                    notesSection
                }
                .padding(.horizontal, RitliTheme.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(RitliTheme.paper)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                EditorPrimaryButton(
                    title: Text(task == nil ? .tasksActionAdd : .tasksActionSave),
                    accessibilityLabel: Text(task == nil ? .tasksActionAdd : .tasksActionSaveAccessibility),
                    isEnabled: draft.canSave,
                    identifier: "tasks.editor.save",
                    action: save
                )
            }
            .navigationTitle(
                Text(task == nil ? .tasksEditorNewTitle : .tasksEditorEditTitle)
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RitliTheme.paper, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text(.commonActionCancel)
                    }
                    .tint(RitliTheme.stone)
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

    // MARK: Category

    private var categorySection: some View {
        EditorSection(Text(.tasksEditorCategory)) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    EditorChip(isSelected: draft.categoryID == nil) {
                        draft.categoryID = nil
                    } label: {
                        Text(.commonCategoryNone)
                    }

                    ForEach(categories, id: \.id) { category in
                        EditorChip(isSelected: draft.categoryID == category.id) {
                            draft.categoryID = category.id
                        } label: {
                            Circle()
                                .fill(category.presentationColor)
                                .frame(width: 8, height: 8)
                            Text(verbatim: category.displayName)
                        }
                    }
                }
            }
            .scrollClipDisabled()
        }
    }

    // MARK: Sessions

    /// Dots cover the usual range; − and + reach the rest (up to 24).
    private static let sessionDots = 8
    private static let maximumSessions = 24

    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(.homeSummarySessions)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(RitliTheme.stone)
                Spacer(minLength: 12)
                Text(sessionsCaption)
                    .font(.footnote)
                    .foregroundStyle(RitliTheme.stone)
                    .multilineTextAlignment(.trailing)
            }

            HStack(spacing: 0) {
                ForEach(1...Self.sessionDots, id: \.self) { count in
                    sessionDot(count)
                }

                Button {
                    draft.estimatedPomodoros = max(1, draft.estimatedPomodoros - 1)
                } label: {
                    Image(systemName: "minus")
                }
                .buttonStyle(RitliIconButtonStyle(size: 36))
                .frame(width: 44, height: 44)
                .disabled(draft.estimatedPomodoros <= 1)
                .accessibilityLabel(Text(Self.fewerSessions))

                Button {
                    draft.estimatedPomodoros = min(Self.maximumSessions, draft.estimatedPomodoros + 1)
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(RitliIconButtonStyle(size: 36))
                .frame(width: 44, height: 44)
                .disabled(draft.estimatedPomodoros >= Self.maximumSessions)
                .accessibilityLabel(Text(Self.moreSessions))
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("tasks.editor.estimate")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sessionDot(_ count: Int) -> some View {
        let isFilled = count <= draft.estimatedPomodoros
        return Button {
            draft.estimatedPomodoros = count
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .strokeBorder(RitliTheme.stone.opacity(0.6), lineWidth: 2)
                        .opacity(isFilled ? 0 : 1)
                    Circle()
                        .fill(RitliTheme.tomato)
                        .opacity(isFilled ? 1 : 0)
                }
                .frame(width: 22, height: 22)

                Text(verbatim: "\(count)")
                    .font(.caption2)
                    .foregroundStyle(RitliTheme.stone)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: TimerDisplayFormatter.sessionCount(count)))
        .accessibilityAddTraits(count == draft.estimatedPomodoros ? .isSelected : [])
    }

    /// "3 sessions · About 1h 15m of focus", using the chosen routine's length.
    private var sessionsCaption: String {
        let focus = selectedRoutine?.focusDuration
            ?? settings.first?.focusDuration
            ?? 25 * 60
        let total = TimerDisplayFormatter.focusedTime(focus * Double(draft.estimatedPomodoros))
        let estimate = String(
            localized: LocalizedStringResource(
                "tasks.editor.sessions.estimate",
                defaultValue: "About \(total) of focus",
                comment: "Beside the session dots in the task editor: the focus time the planned sessions add up to."
            )
        )
        return "\(TimerDisplayFormatter.sessionCount(draft.estimatedPomodoros)) · \(estimate)"
    }

    private static let fewerSessions = LocalizedStringResource(
        "tasks.editor.sessions.fewer",
        defaultValue: "Fewer sessions",
        comment: "VoiceOver label for the button that lowers a task's planned sessions."
    )

    private static let moreSessions = LocalizedStringResource(
        "tasks.editor.sessions.more",
        defaultValue: "More sessions",
        comment: "VoiceOver label for the button that raises a task's planned sessions."
    )

    // MARK: Priority

    private var prioritySection: some View {
        EditorSection(Text(.tasksEditorPriority)) {
            EditorSegmentedControl(
                segments: [
                    EditorSegment(value: TaskPriority.low, title: String(localized: .tasksPriorityLow)),
                    EditorSegment(value: TaskPriority.normal, title: String(localized: .tasksPriorityNormal)),
                    EditorSegment(value: TaskPriority.high, title: String(localized: .tasksPriorityHigh)),
                ],
                selection: draft.priority
            ) { priority in
                draft.priority = priority
            }
        }
    }

    // MARK: Due date

    private enum DueChoice: Hashable {
        case noDate
        case today
        case tomorrow
        case date
    }

    private var dueChoice: DueChoice {
        guard draft.includesDueDate else { return .noDate }
        if isPickingDate { return .date }
        let calendar = Calendar.current
        if calendar.isDateInToday(draft.dueDate) { return .today }
        if calendar.isDateInTomorrow(draft.dueDate) { return .tomorrow }
        return .date
    }

    private var dueSection: some View {
        EditorSection(Text(dueTitle)) {
            EditorSegmentedControl(
                segments: [
                    EditorSegment(value: DueChoice.noDate, title: String(localized: dueNone)),
                    EditorSegment(value: DueChoice.today, title: String(localized: dueToday)),
                    EditorSegment(value: DueChoice.tomorrow, title: String(localized: dueTomorrow)),
                    EditorSegment(
                        value: DueChoice.date,
                        title: dateSegmentTitle,
                        systemImage: "calendar",
                        accessibilityLabel: String(localized: .tasksEditorDate)
                    ),
                ],
                selection: dueChoice,
                onSelect: selectDue
            )

            if dueChoice == .date {
                DatePicker(
                    String(localized: .tasksEditorDate),
                    selection: $draft.dueDate,
                    in: Calendar.current.startOfDay(for: .now)...,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .font(.subheadline)
                .foregroundStyle(RitliTheme.ink)
            }
        }
    }

    /// The fourth segment shows the picked day once there is one.
    private var dateSegmentTitle: String {
        guard dueChoice == .date else {
            return String(localized: .tasksEditorDate)
        }
        return draft.dueDate.formatted(.dateTime.month(.abbreviated).day())
    }

    private func selectDue(_ choice: DueChoice) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        switch choice {
        case .noDate:
            draft.includesDueDate = false
            isPickingDate = false
        case .today:
            draft.includesDueDate = true
            draft.dueDate = today
            isPickingDate = false
        case .tomorrow:
            draft.includesDueDate = true
            draft.dueDate = calendar.date(byAdding: .day, value: 1, to: today) ?? today
            isPickingDate = false
        case .date:
            if dueChoice != .date {
                draft.dueDate = calendar.date(byAdding: .day, value: 2, to: today) ?? today
            }
            draft.includesDueDate = true
            isPickingDate = true
        }
    }

    private let dueTitle = LocalizedStringResource(
        "tasks.editor.due", defaultValue: "Due",
        comment: "Label above the due-date choices in the task editor."
    )
    private let dueNone = LocalizedStringResource(
        "tasks.editor.due.none", defaultValue: "None",
        comment: "Due-date choice: the task has no due date."
    )
    private let dueToday = LocalizedStringResource(
        "tasks.editor.due.today", defaultValue: "Today",
        comment: "Due-date choice: due today."
    )
    private let dueTomorrow = LocalizedStringResource(
        "tasks.editor.due.tomorrow", defaultValue: "Tomorrow",
        comment: "Due-date choice: due tomorrow."
    )

    // MARK: Timer routine

    private var timerRoutineSection: some View {
        EditorSection(
            Text(
                String(
                    localized: "settings.timer.section",
                    defaultValue: "Timer"
                )
            )
        ) {
            Menu {
                Picker(selection: $draft.timerRoutineID) {
                    Text(appDefaultsTitle)
                        .tag(nil as UUID?)

                    ForEach(sortedRoutines, id: \.id) { routine in
                        Text(verbatim: routine.name)
                            .tag(routine.id as UUID?)
                    }
                } label: {
                    EmptyView()
                }
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: selectedRoutine?.name ?? appDefaultsTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(RitliTheme.ink)
                        Text(verbatim: routineSummary)
                            .font(.footnote)
                            .foregroundStyle(RitliTheme.stone)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(RitliTheme.stone)
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 56)
                .background(
                    RitliTheme.surface,
                    in: RoundedRectangle(cornerRadius: RitliTheme.cardRadius, style: .continuous)
                )
                .contentShape(RoundedRectangle(cornerRadius: RitliTheme.cardRadius, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("tasks.editor.routinePicker")

            HStack(spacing: 20) {
                if let selectedRoutine {
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
                        systemImage: "plus"
                    )
                }
                .accessibilityIdentifier("tasks.editor.routineCreate")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(RitliTheme.tomatoInk)
            .frame(minHeight: 44)
        }
    }

    private var appDefaultsTitle: String {
        String(
            localized: "tasks.editor.routine.app_defaults",
            defaultValue: "App Defaults"
        )
    }

    /// "25 min · 5 min": the focus and short-break lengths the task will use.
    private var routineSummary: String {
        let focus = selectedRoutine?.focusDuration ?? settings.first?.focusDuration ?? 25 * 60
        let shortBreak = selectedRoutine?.shortBreakDuration ?? settings.first?.shortBreakDuration ?? 5 * 60
        let focusText = SettingsPresentation.minutes(Int((focus / 60).rounded()))
        let breakText = SettingsPresentation.minutes(Int((shortBreak / 60).rounded()))
        return "\(focusText) · \(breakText)"
    }

    // MARK: Notes

    @ViewBuilder
    private var notesSection: some View {
        if showsNotes {
            EditorSection(Text(.tasksEditorNotesSection)) {
                TextField(
                    String(localized: .tasksEditorNotesPlaceholder),
                    text: $draft.notes,
                    axis: .vertical
                )
                .lineLimit(3...6)
                .focused($isNotesFocused)
                .padding(14)
                .background(
                    RitliTheme.surface,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .accessibilityIdentifier("tasks.editor.notes")
            }
        } else {
            Button {
                showsNotes = true
                isNotesFocused = true
            } label: {
                Label {
                    Text(addNoteTitle)
                } icon: {
                    Image(systemName: "plus")
                }
                .font(.subheadline)
                .foregroundStyle(RitliTheme.stone)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private let addNoteTitle = LocalizedStringResource(
        "tasks.editor.add_note", defaultValue: "Add a note",
        comment: "Button in the task editor that reveals the notes field."
    )

    private var sortedRoutines: [TimerRoutine] {
        routines.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private var selectedRoutine: TimerRoutine? {
        sortedRoutines.first { $0.id == draft.timerRoutineID }
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(isPresenting: $errorMessage)
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
