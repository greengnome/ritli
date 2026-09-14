import SwiftUI

struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var animationStart = Date.now
    @State private var hasFinished = false

    let minimumDisplayDuration: Duration
    let onFinished: () -> Void

    var body: some View {
        ZStack {
            Color(.launchBackground)
                .ignoresSafeArea()

            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion || hasFinished)) { context in
                SplashMark(
                    elapsed: reduceMotion ? 0 : max(0, context.date.timeIntervalSince(animationStart))
                )
            }
            .frame(width: 160, height: 160)
            .accessibilityHidden(true)
        }
        .ignoresSafeArea()
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

        animationStart = .now

        try? await Task.sleep(for: minimumDisplayDuration)
        guard !Task.isCancelled else { return }

        hasFinished = true
        onFinished()
    }
}

private struct SplashMark: View {
    @Environment(\.colorScheme) private var colorScheme

    let elapsed: TimeInterval

    // The rings turn and draw back into the brand mark over 950 ms, then
    // hold the finished silhouette before the normal 1.2-second dismissal.
    private var motion: Double {
        let phase = min(elapsed.truncatingRemainder(dividingBy: 1.4) / 0.95, 1)
        return pow(sin(.pi * phase), 2)
    }

    private var ringColors: [Color] {
        colorScheme == .dark
            ? [Color(red: 1, green: 0.976, blue: 0.941), Color(red: 0.945, green: 0.871, blue: 0.808)]
            : [Color(red: 1, green: 0.475, blue: 0.376), Color(red: 1, green: 0.275, blue: 0.204)]
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(RitliTheme.accent.opacity(0.12 * motion))
                .blur(radius: 20)

            SplashRing(radius: 56, startAngle: -30, endAngle: 292)
                .trim(from: 0, to: 1 - 0.5 * motion)
                .stroke(
                    LinearGradient(colors: ringColors, startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 13, lineCap: .round)
                )
                .rotationEffect(.degrees(-65 * motion))

            SplashRing(radius: 35, startAngle: -20, endAngle: 288)
                .trim(from: 0, to: 1 - 0.62 * motion)
                .stroke(
                    LinearGradient(colors: ringColors, startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 13, lineCap: .round)
                )
                .rotationEffect(.degrees(85 * motion))

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 1, green: 0.69, blue: 0.28), Color(red: 1, green: 0.42, blue: 0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 13, height: 34)
                .rotationEffect(.degrees(40 + 12 * motion))
                .scaleEffect(1 + 0.12 * motion)
                .offset(x: 34 + 6 * motion, y: -30 - 7 * motion)
        }
        .shadow(color: RitliTheme.accent.opacity(0.12 * motion), radius: 12, y: 4)
    }
}

private struct SplashRing: Shape {
    let radius: CGFloat
    let startAngle: Double
    let endAngle: Double

    func path(in rect: CGRect) -> Path {
        // Coordinates match the standalone 160 × 160 LaunchMark vectors.
        Path { path in
            path.addArc(
                center: CGPoint(x: rect.midX, y: rect.minY + rect.height * 82 / 160),
                radius: rect.width * radius / 160,
                startAngle: .degrees(startAngle),
                endAngle: .degrees(endAngle),
                clockwise: false
            )
        }
    }
}
