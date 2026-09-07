import Foundation
import UIKit

enum AppLanguagePresentation {
    static var settingsURL: URL? {
        URL(string: UIApplication.openSettingsURLString)
    }

    static func currentLanguageName(locale: Locale = .current) -> String {
        guard let languageCode = locale.language.languageCode?.identifier else {
            return locale.identifier
        }
        let localizedName = locale.localizedString(forLanguageCode: languageCode)
            ?? languageCode
        return localizedName.capitalized(with: locale)
    }
}
