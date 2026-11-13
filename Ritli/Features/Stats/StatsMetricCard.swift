import SwiftUI

struct StatsMetricCard<Content: View>: View {
    let title: String
    let value: String
    let comparison: StatsComparisonPresentation
    let valueIdentifier: String
    /// The focus-time card leads the screen with a larger value.
    var valueSize: CGFloat = 28
    /// Charts get a fixed height; plain captions size to fit.
    var contentHeight: CGFloat? = 132
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RitliTheme.stone)

                Text(value)
                    .font(.system(size: valueSize, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(RitliTheme.ink)
                    .accessibilityIdentifier(valueIdentifier)

                Text(comparison.text)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(comparisonColor)
            }

            content
                .frame(height: contentHeight)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RitliTheme.surface,
            in: RoundedRectangle(cornerRadius: RitliTheme.cardRadius)
        )
    }

    private var comparisonColor: Color {
        switch comparison.tone {
        case .positive:
            RitliTheme.leaf
        case .negative:
            RitliTheme.tomatoInk
        case .neutral:
            RitliTheme.stone
        }
    }
}
