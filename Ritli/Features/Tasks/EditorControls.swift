import SwiftUI

// Building blocks for the task and routine editors: a labelled block, chips,
// a segmented track and the large title field. They follow the redesign's
// rules: sand tracks, ink for the selection, coral only for focus and progress.

/// A small grey label above a group of controls.
struct EditorSection<Content: View>: View {
    let title: Text
    let content: Content

    init(_ title: Text, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            title
                .font(.footnote.weight(.semibold))
                .foregroundStyle(RitliTheme.stone)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A capsule chip: sand at rest, ink when selected.
struct EditorChip<Label: View>: View {
    let isSelected: Bool
    let action: () -> Void
    let label: Label

    init(isSelected: Bool, action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.isSelected = isSelected
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                label
            }
            .font(.subheadline.weight(isSelected ? .semibold : .medium))
            .foregroundStyle(isSelected ? RitliTheme.paper : RitliTheme.ink)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(isSelected ? RitliTheme.ink : RitliTheme.sand, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// One option in an `EditorSegmentedControl`.
struct EditorSegment<Value: Hashable> {
    let value: Value
    let title: String
    var systemImage: String?
    var accessibilityLabel: String?
}

/// Two to four equal segments on a sand track; the selected one lifts onto
/// the surface colour.
struct EditorSegmentedControl<Value: Hashable>: View {
    let segments: [EditorSegment<Value>]
    let selection: Value
    let onSelect: (Value) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(segments.indices, id: \.self) { index in
                segment(segments[index])
            }
        }
        .padding(4)
        .background(RitliTheme.sand, in: Capsule())
    }

    private func segment(_ segment: EditorSegment<Value>) -> some View {
        let isSelected = segment.value == selection
        return Button {
            onSelect(segment.value)
        } label: {
            HStack(spacing: 6) {
                if let systemImage = segment.systemImage {
                    Image(systemName: systemImage)
                        .font(.footnote.weight(.semibold))
                }
                Text(verbatim: segment.title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .font(.subheadline.weight(isSelected ? .semibold : .medium))
            .foregroundStyle(isSelected ? RitliTheme.ink : RitliTheme.stone)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background {
                if isSelected {
                    Capsule().fill(RitliTheme.surface)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: segment.accessibilityLabel ?? segment.title))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// The large rounded field at the top of an editor, underlined in coral
/// while it has focus.
struct EditorTitleField: View {
    let placeholder: String
    @Binding var text: String
    var focus: FocusState<Bool>.Binding
    let identifier: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(placeholder, text: $text)
                .font(.system(.title, design: .rounded).weight(.heavy))
                .foregroundStyle(RitliTheme.ink)
                .focused(focus)
                .submitLabel(.done)
                .accessibilityIdentifier(identifier)
            Rectangle()
                .fill(focus.wrappedValue ? RitliTheme.tomato : RitliTheme.hairline)
                .frame(height: 2)
        }
    }
}

/// The full-width primary action pinned above the keyboard and home indicator.
struct EditorPrimaryButton: View {
    let title: Text
    var accessibilityLabel: Text?
    let isEnabled: Bool
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            title
                .frame(maxWidth: .infinity)
        }
        .accessibilityLabel(accessibilityLabel ?? title)
        .accessibilityIdentifier(identifier)
        .buttonStyle(
            RitliFilledButtonStyle(
                fill: isEnabled ? RitliTheme.tomatoFill : RitliTheme.sand,
                foreground: isEnabled ? .white : RitliTheme.stone
            )
        )
        .disabled(!isEnabled)
        .padding(.horizontal, RitliTheme.screenPadding)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(RitliTheme.paper)
    }
}
