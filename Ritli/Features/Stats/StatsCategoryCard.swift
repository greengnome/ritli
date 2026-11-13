import SwiftUI

struct StatsCategoryCard: View {
    let categories: [CategoryFocusStat]

    private let barHeight: CGFloat = 14
    private let segmentGap: CGFloat = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(.statsCategoriesTitle)
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(RitliTheme.ink)

            if categories.isEmpty {
                ContentUnavailableView {
                    Text(.statsCategoriesEmptyTitle)
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .foregroundStyle(RitliTheme.ink)
                } description: {
                    Text(.statsCategoriesEmptyDescription)
                        .foregroundStyle(RitliTheme.stone)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .accessibilityIdentifier("stats.categories.empty")
            } else {
                stackedBar

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(categories) { category in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(RitliTheme.categoryColor(for: category.colorToken))
                                .frame(width: 8, height: 8)

                            Text(
                                verbatim: FocusCategoryNamePresentation.displayName(
                                    for: category.name
                                )
                            )
                            .font(.subheadline)
                            .foregroundStyle(RitliTheme.ink)
                            .lineLimit(1)

                            Spacer(minLength: 8)

                            Text(category.fraction, format: .percent.precision(.fractionLength(0)))
                                .font(.subheadline.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(RitliTheme.stone)
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RitliTheme.surface,
            in: RoundedRectangle(cornerRadius: RitliTheme.cardRadius)
        )
    }

    /// One bar split by each category's share of focus time.
    private var stackedBar: some View {
        GeometryReader { proxy in
            let gaps = segmentGap * CGFloat(max(categories.count - 1, 0))
            let available = max(proxy.size.width - gaps, 0)

            HStack(spacing: segmentGap) {
                ForEach(categories) { category in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(RitliTheme.categoryColor(for: category.colorToken))
                        .frame(width: max(available * CGFloat(category.fraction), 4))
                }
            }
            .frame(width: proxy.size.width, alignment: .leading)
        }
        .frame(height: barHeight)
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(.statsCategoriesChartAccessibility))
    }
}
