import Testing
import UserNotifications
@testable import Ritli

struct AppNotificationDelegateTests {
    @Test("Sound previews play without presenting a banner")
    func presentsSoundPreview() {
        let options = AppNotificationDelegate.presentationOptions(for: "ritli.timer.sound-preview.sample")
        #expect(options == [.sound])
    }

    @Test("A session completion still shows its banner and sound")
    func presentsSessionCompletion() {
        #expect(AppNotificationDelegate.presentationOptions(for: "ritli.timer.session.sample") == [.banner, .sound])
    }

    @Test("Foreground timer notifications remain visible and audible")
    func presentsForegroundNotifications() {
        let options = AppNotificationDelegate.foregroundPresentationOptions

        #expect(options.contains(.banner))
        #expect(options.contains(.sound))
    }
}
