import Foundation
import SwiftData

@Model
final class FocusCategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorToken: String
    var iconName: String?
    var sortOrder: Int
    var isArchived: Bool

    @Relationship(deleteRule: .nullify, inverse: \FocusTask.category)
    var tasks: [FocusTask]

    @Relationship(deleteRule: .nullify, inverse: \FocusSession.category)
    var sessions: [FocusSession]

    init(
        id: UUID = UUID(),
        name: String,
        colorToken: String,
        iconName: String? = nil,
        sortOrder: Int = 0,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.colorToken = colorToken
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.isArchived = isArchived
        self.tasks = []
        self.sessions = []
    }
}
