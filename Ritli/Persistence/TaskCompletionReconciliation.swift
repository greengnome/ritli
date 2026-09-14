import Foundation
import SwiftData

enum TaskCompletionReconciliation {
    @MainActor
    static func run(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<FocusTask>(
            predicate: #Predicate { $0.completedAt == nil }
        )
        var didCompleteTask = false
        for task in try context.fetch(descriptor) {
            if task.completeIfEstimateReached() {
                didCompleteTask = true
            }
        }

        if didCompleteTask {
            try context.save()
        }
    }
}
