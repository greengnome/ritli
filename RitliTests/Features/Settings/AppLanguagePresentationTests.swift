import Foundation
import Testing
import UIKit
@testable import Ritli

struct AppLanguagePresentationTests {
    @Test("The Settings destination uses Apple's app-specific URL")
    func usesAppSettingsURL() throws {
        let url = try #require(AppLanguagePresentation.settingsURL)

        #expect(url.absoluteString == UIApplication.openSettingsURLString)
    }

    @Test("The current language name is localized", arguments: [
        ("en_US", "English"),
        ("uk_UA", "Українська"),
    ])
    func localizesCurrentLanguageName(localeIdentifier: String, expected: String) {
        let value = AppLanguagePresentation.currentLanguageName(
            locale: Locale(identifier: localeIdentifier)
        )

        #expect(value == expected)
    }
}
