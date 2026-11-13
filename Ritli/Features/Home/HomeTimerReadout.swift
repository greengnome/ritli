import SwiftUI

/// The dial: a chunky outer ring for the time left in this session and a
/// segmented inner ring for the focus sessions done in the current cycle.
/// It is the app icon's rings, made live.
struct HomeTimerReadout: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let kind: SessionKind
    let state: SessionState?
    let duration: TimeInterval
    let cycle: HomeCycleProgress
    let style: HomeStyle
    let remainingTime: (Date) -> TimeInterval

    var body: some View {
        // Only the readout ticks. The mode picker and controls keep a stable hierarchy.
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
                .frame(maxWidth: .infinity)
        } else {
            let fraction = TimerDisplayFormatter.remainingFraction(remaining, duration: duration)
            ZStack {
                Circle()
                    .stroke(style.track, lineWidth: DialMetrics.outerWidth)
                    .padding(DialMetrics.outerWidth / 2)

                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(
                        style.ring,
                        style: StrokeStyle(lineWidth: DialMetrics.outerWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .padding(DialMetrics.outerWidth / 2)
                    .opacity(fraction > 0 ? 1 : 0)
                    .animation(reduceMotion ? nil : .linear(duration: 1), value: fraction)

                HomeCycleRing(cycle: cycle, style: style)
                    .padding(DialMetrics.cycleInset)

                readout(remaining: remaining)
                    .padding(.horizontal, DialMetrics.cycleInset + 16)
            }
            .frame(maxWidth: 272)
            .aspectRatio(1, contentMode: .fit)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text(kind.timerAccessibilityLabel))
        }
    }

    private func readout(remaining: TimeInterval) -> some View {
        VStack(spacing: 4) {
            Text(verbatim: TimerDisplayFormatter.countdown(remaining))
                .font(
                    dynamicTypeSize.isAccessibilitySize
                        ? .system(.largeTitle, design: .rounded).weight(.heavy)
                        : .system(size: 60, weight: .heavy, design: .rounded)
                )
                .monospacedDigit()
                .foregroundStyle(style.foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.numericText(countsDown: true))
                .accessibilityIdentifier("home.timer.countdown")

            Text(kind.timerSubtitle(state: state, remainingTime: remaining))
                .font(.subheadline)
                .foregroundStyle(style.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("home.timer.status")
        }
    }
}

private enum DialMetrics {
    static let outerWidth: CGFloat = 18
    static let cycleWidth: CGFloat = 8
    /// Outer ring, a gap, then half the cycle stroke.
    static let cycleInset: CGFloat = outerWidth + 14 + cycleWidth / 2
}

/// How far through the long-break cycle the user is.
struct HomeCycleProgress: Equatable {
    let completed: Int
    let length: Int

    init(completed: Int, length: Int) {
        // Keep the ring drawable for odd routines (the settings allow 2...12).
        let length = min(max(length, 1), 12)
        self.length = length
        self.completed = min(max(completed, 0), length)
    }
}

private struct HomeCycleRing: View {
    let cycle: HomeCycleProgress
    let style: HomeStyle

    var body: some View {
        ZStack {
            ForEach(0..<cycle.length, id: \.self) { index in
                Circle()
                    .trim(from: start(of: index), to: end(of: index))
                    .stroke(
                        index < cycle.completed ? style.ring : style.track,
                        style: StrokeStyle(lineWidth: DialMetrics.cycleWidth, lineCap: .round)
                    )
            }
        }
        .rotationEffect(.degrees(-90))
        .accessibilityHidden(true)
    }

    /// A gap between segments, as a fraction of the circle; none for one segment.
    private var gap: CGFloat {
        cycle.length > 1 ? 0.06 : 0
    }

    private func start(of index: Int) -> CGFloat {
        CGFloat(index) / CGFloat(cycle.length) + gap / 2
    }

    private func end(of index: Int) -> CGFloat {
        CGFloat(index + 1) / CGFloat(cycle.length) - gap / 2
    }
}
