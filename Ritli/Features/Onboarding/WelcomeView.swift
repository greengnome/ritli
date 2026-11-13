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
                VStack(spacing: 0) {
                    Spacer(minLength: 24)

                    AnimatedOnboardingArtwork(page: page, isActive: isActive)
                        .frame(width: 300, height: 300)
                        .scaleEffect(artworkSize / 300)
                        .frame(width: artworkSize, height: artworkSize)
                        .accessibilityHidden(true)
                        .padding(.bottom, isCompact ? 20 : 32)

                    VStack(spacing: 12) {
                        Text(page.title)
                            .font(.system(size: isCompact ? 32 : 38, weight: .heavy, design: .rounded))
                            .foregroundStyle(RitliTheme.ink)
                            .multilineTextAlignment(.center)
                            .accessibilityIdentifier("onboarding.\(page.rawValue).title")

                        Text(page.message)
                            .font(isCompact ? .body : .title3)
                            .foregroundStyle(RitliTheme.stone)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 28)

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
                elapsed: isAnimating ? max(0, context.date.timeIntervalSince(animationStart)) : 0,
                isAnimating: isAnimating
            )
        }
        .onChange(of: isAnimating, initial: true) {
            if isAnimating {
                animationStart = .now
            }
        }
    }
}

private struct OnboardingArtwork: View {
    let page: OnboardingPage
    let elapsed: TimeInterval
    let isAnimating: Bool

    private var entrance: Double {
        guard isAnimating else { return 1 }
        return 1 - pow(1 - min(elapsed / 0.85, 1), 3)
    }

