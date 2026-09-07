import SwiftUI

struct StatsMetricCard<Content: View>: View {
    let title: String
    let value: String
    let comparison: StatsComparisonPresentation
    let valueIdentifier: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .accessibilityIdentifier(valueIdentifier)

                Label(comparison.text, systemImage: comparison.systemImage)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(comparisonColor)
            }

            content
                .frame(height: 132)
        }
        .padding(18)
        .background(
            RitliTheme.surface,
            in: RoundedRectangle(cornerRadius: RitliTheme.cardRadius)
        )
        .shadow(color: .black.opacity(0.045), radius: 16, y: 7)
    }

    private var comparisonColor: Color {
        switch comparison.tone {
        case .positive:
            RitliTheme.success
        case .negative:
            RitliTheme.accent
        case .neutral:
            .secondary
        }
    }
}
