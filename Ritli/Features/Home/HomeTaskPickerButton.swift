import SwiftUI

/// The top of Home at rest: the task for the next focus, set as a title,
/// with a round button that opens the picker.
struct HomeTaskPickerButton: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let task: FocusTask?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(.homeTaskWorkingOn)
                        .font(.footnote)
                        .foregroundStyle(RitliTheme.stone)

                    Group {
                        if let task {
                            Text(verbatim: task.title)
                        } else {
                            Text(.homeTaskChoose)
                        }
                    }
                    .font(.system(.title, design: .rounded).weight(.heavy))
                    .foregroundStyle(RitliTheme.ink)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(RitliTheme.ink)
                    .frame(width: 44, height: 44)
                    .background(RitliTheme.sand, in: Circle())
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 64)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(Text(.homeTaskPickerHint))
        .accessibilityIdentifier("home.taskSelector")
    }

    private var accessibilityLabel: Text {
        guard let task else {
            return Text(.homeTaskChoose)
        }

        return Text(
            LocalizedStringResource(
                "home.task.working_on.accessibility",
                defaultValue: "Working on \(task.title)",
                comment: "VoiceOver label for a selected task on Home."
            )
        )
    }
}
