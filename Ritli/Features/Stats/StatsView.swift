import Charts
import SwiftData
import SwiftUI

struct StatsView: View {
    @Query private var sessions: [FocusSession]
    @Query private var tasks: [FocusTask]

    @State private var selectedPeriod = StatsPeriod.week

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    periodPicker
                    focusTimeCard
                    sessionsCard
                    tasksCard
                    StatsCategoryCard(categories: snapshot.categories)
                }
                .padding(.horizontal, RitliTheme.screenPadding)
                .padding(.bottom, 24)
            }
            .background(RitliTheme.background)
            .navigationTitle(Text(.appTabStats))
            .accessibilityIdentifier("stats.screen")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        FocusHistoryView()
                    } label: {
                        Label {
                            Text(.statsActionFocusHistory)
                        } icon: {
                            Image(systemName: "calendar")
                        }
                    }
                    .accessibilityIdentifier("stats.history")
                }
            }
        }
    }

    private var snapshot: StatsSnapshot {
        StatsCalculator(calendar: calendar).snapshot(
            sessions: sessions,
            tasks: tasks,
            period: selectedPeriod
        )
    }

    private var periodPicker: some View {
        Picker(String(localized: .statsPeriodPicker), selection: $selectedPeriod) {
            ForEach(StatsPeriod.allCases) { period in
                Text(verbatim: period.title()).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("stats.period")
    }

    private var focusTimeCard: some View {
        StatsMetricCard(
            title: String(localized: .homeSummaryFocusTime),
            value: TimerDisplayFormatter.focusedTime(snapshot.current.focusTime),
            comparison: .make(
                comparison: snapshot.focusTimeComparison,
                period: selectedPeriod
            ),
            valueIdentifier: "stats.focusTime.value"
        ) {
            Chart(snapshot.buckets) { bucket in
                BarMark(
                    x: .value(
                        String(localized: .statsChartAxisPeriod),
                        bucket.interval.start
                    ),
                    y: .value(
                        String(localized: .homeSummaryFocusTime),
                        bucket.focusTime
                    )
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [RitliTheme.accentSoft, RitliTheme.accent],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(4)
            }
            .chartXAxis { chartXAxis }
            .chartYAxis(.hidden)
            .overlay {
                if snapshot.current.focusTime == 0 {
                    Text(.statsEmptyNoFocusRecorded)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .accessibilityLabel(Text(.statsChartFocusTimeAccessibility))
            .accessibilityIdentifier("stats.focusTime.chart")
        }
    }

    private var sessionsCard: some View {
        StatsMetricCard(
            title: String(localized: .homeSummarySessions),
            value: "\(snapshot.current.completedSessions)",
            comparison: .make(
                comparison: snapshot.completedSessionsComparison,
                period: selectedPeriod
            ),
            valueIdentifier: "stats.sessions.value"
        ) {
            Chart(snapshot.buckets) { bucket in
                AreaMark(
                    x: .value(
                        String(localized: .statsChartAxisPeriod),
                        bucket.interval.start
                    ),
                    y: .value(
                        String(localized: .homeSummarySessions),
                        bucket.completedSessions
                    )
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [RitliTheme.success.opacity(0.3), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value(
                        String(localized: .statsChartAxisPeriod),
                        bucket.interval.start
                    ),
                    y: .value(
                        String(localized: .homeSummarySessions),
                        bucket.completedSessions
                    )
                )
                .foregroundStyle(RitliTheme.success)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

                PointMark(
                    x: .value(
                        String(localized: .statsChartAxisPeriod),
                        bucket.interval.start
                    ),
                    y: .value(
                        String(localized: .homeSummarySessions),
                        bucket.completedSessions
                    )
                )
                .foregroundStyle(RitliTheme.success)
                .symbolSize(22)
            }
            .chartXAxis { chartXAxis }
            .chartYAxis(.hidden)
            .accessibilityLabel(Text(.statsChartSessionsAccessibility))
            .accessibilityIdentifier("stats.sessions.chart")
        }
    }

    private var tasksCard: some View {
        StatsMetricCard(
            title: String(localized: .homeSummaryTasksDone),
            value: "\(snapshot.current.completedTasks)",
            comparison: .make(
                comparison: snapshot.completedTasksComparison,
                period: selectedPeriod
            ),
            valueIdentifier: "stats.tasks.value"
        ) {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(RitliTheme.success)

                Text(verbatim: selectedPeriod.completedTasksDescription())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @AxisContentBuilder
    private var chartXAxis: some AxisContent {
        AxisMarks(values: axisDates) { value in
            AxisValueLabel {
                if let date = value.as(Date.self) {
                    Text(selectedPeriod.bucketLabel(for: date, calendar: calendar))
                }
            }
            AxisTick().foregroundStyle(.clear)
            AxisGridLine().foregroundStyle(.clear)
        }
    }

    private var axisDates: [Date] {
        let dates = snapshot.buckets.map(\.interval.start)
        let stride: Int

        switch selectedPeriod {
        case .day:
            stride = 4
        case .week:
            stride = 1
        case .month:
            stride = 5
        case .year:
            stride = 2
        }

        return dates.enumerated().compactMap { index, date in
            index.isMultiple(of: stride) ? date : nil
        }
    }
}
