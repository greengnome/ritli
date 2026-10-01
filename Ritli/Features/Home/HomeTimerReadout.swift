import SwiftUI

struct HomeTimerReadout: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let kind: SessionKind
    let state: SessionState?
    let duration: TimeInterval
    let remainingTime: (Date) -> TimeInterval

    var body: some View {
        // Only the readout ticks. The mode menu and controls retain a stable hierarchy.
        if state == .running {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                display(remaining: remainingTime(context.date))
            }
        } else {
            display(remaining: remainingTime(.now))
        }
    }

    @ViewBuilder
    private func display(remaining: TimeInterval) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            readout(remaining: remaining)
        } else {
            let fraction = TimerDisplayFormatter.remainingFraction(remaining, duration: duration)
            ZStack {
                Circle()
                    .stroke(RitliTheme.accentSoft.opacity(0.45), lineWidth: 5)
                    .padding(7)

                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(
                        RitliTheme.accent,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .padding(7)
                    .opacity(fraction > 0 ? 1 : 0)
                    .animation(reduceMotion ? nil : .linear(duration: 1), value: fraction)
                    .accessibilityHidden(true)

                readout(remaining: remaining)
                    .padding(.horizontal, 22)
            }
            .frame(maxWidth: 280)
            .aspectRatio(1, contentMode: .fit)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text(kind.timerAccessibilityLabel))
        }
    }

    private func readout(remaining: TimeInterval) -> some View {
        VStack(spacing: 10) {
            Text(verbatim: TimerDisplayFormatter.countdown(remaining))
                .font(
                    dynamicTypeSize.isAccessibilitySize
                        ? .system(.largeTitle, design: .rounded).weight(.medium)
                        : .system(size: 62, weight: .medium, design: .rounded)
                )
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .accessibilityIdentifier("home.timer.countdown")

            Text(kind.timerSubtitle(state: state, remainingTime: remaining))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("home.timer.status")
        }
    }
}