    private func wave(delay: Double = 0) -> Double {
        isAnimating ? sin(elapsed * .pi / 2 - delay) : 0
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

    private var focusArtwork: some View {
        ZStack {
            // A flat sand disc that breathes, behind the white dial.
            Circle()
                .fill(RitliTheme.sand)
                .frame(width: 290, height: 290)
                .scaleEffect(1 + wave() * 0.035)

            Circle()
                .fill(RitliTheme.surface)
                .frame(width: 232, height: 232)
                .overlay {
                    Circle().stroke(RitliTheme.hairline, lineWidth: 1)
                }

            ForEach(0..<60) { tick in
                Capsule()
                    .fill(tick.isMultiple(of: 5) ? RitliTheme.stone : RitliTheme.hairline)
                    .frame(width: 2, height: tick.isMultiple(of: 5) ? 9 : 4)
                    .offset(y: -105)
                    .rotationEffect(.degrees(Double(tick) * 6))
            }

            Circle()
                .stroke(RitliTheme.tomatoTrack, lineWidth: 9)
                .frame(width: 180, height: 180)

            Circle()
                .trim(from: 0, to: entrance * max(0, 1_122 - elapsed) / 1_500)
                .stroke(
                    RitliTheme.tomato,
                    style: StrokeStyle(lineWidth: 9, lineCap: .round)
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 8) {
                Text(.homeTimerModeFocus)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RitliTheme.tomatoInk)

                Text(verbatim: TimerDisplayFormatter.countdown(max(0, 1_122 - elapsed)))
                    .font(.system(size: 43, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(RitliTheme.ink)
                    .contentTransition(.identity)

                HStack(spacing: 4) {
                    ForEach(0..<4) { index in
                        Capsule()
                            .fill(index == 0 ? RitliTheme.tomato : RitliTheme.tomatoTrack)
                            .frame(width: index == 0 ? 16 : 5, height: 5)
                    }
                }
            }

            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(RitliTheme.tomatoInk)
                .frame(width: 52, height: 52)
                .background(RitliTheme.surface, in: RoundedRectangle(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18).stroke(RitliTheme.hairline, lineWidth: 1)
                }
                .rotationEffect(.degrees(-12))
                .offset(x: -105, y: -82 + wave() * 5)

            HStack(spacing: 9) {
                Image(systemName: "cup.and.saucer.fill")
                    .foregroundStyle(RitliTheme.leaf)
                Text(verbatim: "05:00")
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .monospacedDigit()
                    .foregroundStyle(RitliTheme.ink)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RitliTheme.surface, in: Capsule())
            .overlay {
                Capsule().stroke(RitliTheme.hairline, lineWidth: 1)
            }
            .rotationEffect(.degrees(8))
            .offset(x: 83, y: 102 - wave() * 5)
        }
        .scaleEffect(0.92 + entrance * 0.08)
        .opacity(0.3 + entrance * 0.7)
    }

    private var tasksArtwork: some View {
        VStack(spacing: 14) {
            taskCard(
                title: .onboardingTasksProjectRoadmap,
                progress: Text(verbatim: "2 / 4"),
                color: RitliTheme.tomato
            )
            .offset(x: -8 - (1 - entrance) * 25, y: wave() * 4)

            taskCard(
                title: .onboardingTasksReadPages,
                progress: Text(.onboardingTasksDone),
                color: RitliTheme.leaf,
                isComplete: true
            )
            .offset(x: 10 + (1 - entrance) * 25, y: wave(delay: 0.8) * 4)

            taskCard(
                title: .onboardingTasksLearnSpanish,
                progress: Text(verbatim: "1 / 3"),
                color: RitliTheme.categoryColor(for: "purple")
            )
            .offset(x: -4 - (1 - entrance) * 25, y: wave(delay: 1.6) * 4)
        }
        .padding(.horizontal, 8)
        .opacity(0.3 + entrance * 0.7)
    }

    private var insightsArtwork: some View {
        VStack(spacing: 22) {
            HStack(alignment: .bottom, spacing: 13) {
                bar(height: 48, color: RitliTheme.tomatoTrack, index: 0)
                bar(height: 72, color: RitliTheme.tomatoTrack, index: 1)
                bar(height: 102, color: RitliTheme.tomato, index: 2)
                bar(height: 64, color: RitliTheme.tomatoTrack, index: 3)
                bar(height: 88, color: RitliTheme.tomatoTrack, index: 4)
            }
            .frame(height: 112, alignment: .bottom)

            HStack(spacing: 16) {
                insightMetric(
                    value: Text(.onboardingInsightsFocusValue),
                    label: .onboardingInsightsFocusLabel
                )
                insightMetric(
                    value: Text(verbatim: "5"),
                    label: .onboardingInsightsSessionsLabel
                )
            }
        }
        .padding(24)
        .background(RitliTheme.surface, in: RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28).stroke(RitliTheme.hairline, lineWidth: 1)
        }
        .padding(10)
        .offset(y: (1 - entrance) * 18)
        .opacity(0.3 + entrance * 0.7)
    }

    private func taskCard(
        title: LocalizedStringResource,
        progress: Text,
        color: Color,
        isComplete: Bool = false
    ) -> some View {
        HStack(spacing: 13) {
            ZStack {
                if isComplete {
                    Circle()
                        .fill(RitliTheme.leafFill)
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(RitliTheme.onAccent)
                        .scaleEffect(entrance)
                } else {
                    Circle()
                        .stroke(RitliTheme.hairline, lineWidth: 2)
                }
            }
            .frame(width: 25, height: 25)

            HStack(spacing: 8) {
                // The task's category, as a small dot.
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(RitliTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            progress
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isComplete ? RitliTheme.leaf : RitliTheme.stone)
                .fixedSize()
        }
        .padding(17)
        .background(RitliTheme.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18).stroke(RitliTheme.hairline, lineWidth: 1)
        }
    }

    private func bar(height: CGFloat, color: Color, index: Int) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(color)
            .frame(width: 25, height: height)
            .scaleEffect(
                y: max(0.05, entrance * (0.9 + wave(delay: Double(index) * 0.65) * 0.1)),
                anchor: .bottom
            )
    }

    private func insightMetric(
        value: Text,
        label: LocalizedStringResource
    ) -> some View {
        VStack(spacing: 4) {
            value
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(RitliTheme.ink)
            Text(label)
                .font(.caption)
                .foregroundStyle(RitliTheme.stone)
        }
        .frame(maxWidth: .infinity)
    }
}
