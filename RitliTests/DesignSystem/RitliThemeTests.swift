import SwiftUI
import Testing
import UIKit

@testable import Ritli

struct RitliThemeTests {
    @Test
    func backgroundAdaptsToInterfaceStyle() {
        let light = resolvedColor(RitliTheme.background, style: .light)
        let dark = resolvedColor(RitliTheme.background, style: .dark)

        #expect(relativeLuminance(of: light) > 0.9)
        #expect(relativeLuminance(of: dark) < 0.1)
    }

    @Test
    func surfaceAdaptsToInterfaceStyleAndRemainsAboveBackground() {
        let light = resolvedColor(RitliTheme.surface, style: .light)
        let dark = resolvedColor(RitliTheme.surface, style: .dark)
        let darkBackground = resolvedColor(RitliTheme.background, style: .dark)

        #expect(relativeLuminance(of: light) > 0.9)
        #expect(relativeLuminance(of: dark) < 0.2)
        #expect(
            relativeLuminance(of: dark) > relativeLuminance(of: darkBackground)
        )
    }

    private func resolvedColor(
        _ color: Color,
        style: UIUserInterfaceStyle
    ) -> UIColor {
        UIColor(color).resolvedColor(
            with: UITraitCollection(userInterfaceStyle: style)
        )
    }

    private func relativeLuminance(of color: UIColor) -> CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return 0.2126 * red + 0.7152 * green + 0.0722 * blue
    }
}
