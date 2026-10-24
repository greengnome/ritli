import SwiftUI

struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @State private var isRevealed = false
    @State private var isLeaving = false
    @State private var hasFinished = false

    let minimumDisplayDuration: Duration
    let onFinished: () -> Void

    var body: some View {
        ZStack {
            Color(.launchBackground)
                .ignoresSafeArea()

            SplashWordmark(isRevealed: isRevealed, animates: !reduceMotion)
                .offset(y: isLeaving ? -12 : 0)
                .accessibilityHidden(true)
        }
        .ignoresSafeArea()
        .opacity(isLeaving ? 0 : 1)
        .allowsHitTesting(!isLeaving)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "Ritli"))
        .accessibilityIdentifier("startup.splash")
        // Wait for the scene to become active so the reveal isn't spent behind
        // the system launch zoom; a backgrounded launch resumes on return.
        .task(id: scenePhase) {
            await presentSplash()
        }
    }

    @MainActor
    private func presentSplash() async {
        guard scenePhase == .active, !hasFinished else { return }

        isRevealed = true

        try? await Task.sleep(for: minimumDisplayDuration)
        guard !Task.isCancelled else { return }

        hasFinished = true
        // The splash fades itself: transactions started from the App struct's
        // state don't reach the window's views, so a removal transition there
        // would cut instead of fade. The parent removes it once it's invisible.
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.4)) {
            isLeaving = true
        } completion: {
            onFinished()
        }
    }
}

/// "Ritli" set with dotless i's whose dots drop in like the ticks of a clock;
/// the last dot is the tilted accent hand from the app icon.
private struct SplashWordmark: View {
    @Environment(\.colorScheme) private var colorScheme

    let isRevealed: Bool
    let animates: Bool

    private static let fontSize: CGFloat = 64
    private static let letters: [Character] = ["R", "ı", "t", "l", "ı"]
    private static let dotIndices = [1, 4]

    private var letterColors: [Color] {
        colorScheme == .dark
            ? [Color(red: 1, green: 0.976, blue: 0.941), Color(red: 0.945, green: 0.871, blue: 0.808)]
            : [Color(red: 1, green: 0.475, blue: 0.376), Color(red: 1, green: 0.275, blue: 0.204)]
    }

    private static let accentGradient = LinearGradient(
        colors: [Color(red: 1, green: 0.69, blue: 0.28), Color(red: 1, green: 0.42, blue: 0.15)],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(Self.letters.enumerated()), id: \.offset) { index, letter in
                Text(String(letter))
                    .opacity(isRevealed ? 1 : 0)
                    .offset(y: isRevealed ? 0 : 18)
                    .animation(letterAnimation(index), value: isRevealed)
                    .overlay(alignment: .top) {
                        if let dot = Self.dotIndices.firstIndex(of: index) {
                            dotView(dot)
                        }
                    }
            }
        }
        .font(.system(size: Self.fontSize, weight: .bold, design: .rounded))
        .foregroundStyle(
            LinearGradient(colors: letterColors, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }

    @ViewBuilder
    private func dotView(_ dot: Int) -> some View {
        let isAccent = dot == 1
        Group {
            if isAccent {
                Capsule()
                    .fill(Self.accentGradient)
                    .frame(width: 10, height: 22)
                    .rotationEffect(.degrees(isRevealed ? 40 : 4))
            } else {
                Circle()
                    .fill(Self.accentGradient)
                    .frame(width: 13, height: 13)
            }
        }
        .offset(y: isAccent ? 4 : 9)
        .offset(y: isRevealed ? 0 : -30)
        .opacity(isRevealed ? 1 : 0)
        .animation(dotAnimation(dot), value: isRevealed)
    }

    private func letterAnimation(_ index: Int) -> Animation? {
        guard animates else { return nil }
        return .smooth(duration: 0.45).delay(0.05 + Double(index) * 0.07)
    }

    private func dotAnimation(_ dot: Int) -> Animation? {
        guard animates else { return nil }
        // Springs land each dot with a small overshoot, like a hand ticking.
        return .spring(response: 0.34, dampingFraction: 0.55).delay(0.5 + Double(dot) * 0.16)
    }
}
