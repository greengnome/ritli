import Foundation

/// Keeps the in-app notification setting consistent with the system
/// permission. Shared by every place that starts a timer or returns to the
/// foreground, so they all behave the same way.
@MainActor
enum TimerNotificationPreference {
    enum StartReadiness: Equatable {
        case ready
        /// The user declined; notifications were turned off in the app.
        case permissionDenied
    }

    /// Asks for permission the first time a timer starts with notifications
    /// on. The timer may start either way; a denial turns notifications off.
    static func prepareForTimerStart(
        permissions: NotificationPermissionService,
        engine: TimerEngine
    ) async throws -> StartReadiness {
        guard engine.settings.notificationsEnabled else { return .ready }

        do {
            let isAuthorized = try await permissions.requestAuthorizationIfNeeded()
            guard !isAuthorized else { return .ready }
            try engine.setNotificationsEnabled(false)
            return .permissionDenied
        } catch {
            try? engine.setNotificationsEnabled(false)
            throw error
        }
    }

    /// Turns notifications off when permission was revoked in iOS Settings.
    static func disableIfDenied(
        permissions: NotificationPermissionService,
        engine: TimerEngine
    ) async throws {
        await permissions.refreshAuthorizationStatus()
        guard permissions.isDenied, engine.settings.notificationsEnabled else {
            return
        }

        try engine.setNotificationsEnabled(false)
    }
}
