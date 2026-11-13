import SwiftData
import SwiftUI

struct FocusHistoryView: View {
    @Query private var sessions: [FocusSession]
    @Query private var tasks: [FocusTask]

    @State private var selectedDate = Date.now

    private let calendar = Calendar.current

    var body: some View {
        let day = selectedDay

        ScrollView {
            VStack(spacing: 18) {
                DatePicker(
                    String(localized: .historyDatePickerLabel),
                    selection: $selectedDate,
                    in: ...Date.now,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(RitliTheme.tomatoInk)
                .padding(10)
                .background(
                    RitliTheme.surface,
                    in: RoundedRectangle(cornerRadius: RitliTheme.cardRadius)
                )
                .accessibilityIdentifier("history.calendar")

                VStack(alignment: .leading, spacing: 14) {
                    Text(selectedDate, format: .dateTime.weekday(.wide).month(.wide).day())
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .foregroundStyle(RitliTheme.ink)

                    FocusHistorySummaryCard(day: day)
                }

                sessionSection(day)
            }
            .padding(.horizontal, RitliTheme.screenPadding)
            .padding(.bottom, 24)
        }
        .background(RitliTheme.paper)
        .navigationTitle(Text(.historyTitle))
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("history.screen")
        .toolbar {
            if !calendar.isDateInToday(selectedDate) {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        selectedDate = .now
                    } label: {
                        Text(.homeSummaryToday)
                    }
                    .accessibilityIdentifier("history.today")
                }
            }
        }
    }

    private var selectedDay: FocusHistoryDay {
        FocusHistoryCalculator(calendar: calendar).day(
            containing: selectedDate,
            sessions: sessions,
            tasks: tasks
        )
    }

    @ViewBuilder
    private func sessionSection(_ day: FocusHistoryDay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(.homeSummarySessions)
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(RitliTheme.ink)

            if day.entries.isEmpty {
                ContentUnavailableView {
                    Text(.historyEmptyTitle)
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .foregroundStyle(RitliTheme.ink)
                } description: {
                    Text(.historyEmptyDescription)
                        .foregroundStyle(RitliTheme.stone)
                }
                .frame(maxWidth: .infinity, minHeight: 180)
                .background(
                    RitliTheme.surface,
                    in: RoundedRectangle(cornerRadius: RitliTheme.cardRadius)
                )
                .accessibilityIdentifier("history.empty")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(day.entries.enumerated()), id: \.element.id) {
                        index,
                        entry in
                        FocusHistoryRow(entry: entry)

                        if index < day.entries.count - 1 {
                            Rectangle()
                                .fill(RitliTheme.hairline)
                                .frame(height: 1)
                                .padding(.leading, 80)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .background(
                    RitliTheme.surface,
                    in: RoundedRectangle(cornerRadius: RitliTheme.cardRadius)
                )
            }
        }
    }
}
