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

    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    EditorSection(
                        Text(
                            String(
                                localized: "tasks.routine.editor.name",
                                defaultValue: "Name"
                            )
                        )
                    ) {
                        EditorTitleField(
                            placeholder: String(
                                localized: "tasks.routine.editor.name_placeholder",
                                defaultValue: "e.g. Deep Work"
                            ),
                            text: $draft.name,
                            focus: $isNameFocused,
                            identifier: "routine.editor.name"
                        )
                    }

                    RoutineCyclePreview(draft: draft)

                    HStack(spacing: 8) {
                        DurationTile(
                            title: focusTitle,
                            minutes: $draft.focusMinutes,
                            options: TimerDurationOptions.focusMinutes,
                            identifier: "routine.editor.focusDuration"
                        )
                        DurationTile(
                            title: shortBreakTitle,
                            minutes: $draft.shortBreakMinutes,
                            options: TimerDurationOptions.shortBreakMinutes,
                            identifier: "routine.editor.shortBreakDuration"
                        )
                        DurationTile(
                            title: longBreakTitle,
                            minutes: $draft.longBreakMinutes,
                            options: TimerDurationOptions.longBreakMinutes,
                            identifier: "routine.editor.longBreakDuration"
                        )
                    }

                    EditorSection(
                        Text(
                            String(
                                localized: "settings.cycle.long_break_frequency",
                                defaultValue: "Long break frequency"
                            )
                        )
                    ) {
                        HStack(spacing: 6) {
                            ForEach(TimerDurationOptions.longBreakIntervals, id: \.self) { count in
                                EditorChip(isSelected: draft.longBreakEvery == count) {
                                    draft.longBreakEvery = count
                                } label: {
                                    Text(verbatim: "\(count)")
                                        .frame(minWidth: 16)
                                }
                                .accessibilityLabel(
                                    Text(verbatim: SettingsPresentation.longBreakInterval(count))
                                )
                            }
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("routine.editor.longBreakEvery")
                    }

                    VStack(spacing: 0) {
                        Toggle(
                            String(
                                localized: "settings.cycle.auto_start_breaks",
                                defaultValue: "Auto-start breaks"
                            ),
                            isOn: $draft.autoStartBreaks
                        )
                        .frame(minHeight: 52)
                        .accessibilityIdentifier("routine.editor.autoStartBreaks")

                        Rectangle()
                            .fill(RitliTheme.hairline)
                            .frame(height: 1)

                        Toggle(
                            String(
                                localized: "settings.cycle.auto_start_focus",
                                defaultValue: "Auto-start focus"
                            ),
                            isOn: $draft.autoStartFocus
                        )
                        .frame(minHeight: 52)
                        .accessibilityIdentifier("routine.editor.autoStartFocus")
                    }
                    .font(.subheadline)
                    .foregroundStyle(RitliTheme.ink)
                    .padding(.horizontal, 16)
                    .background(
                        RitliTheme.surface,
                        in: RoundedRectangle(cornerRadius: RitliTheme.cardRadius, style: .continuous)
                    )
                }
                .padding(.horizontal, RitliTheme.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(RitliTheme.paper)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                EditorPrimaryButton(
                    title: Text(.tasksActionSave),
                    isEnabled: draft.canSave,
                    identifier: "routine.editor.save",
                    action: save
                )
            }
            .navigationTitle(
                routine == nil
                    ? String(
                        localized: "tasks.routine.editor.new.title",
                        defaultValue: "New Timer Routine"
                    )
                    : String(
                        localized: "tasks.routine.editor.edit.title",
                        defaultValue: "Edit Timer Routine"
                    )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RitliTheme.paper, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: .commonActionCancel)) {
                        dismiss()
                    }
                    .tint(RitliTheme.stone)
                }
            }
            .task {
                if routine == nil {
                    isNameFocused = true
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

    private var focusTitle: String {
        String(localized: "settings.timer.focus", defaultValue: "Focus")
    }

    private var shortBreakTitle: String {
        String(localized: "settings.timer.short_break", defaultValue: "Short break")
    }

    private var longBreakTitle: String {
        String(localized: "settings.timer.long_break", defaultValue: "Long break")
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(isPresenting: $errorMessage)
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

/// One full cycle of the routine drawn to scale: focus blocks in coral,
/// short breaks in pale green, the long break in green, with the total time.
private struct RoutineCyclePreview: View {
    let draft: TimerRoutineDraft

    private enum Block {
        case focus
        case shortBreak
        case longBreak
    }

    private var blocks: [(kind: Block, minutes: Int)] {
        var blocks: [(kind: Block, minutes: Int)] = []
        let sessions = max(1, draft.longBreakEvery)
        for index in 0..<sessions {
            blocks.append((kind: Block.focus, minutes: draft.focusMinutes))
            if index < sessions - 1 {
                blocks.append((kind: Block.shortBreak, minutes: draft.shortBreakMinutes))
            } else {
                blocks.append((kind: Block.longBreak, minutes: draft.longBreakMinutes))
            }
        }
        return blocks
    }

    private var totalMinutes: Int {
        blocks.reduce(0) { $0 + $1.minutes }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(cycleTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RitliTheme.ink)
                Spacer(minLength: 12)
                Text(verbatim: TimerDisplayFormatter.focusedTime(TimeInterval(totalMinutes * 60)))
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(RitliTheme.stone)
            }

            GeometryReader { proxy in
                let gaps = CGFloat(blocks.count - 1) * 3
                let available = max(0, proxy.size.width - gaps)
                HStack(spacing: 3) {
                    ForEach(blocks.indices, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(color(for: blocks[index].kind))
                            .frame(
                                width: available * CGFloat(blocks[index].minutes) / CGFloat(max(1, totalMinutes))
                            )
                    }
                }
            }
            .frame(height: 14)
            .animation(.smooth(duration: 0.25), value: draft)

            HStack(spacing: 14) {
                legend(.focus, title: String(localized: "settings.timer.focus", defaultValue: "Focus"))
                legend(.shortBreak, title: String(localized: "settings.timer.short_break", defaultValue: "Short break"))
                legend(.longBreak, title: String(localized: "settings.timer.long_break", defaultValue: "Long break"))
            }
            .font(.caption)
            .foregroundStyle(RitliTheme.stone)
        }
        .padding(16)
        .background(
            RitliTheme.surface,
            in: RoundedRectangle(cornerRadius: RitliTheme.cardRadius, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }

    private func color(for block: Block) -> Color {
        switch block {
        case .focus:
            RitliTheme.tomato
        case .shortBreak:
            RitliTheme.leaf.opacity(0.45)
        case .longBreak:
            RitliTheme.leaf
        }
    }

    private func legend(_ block: Block, title: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color(for: block))
                .frame(width: 8, height: 8)
            Text(verbatim: title)
        }
    }

    private let cycleTitle = LocalizedStringResource(
        "tasks.routine.editor.cycle",
        defaultValue: "One cycle",
        comment: "Heading of the routine editor's to-scale preview of one focus cycle."
    )
}

/// A duration as a tile: its name, the minutes large, and − / + buttons that
/// step through the same choices Settings offers.
private struct DurationTile: View {
    let title: String
    @Binding var minutes: Int
    let options: [Int]
    let identifier: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(verbatim: title)
                .font(.caption)
                .foregroundStyle(RitliTheme.stone)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(verbatim: "\(minutes)")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(RitliTheme.ink)
                    .contentTransition(.numericText())
                Text(unitTitle)
                    .font(.caption)
                    .foregroundStyle(RitliTheme.stone)
            }

            HStack(spacing: 6) {
                Button {
                    step(-1)
                } label: {
                    Image(systemName: "minus")
                }
                .buttonStyle(RitliIconButtonStyle(size: 32))
                .frame(width: 44, height: 44)
                .disabled(previous == nil)
                .accessibilityLabel(Text(shorter))

                Button {
                    step(1)
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(RitliIconButtonStyle(size: 32))
                .frame(width: 44, height: 44)
                .disabled(next == nil)
                .accessibilityLabel(Text(longer))
            }
            .padding(.leading, -6)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RitliTheme.surface,
            in: RoundedRectangle(cornerRadius: RitliTheme.cardRadius, style: .continuous)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(verbatim: title))
        .accessibilityValue(Text(verbatim: SettingsPresentation.minutes(minutes)))
        .accessibilityIdentifier(identifier)
    }

    private var previous: Int? {
        options.last { $0 < minutes }
    }

    private var next: Int? {
        options.first { $0 > minutes }
    }

    private func step(_ direction: Int) {
        guard let value = direction < 0 ? previous : next else { return }
        withAnimation(.smooth(duration: 0.2)) {
            minutes = value
        }
    }

    private let unitTitle = LocalizedStringResource(
        "settings.timer.minutes_unit",
        defaultValue: "min",
        comment: "Unit under a duration value."
    )
    private let shorter = LocalizedStringResource(
        "tasks.routine.editor.shorter",
        defaultValue: "Shorter",
        comment: "VoiceOver label for the button that shortens a routine duration."
    )
    private let longer = LocalizedStringResource(
        "tasks.routine.editor.longer",
        defaultValue: "Longer",
        comment: "VoiceOver label for the button that lengthens a routine duration."
    )
}
