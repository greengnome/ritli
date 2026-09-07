import Testing
import UserNotifications
@testable import Ritli

struct AppNotificationDelegateTests {
    @Test("Foreground timer notifications remain visible and audible")
    func presentsForegroundNotifications() {
        let options = AppNotificationDelegate.foregroundPresentationOptions

        #expect(options.contains(.banner))
        #expect(options.contains(.sound))
    }
}
