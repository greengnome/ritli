import Charts
import SwiftUI

struct StatsCategoryCard: View {
    let categories: [CategoryFocusStat]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(.statsCategoriesTitle)
                .font(.headline)

            if categories.isEmpty {
                ContentUnavailableView(
                    String(localized: .statsCategoriesEmptyTitle),
                    systemImage: "chart.pie",
                    description: Text(.statsCategoriesEmptyDescription)
                )
                .frame(maxWidth: .infinity, minHeight: 150)
                .accessibilityIdentifier("stats.categories.empty")
            } else {
                HStack(spacing: 22) {
                    Chart(categories) { category in
                        SectorMark(
                            angle: .value(
                                String(localized: .homeSummaryFocusTime),
                                category.focusTime
                            ),
                            innerRadius: .ratio(0.64),
                            angularInset: 1.5
                        )
                        .foregroundStyle(
                            RitliTheme.categoryColor(for: category.colorToken)
                        )
                        .cornerRadius(4)
                    }
                    .frame(width: 128, height: 128)
                    .chartLegend(.hidden)
                    .accessibilityLabel(Text(.statsCategoriesChartAccessibility))

                    VStack(alignment: .leading, spacing: 13) {
                        ForEach(categories.prefix(4)) { category in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(
                                        RitliTheme.categoryColor(
                                            for: category.colorToken
                                        )
                                    )
                                    .frame(width: 9, height: 9)

                                Text(
                                    verbatim: FocusCategoryNamePresentation.displayName(
                                        for: category.name
                                    )
                                )
                                    .font(.subheadline)
                                    .lineLimit(1)

                                Spacer(minLength: 8)

                                Text(category.fraction, format: .percent.precision(.fractionLength(0)))
                                    .font(.subheadline.weight(.semibold))
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(
            RitliTheme.surface,
            in: RoundedRectangle(cornerRadius: RitliTheme.cardRadius)
        )
        .shadow(color: .black.opacity(0.045), radius: 16, y: 7)
    }

}
