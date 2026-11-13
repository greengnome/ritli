import SwiftUI

struct WelcomeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedPage = 0

    let onContinue: () -> Void

    private let pages = OnboardingPage.allCases

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedPage) {
                ForEach(Array(pages.enumerated()), id: \.element) { index, page in
                    OnboardingPageView(page: page, isActive: selectedPage == index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            pageIndicator
                .frame(maxWidth: .infinity, alignment: .leading)
                // Each dot sits in a 44pt target; line its visible edge up with the text.
                .padding(.horizontal, RitliTheme.screenPadding - 10)
                .padding(.top, 8)

            Button(action: advance) {
                Text(
                    selectedPage == pages.indices.last
                        ? .onboardingActionFinish
                        : .onboardingActionContinue
                )
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, minHeight: 58)
                .background(RitliTheme.tomatoFill, in: Capsule())
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, RitliTheme.screenPadding)
            .padding(.top, 30)
            .accessibilityIdentifier("onboarding.continue")
        }
        .padding(.bottom, 28)
        .background(RitliTheme.paper)
    }

    private var pageIndicator: some View {
        HStack(spacing: 0) {
            ForEach(pages.indices, id: \.self) { index in
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                        selectedPage = index
                    }
                } label: {
                    Capsule()
                        .fill(
                            index == selectedPage
                                ? RitliTheme.ink
                                : RitliTheme.hairline
                        )
                        .frame(
                            width: index == selectedPage ? 24 : 8,
                            height: 8
                        )
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    Text(
                        LocalizedStringResource(
                            "onboarding.accessibility.page",
                            defaultValue: "Onboarding page \(index + 1)",
                            comment: "VoiceOver label for an onboarding page indicator."
                        )
                    )
                )
                .accessibilityValue(
                    Text(
                        index == selectedPage
                            ? .onboardingPageSelected
                            : .onboardingPageNotSelected
                    )
                )
                .accessibilityIdentifier("onboarding.page.\(index + 1)")
            }
        }
    }

    private func advance() {
        guard selectedPage < pages.count - 1 else {
            onContinue()
            return
        }

        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
            selectedPage += 1
        }
    }
}

private enum OnboardingPage: String, CaseIterable {
    case focus
    case tasks
    case insights

    var title: LocalizedStringResource {
        switch self {
        case .focus:
            .onboardingFocusTitle
        case .tasks:
            .onboardingTasksTitle
        case .insights:
            .onboardingInsightsTitle
        }
    }

    var message: LocalizedStringResource {
        switch self {
        case .focus:
            .onboardingFocusMessage
        case .tasks:
            .onboardingTasksMessage
        case .insights:
            .onboardingInsightsMessage
        }
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool

    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 600
            let artworkSize: CGFloat = isCompact ? 220 : 300

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer(minLength: 24)

                    AnimatedOnboardingArtwork(page: page, isActive: isActive)
                        .frame(width: 300, height: 300)
                        .scaleEffect(artworkSize / 300)
                        .frame(width: artworkSize, height: artworkSize)
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                        .padding(.bottom, isCompact ? 20 : 36)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(page.title)
                            .font(.system(size: isCompact ? 30 : 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(RitliTheme.ink)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("onboarding.\(page.rawValue).title")

                        Text(page.message)
                            .font(.body)
                            .foregroundStyle(RitliTheme.stone)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, RitliTheme.screenPadding)

                    Spacer(minLength: 24)
                }
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

private struct AnimatedOnboardingArtwork: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var animationStart = Date.now

    let page: OnboardingPage
    let isActive: Bool

    private var isAnimating: Bool {
        isActive && !reduceMotion && scenePhase == .active
    }

    var body: some View {
        // TabView preloads neighboring pages. Drive motion from selection so
        // every page starts fresh, including when revisited or foregrounded.
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !isAnimating)) { context in
            OnboardingArtwork(
                page: page,
                elapsed: isAnimating ? max(0, context.date.timeIntervalSince(animationStart)) : nil
            )
        }
        .onChange(of: isAnimating, initial: true) {
            if isAnimating {
                animationStart = .now
            }
        }
    }
}

/// Each page acts out what it says, using the app's own pieces: the Home
/// dial counts down, a task fills its sessions and gets checked off, and the
/// week's focus adds up. Pages 2 and 3 replay every few seconds while open.
/// With no `elapsed` (Reduce Motion, or a preloaded page) everything shows
/// in its finished state.
private struct OnboardingArtwork: View {
    let page: OnboardingPage
    let elapsed: TimeInterval?

