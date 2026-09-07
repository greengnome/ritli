import SwiftUI

struct WelcomeView: View {
    @State private var selectedPage = 0

    let onContinue: () -> Void

    private let pages = OnboardingPage.allCases

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedPage) {
                ForEach(Array(pages.enumerated()), id: \.element) { index, page in
                    OnboardingPageView(page: page)
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
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                LinearGradient(
                    colors: [RitliTheme.accent, .orange],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .padding(.horizontal, RitliTheme.screenPadding)
            .padding(.top, 30)
            .accessibilityIdentifier("onboarding.continue")
        }
        .padding(.bottom, 28)
        .background(RitliTheme.background)
    }

    private var pageIndicator: some View {
        HStack(spacing: 12) {
            ForEach(pages.indices, id: \.self) { index in
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedPage = index
                    }
                } label: {
                    Capsule()
                        .fill(
                            index == selectedPage
                                ? RitliTheme.accent
                                : .secondary.opacity(0.18)
                        )
                        .frame(
                            width: index == selectedPage ? 22 : 8,
                            height: 8
                        )
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

        withAnimation(.easeInOut(duration: 0.3)) {
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

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 36)

                OnboardingArtwork(page: page)
                    .frame(width: 270, height: 270)
                    .accessibilityHidden(true)

                VStack(spacing: 12) {
                    Text(page.title)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("onboarding.\(page.rawValue).title")

                    Text(page.message)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 28)

                Spacer(minLength: 24)
            }
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

private struct OnboardingArtwork: View {
    let page: OnboardingPage

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
            Ellipse()
                .trim(from: 0.08, to: 0.82)
                .stroke(
                    RitliTheme.accentSoft.opacity(0.55),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
                .frame(width: 230, height: 135)
                .rotationEffect(.degrees(-42))

            Circle()
                .fill(
                    LinearGradient(
                        colors: [RitliTheme.accent, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 132, height: 132)
                .shadow(color: RitliTheme.accent.opacity(0.2), radius: 20, y: 12)
                .overlay {
                    Text(verbatim: "R")
                        .font(.system(size: 66, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }

            decorativeDots
        }
    }

    private var tasksArtwork: some View {
        VStack(spacing: 14) {
            taskCard(
                title: .onboardingTasksProjectRoadmap,
                progress: Text(verbatim: "2 / 4"),
                color: RitliTheme.accent
            )
            .offset(x: -8)

            taskCard(
                title: .onboardingTasksReadPages,
                progress: Text(.onboardingTasksDone),
                color: RitliTheme.success
            )
            .offset(x: 10)

            taskCard(
                title: .onboardingTasksLearnSpanish,
                progress: Text(verbatim: "1 / 3"),
                color: .purple
            )
            .offset(x: -4)
        }
        .padding(20)
    }

    private var insightsArtwork: some View {
        VStack(spacing: 22) {
            HStack(alignment: .bottom, spacing: 13) {
                bar(height: 48, color: RitliTheme.accentSoft)
                bar(height: 72, color: RitliTheme.accentSoft)
                bar(height: 102, color: RitliTheme.accent)
                bar(height: 64, color: RitliTheme.accentSoft)
                bar(height: 88, color: RitliTheme.accentSoft)
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
        .shadow(color: .black.opacity(0.06), radius: 20, y: 10)
        .padding(10)
    }

    private var decorativeDots: some View {
        ZStack {
            Circle()
                .fill(.purple.opacity(0.65))
                .frame(width: 31, height: 31)
                .offset(x: 102, y: -76)

            Circle()
                .fill(.yellow.opacity(0.8))
                .frame(width: 38, height: 38)
                .offset(x: -107, y: 78)

            Circle()
                .fill(RitliTheme.success.opacity(0.85))
                .frame(width: 15, height: 15)
                .offset(x: 93, y: 102)
        }
    }

    private func taskCard(
        title: LocalizedStringResource,
        progress: Text,
        color: Color
    ) -> some View {
        HStack(spacing: 13) {
            Circle()
                .stroke(color, lineWidth: 3)
                .frame(width: 25, height: 25)

            Text(title)
                .font(.headline)

            Spacer()

            progress
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
        }
        .padding(17)
        .background(RitliTheme.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 5)
        }
        .shadow(color: .black.opacity(0.05), radius: 12, y: 6)
    }

    private func bar(height: CGFloat, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(color)
            .frame(width: 25, height: height)
    }

    private func insightMetric(
        value: Text,
        label: LocalizedStringResource
    ) -> some View {
        VStack(spacing: 4) {
            value
                .font(.title3.weight(.bold))
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
