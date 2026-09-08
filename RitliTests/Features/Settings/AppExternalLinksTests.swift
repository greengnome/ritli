import Foundation
import Testing
@testable import Ritli

struct AppExternalLinksTests {
    @Test("The release bundle exposes support and privacy-policy URLs")
    func readsReleaseConfiguration() {
        #expect(
            AppExternalLinks.supportURL
                == URL(string: "https://github.com/greengnome/ritli/issues")
        )
        #expect(
            AppExternalLinks.privacyPolicyURL
                == URL(string: "https://www.ritli.app/privacy")
        )
    }

    @Test("External links accept only complete HTTPS URLs")
    func validatesURLs() {
        #expect(
            AppExternalLinks.url(
                for: "URL",
                in: ["URL": "https://example.com/privacy"]
            ) == URL(string: "https://example.com/privacy")
        )
        #expect(AppExternalLinks.url(for: "URL", in: ["URL": ""]) == nil)
        #expect(
            AppExternalLinks.url(
                for: "URL",
                in: ["URL": "http://example.com/privacy"]
            ) == nil
        )
        #expect(
            AppExternalLinks.url(for: "URL", in: ["URL": "not a url"])
                == nil
        )
    }
}
