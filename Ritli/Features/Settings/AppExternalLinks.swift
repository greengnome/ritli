import Foundation

enum AppExternalLinks {
    static let privacyPolicyInfoKey = "RITLI_PRIVACY_POLICY_URL"
    static let supportInfoKey = "RITLI_SUPPORT_URL"

    private static var configuredLinks: [String: Any] {
        guard
            let url = Bundle.main.url(
                forResource: "ReleaseLinks",
                withExtension: "plist"
            ),
            let data = try? Data(contentsOf: url),
            let links = try? PropertyListSerialization.propertyList(
                from: data,
                format: nil
            ) as? [String: Any]
        else {
            return [:]
        }

        return links
    }

    static var privacyPolicyURL: URL? {
        url(for: privacyPolicyInfoKey, in: configuredLinks)
    }

    static var supportURL: URL? {
        url(for: supportInfoKey, in: configuredLinks)
    }

    static func url(for key: String, in info: [String: Any]) -> URL? {
        guard
            let rawValue = info[key] as? String,
            let url = URL(string: rawValue),
            url.scheme == "https",
            url.host() != nil
        else {
            return nil
        }

        return url
    }
}
