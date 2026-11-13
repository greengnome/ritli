import SwiftUI

/// The timer area of Home: the mode picker (only at rest), the dial, the
/// planned length and the controls. It sits straight on the screen colour.
struct HomeTimerCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let kind: SessionKind
    let state: SessionState?
    let remainingTime: (Date) -> TimeInterval
    let duration: TimeInterval
    let cycle: HomeCycleProgress
    let style: HomeStyle
    let isModeSelectionEnabled: Bool
    let onSelectMode: (SessionKind) -> Void
    let onPrimaryAction: () -> Void
    let onCancel: () -> Void
    let onSkipBreak: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            if isModeSelectionEnabled {
                HomeModePicker(selection: kind, onSelect: onSelectMode)
            }

            HomeTimerReadout(
                kind: kind,
                state: isActive ? state : nil,
                duration: duration,
                cycle: cycle,
                style: style,
                remainingTime: remainingTime
            )

            VStack(spacing: 14) {
                Text(verbatim: TimerDisplayFormatter.sessionDurationLabel(duration))
                    .font(.subheadline)
                    .foregroundStyle(style.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                controls
            }
        }
    }

    private var controls: some View {
        controlLayout {
            if isActive {
                Button(role: .destructive, action: onCancel) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(HomeRoundControlStyle(style: style))
                .accessibilityLabel(Text(.homeTimerActionCancel))
                .accessibilityIdentifier("home.timer.cancel")
            }

            Button(action: onPrimaryAction) {
                primaryLabelLayout {
                    Image(systemName: primarySystemImage)
                    Text(primaryTitle)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .frame(height: dynamicTypeSize.isAccessibilitySize ? nil : RitliTheme.controlHeight)
                .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 12 : 0)
            }
            .buttonStyle(
                RitliFilledButtonStyle(
                    fill: style.primaryFill,
                    foreground: style.primaryForeground
                )
            )
            .accessibilityLabel(Text(primaryTitle))
            .accessibilityIdentifier("home.timer.primary")

            if isActive && kind != .focus {
                Button(action: onSkipBreak) {
                    Image(systemName: "forward.end.fill")
                }
                .buttonStyle(HomeRoundControlStyle(style: style))
                .accessibilityLabel(Text(.homeTimerActionSkipBreak))
                .accessibilityIdentifier("home.timer.skip")
            }
        }
    }

    private var controlLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))
    }

    private var primaryLabelLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(spacing: 10))
    }

    private var isActive: Bool {
        state == .running || state == .paused
    }

    private var primaryTitle: LocalizedStringResource {
        switch state {
        case .running:
            .homeTimerActionPause
        case .paused:
            .homeTimerActionResume
        case .completed, .cancelled, .skipped, .none:
            kind == .focus
                ? .homeTimerActionStartFocus
                : .homeTimerActionStartBreak
        }
    }

    private var primarySystemImage: String {
        switch state {
        case .running:
            "pause.fill"
        case .paused, .completed, .cancelled, .skipped, .none:
            "play.fill"
        }
    }
}

/// Focus, Short break and Long break as three always-visible segments.
private struct HomeModePicker: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let selection: SessionKind
    let onSelect: (SessionKind) -> Void

    var body: some View {
        layout {
            segment(.focus)
            segment(.shortBreak)
            segment(.longBreak)
        }
        .padding(4)
        .background(
            RitliTheme.sand,
            in: RoundedRectangle(cornerRadius: RitliTheme.controlRadius, style: .continuous)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.timer.mode")
    }

    private var layout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 4))
            : AnyLayout(HStackLayout(spacing: 4))
    }

    private func segment(_ mode: SessionKind) -> some View {
        let isSelected = mode == selection
        return Button {
            onSelect(mode)
        } label: {
            Text(mode.title)
                .font(.subheadline.weight(isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? RitliTheme.ink : RitliTheme.stone)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background {
                    if isSelected {
                        Capsule().fill(RitliTheme.surface)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("home.timer.mode.option.\(mode.rawValue)")
    }
}

/// Cancel and Skip: a round control the same height as the primary button.
private struct HomeRoundControlStyle: ButtonStyle {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let style: HomeStyle

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(style.foreground)
            .frame(
                width: dynamicTypeSize.isAccessibilitySize ? nil : RitliTheme.controlHeight,
                height: RitliTheme.controlHeight
            )
            .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil)
            .background(style.controlFill, in: Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
            .contentShape(Capsule())
    }
}
