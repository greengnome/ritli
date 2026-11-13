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

            SplashMark(isRevealed: isRevealed, animates: !reduceMotion)
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

/// The app icon's mark: a rounded "r" and a small tomato. The "r" rises in,
/// the tomato drops and lands with a little squash, then its leaf pops up.
/// Everything settles within about a second, inside the splash's display time.
private struct SplashMark: View {
    let isRevealed: Bool
    let animates: Bool

    @State private var isSquashed = false
    @State private var hasLeaf = false

    /// The mark is drawn in the icon's 192-point grid, shown at this size.
    private static let size: CGFloat = 176
    private static let scale = size / RitliMarkGeometry.grid
    /// How far above its resting place the tomato starts.
    private static let dropHeight: CGFloat = 70 * scale

    var body: some View {
        ZStack {
            RitliMarkLetter()
                .stroke(
                    RitliTheme.ink,
                    style: StrokeStyle(lineWidth: RitliMarkGeometry.letterWidth * Self.scale, lineCap: .round)
                )
                .opacity(isRevealed ? 1 : 0)
                .offset(y: isRevealed ? 0 : 14 * Self.scale)
                .animation(letterAnimation, value: isRevealed)

            RitliMarkTomato()
                .fill(RitliTheme.tomato)
                .scaleEffect(
                    x: isSquashed ? 1.16 : 1,
                    y: isSquashed ? 0.84 : 1,
                    anchor: RitliMarkGeometry.tomatoBase
                )
                .offset(y: isRevealed ? 0 : -Self.dropHeight)
                .animation(dropAnimation, value: isRevealed)
                .opacity(isRevealed ? 1 : 0)
                .animation(appearAnimation, value: isRevealed)

            RitliMarkLeaf()
                .stroke(
                    RitliTheme.leaf,
                    style: StrokeStyle(lineWidth: RitliMarkGeometry.leafWidth * Self.scale, lineCap: .round)
                )
                .scaleEffect(showsLeaf ? 1 : 0.01, anchor: RitliMarkGeometry.leafBase)
                .opacity(showsLeaf ? 1 : 0)
        }
        .frame(width: Self.size, height: Self.size)
        .task(id: isRevealed) {
            await land()
        }
    }

    private var showsLeaf: Bool {
        hasLeaf || (isRevealed && !animates)
    }

    private var letterAnimation: Animation? {
        guard animates else { return nil }
        return .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.35)
    }

    /// The fall accelerates like something dropped.
    private var dropAnimation: Animation? {
        guard animates else { return nil }
        return .timingCurve(0.5, 0, 0.9, 0.5, duration: 0.33).delay(0.29)
    }

    private var appearAnimation: Animation? {
        guard animates else { return nil }
        return .linear(duration: 0.05).delay(0.29)
    }

    /// Squash on impact, spring back, then sprout the leaf.
    @MainActor
    private func land() async {
        guard isRevealed, animates else { return }

        try? await Task.sleep(for: .milliseconds(620))
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: 0.08)) {
            isSquashed = true
        }

        try? await Task.sleep(for: .milliseconds(80))
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.45)) {
            isSquashed = false
        }

        try? await Task.sleep(for: .milliseconds(130))
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.28, dampingFraction: 0.5)) {
            hasLeaf = true
        }
    }
}

/// The mark's shapes in the app icon's 192-point grid (see the AppIcon
/// artwork), so the splash and the icon stay identical.
nonisolated enum RitliMarkGeometry {
    static let grid: CGFloat = 192
    static let letterWidth: CGFloat = 26
    static let leafWidth: CGFloat = 3.6
    static let tomatoCenter = CGPoint(x: 130, y: 124)
    static let tomatoRadius: CGFloat = 15
    /// Where the tomato touches the ground, for the squash.
    static let tomatoBase = UnitPoint(x: 130 / grid, y: 139 / grid)
    /// Where the leaf meets the tomato, for the sprout.
    static let leafBase = UnitPoint(x: 130 / grid, y: 110.6 / grid)

    static func point(_ x: CGFloat, _ y: CGFloat, in rect: CGRect) -> CGPoint {
        CGPoint(
            x: rect.minX + x / grid * rect.width,
            y: rect.minY + y / grid * rect.height
        )
    }
}

/// The lowercase "r": a stem and a shoulder curving right.
nonisolated struct RitliMarkLetter: Shape {
    func path(in rect: CGRect) -> Path {
        let p = { (x: CGFloat, y: CGFloat) in RitliMarkGeometry.point(x, y, in: rect) }
        var path = Path()
        path.move(to: p(72, 66))
        path.addLine(to: p(72, 128))
        path.move(to: p(72, 104))
        path.addCurve(to: p(104, 68), control1: p(72, 82), control2: p(84, 68))
        return path
    }
}

nonisolated struct RitliMarkTomato: Shape {
    func path(in rect: CGRect) -> Path {
        let center = RitliMarkGeometry.point(
            RitliMarkGeometry.tomatoCenter.x,
            RitliMarkGeometry.tomatoCenter.y,
            in: rect
        )
        let radius = RitliMarkGeometry.tomatoRadius / RitliMarkGeometry.grid * rect.width
        return Path(
            ellipseIn: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            )
        )
    }
}

/// Two small strokes curling away from the top of the tomato.
nonisolated struct RitliMarkLeaf: Shape {
    func path(in rect: CGRect) -> Path {
        let p = { (x: CGFloat, y: CGFloat) in RitliMarkGeometry.point(x, y, in: rect) }
        var path = Path()
        path.move(to: p(130, 110.6))
        path.addCurve(to: p(121.4, 107.4), control1: p(127.9, 106.3), control2: p(124.1, 105.8))
        path.move(to: p(130, 110.6))
        path.addCurve(to: p(138.6, 107.4), control1: p(132.1, 106.3), control2: p(135.9, 105.8))
        return path
    }
}
