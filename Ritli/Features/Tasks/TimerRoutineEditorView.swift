import SwiftData
import SwiftUI

struct TimerRoutineEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let routine: TimerRoutine?
    let onSave: (TimerRoutine) -> Void

    @State private var draft: TimerRoutineDraft
    @State private var errorMessage: String?

    init(
        routine: TimerRoutine?,
        defaults: PomodoroSettings?,
        onSave: @escaping (TimerRoutine) -> Void
    ) {
        self.routine = routine
        self.onSave = onSave
        _draft = State(
            initialValue: TimerRoutineDraft(
                routine: routine,
                defaults: defaults
            )
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        String(
                            localized: "tasks.routine.editor.name_placeholder",
                            defaultValue: "e.g. Deep Work"
                        ),
                        text: $draft.name
                    )
                    .accessibilityIdentifier("routine.editor.name")
                } header: {
                    Text(
                        String(
                            localized: "tasks.routine.editor.name",
                            defaultValue: "Name"
                        )
                    )
                }

                Section(
                    String(
                        localized: "settings.timer.section",
                        defaultValue: "Timer"
                    )
                ) {
                    durationPicker(
                        title: String(
                            localized: "settings.timer.focus",
                            defaultValue: "Focus"
                        ),
                        selection: $draft.focusMinutes,
                        options: TimerSettingsDraft.focusMinuteOptions,
                        identifier: "routine.editor.focusDuration"
                    )
                    durationPicker(
                        title: String(
                            localized: "settings.timer.short_break",
                            defaultValue: "Short break"
                        ),
                        selection: $draft.shortBreakMinutes,
                        options: TimerSettingsDraft.shortBreakMinuteOptions,
                        identifier: "routine.editor.shortBreakDuration"
                    )
                    durationPicker(
                        title: String(
                            localized: "settings.timer.long_break",
                            defaultValue: "Long break"
                        ),
                        selection: $draft.longBreakMinutes,
                        options: TimerSettingsDraft.longBreakMinuteOptions,
                        identifier: "routine.editor.longBreakDuration"
                    )
                }

                Section(
                    String(
                        localized: "settings.cycle.section",
                        defaultValue: "Cycle"
                    )
                ) {
                    Picker(
                        String(
                            localized: "settings.timer.long_break",
                            defaultValue: "Long break"
                        ),
                        selection: $draft.longBreakEvery
                    ) {
                        ForEach(
                            TimerSettingsDraft.longBreakIntervalOptions,
                            id: \.self
                        ) { count in
                            Text(
                                verbatim: SettingsPresentation
                                    .longBreakInterval(count)
                            )
                            .tag(count)
                        }
                    }
                    .accessibilityIdentifier("routine.editor.longBreakEvery")

                    Toggle(
                        String(
                            localized: "settings.cycle.auto_start_breaks",
                            defaultValue: "Auto-start breaks"
                        ),
                        isOn: $draft.autoStartBreaks
                    )
                    .accessibilityIdentifier("routine.editor.autoStartBreaks")

                    Toggle(
                        String(
                            localized: "settings.cycle.auto_start_focus",
                            defaultValue: "Auto-start focus"
                        ),
                        isOn: $draft.autoStartFocus
                    )
                    .accessibilityIdentifier("routine.editor.autoStartFocus")
                }
            }
            .navigationTitle(
                String(
                    localized: routine == nil
                        ? "tasks.routine.editor.new.title"
                        : "tasks.routine.editor.edit.title",
                    defaultValue: routine == nil
                        ? "New Timer Routine"
                        : "Edit Timer Routine"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: .commonActionCancel)) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: .tasksActionSave)) {
                        save()
                    }
                    .disabled(!draft.canSave)
                    .accessibilityIdentifier("routine.editor.save")
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
        }
    }

    private func durationPicker(
        title: String,
        selection: Binding<Int>,
        options: [Int],
        identifier: String
    ) -> some View {
        Picker(title, selection: selection) {
            ForEach(options, id: \.self) { minutes in
                Text(verbatim: SettingsPresentation.minutes(minutes))
                    .tag(minutes)
            }
        }
        .accessibilityIdentifier(identifier)
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func save() {
        guard draft.canSave else { return }

        let savedRoutine: TimerRoutine
        if let routine {
            draft.apply(to: routine)
            savedRoutine = routine
        } else {
            let routine = draft.makeRoutine()
            modelContext.insert(routine)
            savedRoutine = routine
        }

        do {
            try modelContext.save()
            onSave(savedRoutine)
            dismiss()
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
        }
    }
}
