import SwiftUI
import UIKit

/// Ritli's own tab bar icons: rounded 2pt strokes on a 24pt grid, in the
/// same hand as the rest of the app. They're template images, so the tab
/// bar tints them like SF Symbols.
enum RitliTabIcon {
    case home
    case stats
    case tasks
    case settings

    var image: Image {
        Image(uiImage: Self.images[self] ?? UIImage())
    }

    private static let images: [RitliTabIcon: UIImage] = [
        .home: render(.home),
        .stats: render(.stats),
        .tasks: render(.tasks),
        .settings: render(.settings),
    ]

    private static func render(_ icon: RitliTabIcon) -> UIImage {
        let size = CGSize(width: 24, height: 24)
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            UIColor.black.setStroke()
            for path in icon.paths {
                path.lineCapStyle = .round
                path.lineJoinStyle = .round
                path.stroke()
            }
        }
        return image.withRenderingMode(.alwaysTemplate)
    }

    private var paths: [UIBezierPath] {
        switch self {
        case .home:
            // A house: roof, walls with rounded feet, and a doorway.
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 4, y: 11))
            path.addLine(to: CGPoint(x: 12, y: 4))
            path.addLine(to: CGPoint(x: 20, y: 11))
            path.addLine(to: CGPoint(x: 20, y: 19))
            path.addQuadCurve(to: CGPoint(x: 19, y: 20), controlPoint: CGPoint(x: 20, y: 20))
            path.addLine(to: CGPoint(x: 15, y: 20))
            path.addLine(to: CGPoint(x: 15, y: 14))
            path.addLine(to: CGPoint(x: 9, y: 14))
            path.addLine(to: CGPoint(x: 9, y: 20))
            path.addLine(to: CGPoint(x: 5, y: 20))
            path.addQuadCurve(to: CGPoint(x: 4, y: 19), controlPoint: CGPoint(x: 4, y: 20))
            path.close()
            path.lineWidth = 2
            return [path]
        case .stats:
            // Three rounded bars.
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 6, y: 20))
            path.addLine(to: CGPoint(x: 6, y: 14))
            path.move(to: CGPoint(x: 12, y: 20))
            path.addLine(to: CGPoint(x: 12, y: 5))
            path.move(to: CGPoint(x: 18, y: 20))
            path.addLine(to: CGPoint(x: 18, y: 11))
            path.lineWidth = 2.6
            return [path]
        case .tasks:
            // Two ticks, each beside a line.
            let path = UIBezierPath()
            for y in [CGFloat(7), 16] {
                path.move(to: CGPoint(x: 4, y: y))
                path.addLine(to: CGPoint(x: 6, y: y + 2))
                path.addLine(to: CGPoint(x: 9, y: y - 2))
                path.move(to: CGPoint(x: 13, y: y))
                path.addLine(to: CGPoint(x: 20, y: y))
            }
            path.lineWidth = 2
            return [path]
        case .settings:
            // Two sliders with their knobs.
            let lines = UIBezierPath()
            lines.move(to: CGPoint(x: 4, y: 8))
            lines.addLine(to: CGPoint(x: 13, y: 8))
            lines.move(to: CGPoint(x: 17, y: 8))
            lines.addLine(to: CGPoint(x: 20, y: 8))
            lines.move(to: CGPoint(x: 4, y: 16))
            lines.addLine(to: CGPoint(x: 7, y: 16))
            lines.move(to: CGPoint(x: 11, y: 16))
            lines.addLine(to: CGPoint(x: 20, y: 16))
            lines.lineWidth = 2
            let topKnob = UIBezierPath(ovalIn: CGRect(x: 13, y: 6, width: 4, height: 4))
            topKnob.lineWidth = 2
            let bottomKnob = UIBezierPath(ovalIn: CGRect(x: 7, y: 14, width: 4, height: 4))
            bottomKnob.lineWidth = 2
            return [lines, topKnob, bottomKnob]
        }
    }
}
