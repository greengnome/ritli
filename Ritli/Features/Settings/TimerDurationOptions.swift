import SwiftUI

/// Choices offered for timer durations, shared by Settings and the
/// per-task routine editor.
enum TimerDurationOptions {
    static let focusMinutes = Array(stride(from: 5, through: 90, by: 5))
    static let shortBreakMinutes = Array(1...30)
    static let longBreakMinutes = Array(stride(from: 5, through: 60, by: 5))
    static let longBreakIntervals = Array(2...8)

    static func minutes(from duration: TimeInterval) -> Int {
        max(1, Int((duration / 60).rounded()))
    }

    static func duration(fromMinutes minutes: Int) -> TimeInterval {
        TimeInterval(max(1, minutes) * 60)
    }
}

struct MinutesPicker: View {
    let title: String
    @Binding var selection: Int
    let options: [Int]
    let identifier: String

    var body: some View {
        Picker(title, selection: $selection) {
            ForEach(options, id: \.self) { minutes in
                Text(verbatim: SettingsPresentation.minutes(minutes))
                    .tag(minutes)
            }
        }
        .accessibilityIdentifier(identifier)
    }
}
