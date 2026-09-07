import SwiftUI

struct StartupFailureView: View {
    var body: some View {
        ContentUnavailableView {
            Label(
                String(
                    localized: "startup.failure.title",
                    defaultValue: "Ritli couldn't start"
                ),
                systemImage: "exclamationmark.triangle"
            )
        } description: {
            Text(
                String(
                    localized: "startup.failure.message",
                    defaultValue: "Close and reopen the app. Your existing data has not been changed."
                )
            )
        }
        .accessibilityIdentifier("startup.failure")
    }
}