    /// One pass of the task and stats stories, in seconds.
    private static let loop: TimeInterval = 6
    /// A moment in the loop where everything is shown, for the still state.
    private static let settled: TimeInterval = 3.6

    /// Time within the current loop.
    private var time: TimeInterval {
        guard let elapsed else { return Self.settled }
        return elapsed.truncatingRemainder(dividingBy: Self.loop)
    }

    var body: some View {
        switch page {
        case .focus:
            focusArtwork
        case .tasks:
            tasksArtwork
        case .insights:
            insightsArtwork
        }
    }

    // MARK: Focus: the Home dial, counting down

    private var focusArtwork: some View {
        let remaining = max(0, 1_122 - (elapsed ?? 0))
        let chip = OnboardingTiming.progress(elapsed ?? 2, from: 1.2, to: 1.6)
        return VStack(spacing: 20) {
            HomeTimerReadout(
                kind: .focus,
                state: .running,
                duration: 1_500,
                cycle: HomeCycleProgress(completed: 1, length: 4),
                style: .resting,
                remainingTime: { _ in remaining }
            )
            .frame(width: 236, height: 236)

            HStack(spacing: 8) {
                Circle()
                    .fill(RitliTheme.leaf)
                    .frame(width: 8, height: 8)
                Text(.onboardingFocusNextBreak)
                    .font(.footnote)
                    .foregroundStyle(RitliTheme.ink)
            }
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(RitliTheme.surface, in: Capsule())
            .overlay {
                Capsule().stroke(RitliTheme.hairline, lineWidth: 1)
            }
            .opacity(chip)
            .offset(y: (1 - chip) * 8)
        }
    }

    // MARK: Tasks: a session lands, a task gets done

    private var tasksArtwork: some View {
        let t = time
        let thirdDot = OnboardingTiming.progress(t, from: 1.3, to: 1.6)
        let check = OnboardingTiming.progress(t, from: 2.4, to: 2.75)
        let strike = OnboardingTiming.progress(t, from: 2.7, to: 3.3)
        // The next session on the last task pulses, like the dial's current arc.
        let pulse = elapsed.map { 0.6 + 0.4 * cos($0 * .pi / 0.75) } ?? 1

        return VStack(spacing: 0) {
            taskRow(
                index: 0,
                title: .onboardingTasksProjectRoadmap,
                category: "Work",
                dots: [.done, .done, .filling(thirdDot), .empty]
            )
            OnboardingDivider()
            taskRow(
                index: 1,
                title: .onboardingTasksReadPages,
                category: "Study",
                dots: [.done, .done],
                completion: check,
                strike: strike
            )
            OnboardingDivider()
            taskRow(
                index: 2,
                title: .onboardingTasksLearnSpanish,
                category: "Personal",
                dots: [.done, .current(pulse), .empty]
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .frame(width: 300)
        .background(RitliTheme.surface, in: RoundedRectangle(cornerRadius: RitliTheme.cardRadius, style: .continuous))
    }

    private func taskRow(
        index: Int,
        title: LocalizedStringResource,
        category: String,
        dots: [OnboardingDot],
        completion: Double = 0,
        strike: Double = 0
    ) -> some View {
        let entrance = rowEntrance(index)
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(RitliTheme.stone.opacity(0.6), lineWidth: 2)
                Circle()
                    .fill(RitliTheme.leafFill)
                    .opacity(completion)
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.white)
                    .opacity(completion)
            }
            .frame(width: 20, height: 20)
            .scaleEffect(1 + 0.2 * sin(completion * .pi))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(strike > 0.5 ? RitliTheme.stone : RitliTheme.ink)
                    .overlay(alignment: .leading) {
                        GeometryReader { proxy in
                            Rectangle()
                                .fill(RitliTheme.stone)
                                .frame(width: proxy.size.width * strike, height: 1.5)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                Text(verbatim: FocusCategoryNamePresentation.displayName(for: category))
                    .font(.caption)
                    .foregroundStyle(RitliTheme.stone)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                ForEach(dots.indices, id: \.self) { dotIndex in
                    dotView(dots[dotIndex])
                }
            }
        }
        .frame(minHeight: 60)
        .opacity(entrance)
        .offset(y: (1 - entrance) * 12)
    }

