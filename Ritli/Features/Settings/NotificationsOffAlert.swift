import SwiftUI
import UIKit

/// Explains that timer alerts are off because iOS permission was declined,
/// with a shortcut to the app's page in iOS Settings.
private struct NotificationsOffAlert: ViewModifier {
    @Environment(\.openURL) private var openURL
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content.alert(
            String(
                localized: "settings.notifications.permission_required.title",
                defaultValue: "Notifications are off"
            ),
            isPresented: $isPresented
        ) {
            Button(
                String(
                    localized: "settings.notifications.open_settings",
                    defaultValue: "Open Settings"
                )
            ) {
                guard let url = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                openURL(url)
            }
            Button(String(localized: .commonActionCancel), role: .cancel) {}
        } message: {
            Text(
                String(
                    localized: "settings.notifications.permission_required",
                    defaultValue: "Enable notifications for Ritli in System Settings to receive timer alerts."
                )
            )
        }
    }
}

extension View {
    func notificationsOffAlert(isPresented: Binding<Bool>) -> some View {
        modifier(NotificationsOffAlert(isPresented: isPresented))
    }
}
