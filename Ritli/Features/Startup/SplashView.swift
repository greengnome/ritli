import SwiftUI

struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isAnimating = false
    @State private var hasFinished = false

    let minimumDisplayDuration: Duration
    let onFinished: () -> Void

    var body: some View {
        ZStack {
            RitliTheme.background
                .ignoresSafeArea()

            SplashMark(isAnimating: isAnimating && !reduceMotion)
                .frame(width: 128, height: 128)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "Ritli"))
        .accessibilityIdentifier("startup.splash")
        .task {
            await presentSplash()
        }
    }

    @MainActor
    private func presentSplash() async {
        guard !hasFinished else { return }

        if !reduceMotion {
            await Task.yield()
            withAnimation(.easeInOut(duration: 0.68)) {
                isAnimating = true
            }
        }

        try? await Task.sleep(for: minimumDisplayDuration)
        guard !Task.isCancelled else { return }

        hasFinished = true
        onFinished()
    }
}

private struct SplashMark: View {
    let isAnimating: Bool

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.08, to: 0.83)
                .stroke(
                    RitliTheme.accent,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(isAnimating ? -20 : -38))

            Circle()
                .trim(from: 0.10, to: 0.78)
                .stroke(
                    RitliTheme.accent,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .padding(22)
                .rotationEffect(.degrees(isAnimating ? -44 : -26))

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [RitliTheme.accent, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 12, height: 30)
                .rotationEffect(.degrees(45))
                .offset(x: 38, y: -39)
                .scaleEffect(isAnimating ? 1.08 : 1)
        }
        .scaleEffect(isAnimating ? 1.04 : 1)
        .shadow(color: RitliTheme.accent.opacity(0.14), radius: 18)
    }
}
