import Foundation
import Testing
@testable import Ritli

struct FocusHistoryEntryPresentationTests {
    @Test("Assigned completed focus resolves in Ukrainian")
    func presentsAssignedCompletedFocus() throws {
        let bundle = try localizedBundle(language: "uk")
        let entry = makeEntry(
            state: .completed,
            taskTitle: "План проєкту",
            categoryName: "Work",
            focusTime: 25 * 60
        )

        #expect(
            FocusHistoryEntryPresentation.taskTitle(
                for: entry,
                bundle: bundle,
                locale: Locale(identifier: "uk")
            ) == "План проєкту"
        )
        #expect(
            FocusHistoryEntryPresentation.detail(
                for: entry,
                bundle: bundle,
                locale: Locale(identifier: "uk")
            ) == "Завершено · Робота"
        )
        #expect(
            FocusHistoryEntryPresentation.accessibilityLabel(
                for: entry,
                bundle: bundle,
                locale: Locale(identifier: "uk")
            ) == "План проєкту, Завершено · Робота, 25 хв"
        )
    }

    @Test("Unassigned cancelled focus resolves in both languages", arguments: [
        ("en", "Unassigned focus", "Cancelled"),
        ("uk", "Фокус без завдання", "Скасовано"),
    ])
    func presentsUnassignedCancelledFocus(
        language: String,
        expectedTitle: String,
        expectedDetail: String
    ) throws {
        let bundle = try localizedBundle(language: language)
        let entry = makeEntry(state: .cancelled)

        #expect(
            FocusHistoryEntryPresentation.taskTitle(
                for: entry,
                bundle: bundle,
                locale: Locale(identifier: language)
            ) == expectedTitle
        )
        #expect(
            FocusHistoryEntryPresentation.detail(
                for: entry,
                bundle: bundle,
                locale: Locale(identifier: language)
            ) == expectedDetail
        )
    }

    private func makeEntry(
        state: SessionState,
        taskTitle: String? = nil,
        categoryName: String? = nil,
        focusTime: TimeInterval = 5 * 60
    ) -> FocusHistoryEntry {
        FocusHistoryEntry(
            id: UUID(),
            startedAt: Date(timeIntervalSince1970: 0),
            focusTime: focusTime,
            state: state,
            taskTitle: taskTitle,
            categoryName: categoryName,
            categoryColorToken: nil
        )
    }

    private func localizedBundle(language: String) throws -> Bundle {
        let resourcePath = try #require(
            Bundle.main.path(forResource: language, ofType: "lproj")
        )
        return try #require(Bundle(path: resourcePath))
    }
}
