import SwiftUI

struct HomeTimerCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private enum ControlMetrics {
        static let height: CGFloat = 52
        static let primaryWidth: CGFloat = 160
    }

    let kind: SessionKind
    let state: SessionState?
    let remainingTime: TimeInterval
    let progress: Double
    let duration: TimeInterval
    let isModeSelectionEnabled: Bool
    let onSelectMode: (SessionKind) -> Void
    let onPrimaryAction: () -> Void
    let onCancel: () -> Void
    let onSkipBreak: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            headerLayout {
                Menu {
                    modeButton(.focus)
                    modeButton(.shortBreak)
                    modeButton(.longBreak)
                } label: {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(RitliTheme.accent)
                            .frame(width: 9, height: 9)
                        Text(kind.title)
                            .font(.subheadline.weight(.semibold))
                            .fixedSize(horizontal: false, vertical: true)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(RitliTheme.accent)
                }
                .disabled(!isModeSelectionEnabled)
                .accessibilityIdentifier("home.timer.mode")

                if !dynamicTypeSize.isAccessibilitySize {
                    Spacer()
                }

                Text(verbatim: TimerDisplayFormatter.durationLabel(duration))
                    .font(.subheadline.weight(.medium))
                    .fixedSize()
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if dynamicTypeSize.isAccessibilitySize {
                timerReadout
            } else {
                ZStack {
                    Circle()
                        .stroke(RitliTheme.accentSoft.opacity(0.45), lineWidth: 7)

                    Circle()
                        .trim(from: 0, to: max(0.002, progress))
                        .stroke(
                            RitliTheme.accent,
                            style: StrokeStyle(lineWidth: 7, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    timerReadout
                }
                .frame(width: 255, height: 255)
                .accessibilityElement(children: .contain)
                .accessibilityLabel(Text(kind.timerAccessibilityLabel))
            }

            controlLayout {
                if isActive {
                    Button(role: .destructive, action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.red)
                            .frame(
                                width: ControlMetrics.height,
                                height: ControlMetrics.height
                            )
                            .background(.red.opacity(0.1), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .frame(
                        width: ControlMetrics.height,
                        height: ControlMetrics.height
                    )
                    .contentShape(Circle())
                    .accessibilityLabel(Text(.homeTimerActionCancel))
                    .accessibilityIdentifier("home.timer.cancel")
                }

                Button(action: onPrimaryAction) {
                    primaryLabelLayout {
                        Image(systemName: primarySystemImage)
                        Text(primaryTitle)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .frame(
                        width: dynamicTypeSize.isAccessibilitySize ? nil : ControlMetrics.primaryWidth,
                        height: dynamicTypeSize.isAccessibilitySize ? nil : ControlMetrics.height
                    )
                    .padding(.horizontal, dynamicTypeSize.isAccessibilitySize ? 16 : 0)
                    .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 12 : 0)
                    .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(RitliTheme.accent, in: RoundedRectangle(cornerRadius: 26))
                .contentShape(RoundedRectangle(cornerRadius: 26))
                .accessibilityLabel(Text(primaryTitle))
                .accessibilityIdentifier("home.timer.primary")

                if isActive && kind != .focus {
                    Button(action: onSkipBreak) {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 17))
                            .frame(
                                width: ControlMetrics.height,
                                height: ControlMetrics.height
                            )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.primary)
                    .background(.thinMaterial, in: Circle())
                    .overlay {
                        Circle()
                            .stroke(.secondary.opacity(0.25), lineWidth: 1)
                    }
                    .contentShape(Circle())
                    .accessibilityLabel(Text(.homeTimerActionSkipBreak))
                    .accessibilityIdentifier("home.timer.skip")
                }
            }
        }
        .padding(22)
        .background(
            RitliTheme.surface,
            in: RoundedRectangle(cornerRadius: RitliTheme.cardRadius)
        )
        .shadow(color: .black.opacity(0.055), radius: 18, y: 8)
    }

    private var headerLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout())
    }

    private var controlLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 16))
            : AnyLayout(HStackLayout(spacing: 16))
    }

    private var primaryLabelLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(spacing: 8))
    }

    private var timerReadout: some View {
        VStack(spacing: 7) {
            Text(verbatim: TimerDisplayFormatter.countdown(remainingTime))
                .font(
                    dynamicTypeSize.isAccessibilitySize
                        ? .system(.largeTitle, design: .rounded).weight(.semibold)
                        : .system(size: 50, weight: .semibold, design: .rounded)
                )
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .accessibilityIdentifier("home.timer.countdown")

            Text(kind.timerSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
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

    private func modeButton(_ mode: SessionKind) -> some View {
        Button {
            onSelectMode(mode)
        } label: {
            Label {
                Text(mode.title)
            } icon: {
                Image(systemName: mode == kind ? "checkmark" : "circle")
            }
        }
    }
}
