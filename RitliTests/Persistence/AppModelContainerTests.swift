import Foundation
import SwiftData
import Testing
@testable import Ritli

@MainActor
struct AppModelContainerTests {
    @Test("A fresh disk store creates its parent directories and survives reopening")
    func createsDiskStoreDirectory() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("Library/Application Support/default.store")
        let configuration = ModelConfiguration(schema: AppModelContainer.schema, url: url)
        #expect(!FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path))

        try autoreleasepool {
            let container = try AppModelContainer.make(configuration: configuration)
            container.mainContext.insert(FocusCategory(name: "Persisted", colorToken: "purple"))
            try container.mainContext.save()
        }

        #expect(FileManager.default.fileExists(atPath: url.path))
        let reopened = try AppModelContainer.make(configuration: configuration)
        let categories = try reopened.mainContext.fetch(FetchDescriptor<FocusCategory>())
        #expect(categories.map(\.name) == ["Persisted"])
    }

    @Test("An invalid disk store parent still reports an error")
    func rejectsInvalidDiskStoreDirectory() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let blocker = root.appendingPathComponent("not-a-directory")
        try Data("occupied".utf8).write(to: blocker)
        let configuration = ModelConfiguration(
            schema: AppModelContainer.schema,
            url: blocker.appendingPathComponent("default.store")
        )

        #expect(throws: CocoaError.self) {
            try AppModelContainer.make(configuration: configuration)
        }
        #expect(try Data(contentsOf: blocker) == Data("occupied".utf8))
    }

}
