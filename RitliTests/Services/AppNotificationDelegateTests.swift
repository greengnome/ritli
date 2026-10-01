import Foundation
import Testing
import UserNotifications
@testable import Ritli

struct AppNotificationDelegateTests {
    @Test("Sound previews play without presenting a banner")
    func presentsSoundPreview() {
        let options = AppNotificationDelegate.presentationOptions(for: "ritli.timer.sound-playback.sample")
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

    @Test("Only audible custom timer alerts are handed to direct playback", arguments: TimerSound.allCases)
    func recognizesCustomCompletion(sound: TimerSound) {
        let id = UUID()
        let content = UNMutableNotificationContent()
        content.sound = sound.notificationSound
        content.userInfo = ["sessionID": id.uuidString, "timerSound": sound.rawValue]
        let request = UNNotificationRequest(identifier: "ritli.timer.session.\(id)", content: content, trigger: nil)
        let completion = AppNotificationDelegate.customCompletionSound(for: request)
        if sound.fileName != nil {
            #expect(completion?.id == id)
            #expect(completion?.sound == sound)
        } else {
            #expect(completion?.id == nil)
        }
    }
}
