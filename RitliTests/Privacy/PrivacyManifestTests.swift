import Foundation
import Testing

struct PrivacyManifestTests {
    @Test("The packaged privacy manifest declares UserDefaults without tracking")
    func declaresRequiredReasonAPI() throws {
        let url = try #require(
            Bundle.main.url(
                forResource: "PrivacyInfo",
                withExtension: "xcprivacy"
            )
        )
        let data = try Data(contentsOf: url)
        let manifest = try #require(
            PropertyListSerialization.propertyList(
                from: data,
                format: nil
            ) as? [String: Any]
        )
        let accessedAPIs = try #require(
            manifest["NSPrivacyAccessedAPITypes"] as? [[String: Any]]
        )
        let userDefaults = try #require(
            accessedAPIs.first {
                $0["NSPrivacyAccessedAPIType"] as? String
                    == "NSPrivacyAccessedAPICategoryUserDefaults"
            }
        )

        #expect(manifest["NSPrivacyTracking"] as? Bool == false)
        #expect(
            userDefaults["NSPrivacyAccessedAPITypeReasons"] as? [String]
                == ["CA92.1"]
        )
    }
}
