import Foundation
import Testing
@testable import Ritli

struct TimerEngineErrorPresentationTests {
    @Test("Timer errors resolve in English and Ukrainian", arguments: [
        (
            TimerEngineError.activeSessionExists,
            "A timer is already running.",
            "Таймер уже працює."
        ),
        (
            TimerEngineError.noActiveSession,
            "There is no active timer.",
            "Немає активного таймера."
        ),
        (
            TimerEngineError.invalidTransition(from: .completed),
            "This timer action is not available right now.",
            "Ця дія з таймером зараз недоступна."
        ),
        (
            TimerEngineError.focusSessionCannotBeSkipped,
            "Focus sessions cannot be skipped.",
            "Сесії фокусу не можна пропускати."
        ),
    ])
    func localizesMessage(
        error: TimerEngineError,
        english: String,
        ukrainian: String
    ) throws {
        let englishBundle = try localizedBundle(language: "en")
        let ukrainianBundle = try localizedBundle(language: "uk")

        #expect(
            error.message(
                bundle: englishBundle,
                locale: Locale(identifier: "en")
            ) == english
        )
        #expect(
            error.message(
                bundle: ukrainianBundle,
                locale: Locale(identifier: "uk")
            ) == ukrainian
        )
    }

    private func localizedBundle(language: String) throws -> Bundle {
        let resourcePath = try #require(
            Bundle.main.path(forResource: language, ofType: "lproj")
        )
        return try #require(Bundle(path: resourcePath))
    }
}