    @ViewBuilder
    private func dotView(_ dot: OnboardingDot) -> some View {
        switch dot {
        case .done:
            Circle().fill(RitliTheme.tomato).frame(width: 8, height: 8)
        case .empty:
            Circle().stroke(RitliTheme.stone.opacity(0.6), lineWidth: 1.5).frame(width: 7, height: 7)
                .frame(width: 8, height: 8)
        case let .filling(progress):
            ZStack {
                Circle().stroke(RitliTheme.stone.opacity(0.6), lineWidth: 1.5).frame(width: 7, height: 7)
                Circle().fill(RitliTheme.tomato).opacity(progress)
            }
            .frame(width: 8, height: 8)
            .scaleEffect(1 + 0.4 * sin(progress * .pi))
        case let .current(opacity):
            Circle().fill(RitliTheme.tomato).opacity(opacity).frame(width: 8, height: 8)
        }
    }

    /// Rows slide in one after another, then fade before the loop restarts.
    private func rowEntrance(_ index: Int) -> Double {
        let start = Double(index) * 0.12
        let enter = OnboardingTiming.progress(time, from: start, to: start + 0.48)
        let leave = OnboardingTiming.progress(time, from: 5.5, to: 6)
        return enter * (1 - leave)
    }

    // MARK: Insights: the week adds up

    private static let barHeights: [CGFloat] = [0.18, 0.62, 0.48, 0.88, 0.40, 0.72, 0.06]
    private static let todayIndex = 5

    private var insightsArtwork: some View {
        let t = time
        let leave = OnboardingTiming.progress(t, from: 5.5, to: 6)
        let count = OnboardingTiming.progress(t, from: 0, to: 1.2)
        let minutes = (135 * count).rounded()

        return VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(.onboardingInsightsWeek)
                    .font(.caption)
                    .foregroundStyle(RitliTheme.stone)
                Text(verbatim: TimerDisplayFormatter.focusedTime(minutes * 60))
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(RitliTheme.ink)
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Self.barHeights.indices, id: \.self) { index in
                    bar(index: index, t: t)
                }
            }
            .frame(height: 96, alignment: .bottom)

            categoryBar(t: t)
        }
        .padding(18)
        .frame(width: 300)
        .background(RitliTheme.surface, in: RoundedRectangle(cornerRadius: RitliTheme.cardRadius, style: .continuous))
        .opacity(1 - leave)
    }

    private func bar(index: Int, t: TimeInterval) -> some View {
        let start = Double(index) * 0.06
        let grow = OnboardingTiming.progress(t, from: start, to: start + 0.84)
        var height = Self.barHeights[index]
        if index == Self.todayIndex {
            // Today keeps adding up while you watch.
            height += CGFloat(0.08 * OnboardingTiming.progress(t, from: 1, to: 5.5, curve: .linear))
        }
        return RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(index == Self.todayIndex ? RitliTheme.tomato : RitliTheme.tomatoTrack)
            .frame(height: 96 * height)
            .frame(maxWidth: .infinity)
            .scaleEffect(y: max(0.01, grow), anchor: .bottom)
    }

    private func categoryBar(t: TimeInterval) -> some View {
        let segments: [(share: CGFloat, color: Color)] = [
            (0.52, RitliTheme.tomato),
            (0.31, RitliTheme.categoryColor(for: "blue")),
            (0.17, RitliTheme.categoryColor(for: "purple")),
        ]
        return GeometryReader { proxy in
            let available = proxy.size.width - 6
            HStack(spacing: 3) {
                ForEach(segments.indices, id: \.self) { index in
                    let start = 0.72 + Double(index) * 0.1
                    let grow = OnboardingTiming.progress(t, from: start, to: start + 0.8)
                    Capsule()
                        .fill(segments[index].color)
                        .frame(width: available * segments[index].share)
                        .scaleEffect(x: max(0.01, grow), anchor: .leading)
                }
            }
        }
        .frame(height: 10)
    }
}

private enum OnboardingDot {
    case done
    case empty
    /// Filling in, 0...1.
    case filling(Double)
    /// The next session, pulsing at this opacity.
    case current(Double)
}

private struct OnboardingDivider: View {
    var body: some View {
        Rectangle()
            .fill(RitliTheme.hairline)
            .frame(height: 1)
    }
}

private enum OnboardingTiming {
    enum Curve {
        case easeOut
        case linear
    }

    /// How far `time` is between `start` and `end`, eased, clamped to 0...1.
    static func progress(
        _ time: TimeInterval,
        from start: TimeInterval,
        to end: TimeInterval,
        curve: Curve = .easeOut
    ) -> Double {
        guard end > start else { return time >= end ? 1 : 0 }
        let linear = min(1, max(0, (time - start) / (end - start)))
        switch curve {
        case .easeOut:
            return 1 - pow(1 - linear, 3)
        case .linear:
            return linear
        }
    }
}
