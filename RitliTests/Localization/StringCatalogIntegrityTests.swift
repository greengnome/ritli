import Foundation
import Testing

/// Checks the source String Catalogs as data instead of pinning individual
/// translations: every key needs a finished Ukrainian translation whose format
/// arguments line up with English. Composition of formatted and plural copy is
/// covered by the feature suites (for example `TasksLocalizationTests`).
@Suite("String Catalog integrity")
struct StringCatalogIntegrityTests {
    /// Catalog paths relative to the repository root. Simulator test processes
    /// run on the host, so the source files are readable through `#filePath`.
    static let catalogPaths = [
        "Ritli/Localizable.xcstrings",
        "RitliLiveActivity/Localizable.xcstrings",
    ]

    /// Known failures, excluded so the check guards every other key.
    /// Remove an entry once its catalog entry is fixed or deleted; the
    /// `allowlistIsCurrent` test fails while an entry here is stale.
    /// Keep it empty: fix the catalog (or the code that extracted a stray
    /// key, such as a ternary inside `String(localized:)`) instead.
    static let allowlistedKeys: Set<String> = []

    @Test("Every key has a finished Ukrainian translation with English's format arguments",
          arguments: catalogPaths)
    func catalogIsComplete(path: String) throws {
        let catalog = try Self.loadCatalog(at: path)
        let problems = catalog.strings.keys.sorted().flatMap { key in
            Self.allowlistedKeys.contains(key)
                ? []
                : Self.problems(forKey: key, in: catalog)
        }

        #expect(
            problems.isEmpty,
            "\(path) has \(problems.count) problem(s):\n\(problems.joined(separator: "\n"))"
        )
    }

    @Test("The allowlist names only keys that still fail the integrity check")
    func allowlistIsCurrent() throws {
        let catalogs = try Self.catalogPaths.map(Self.loadCatalog(at:))
        for key in Self.allowlistedKeys.sorted() {
            let failingCatalogs = catalogs.filter {
                $0.strings[key] != nil && !Self.problems(forKey: key, in: $0).isEmpty
            }
            #expect(
                !failingCatalogs.isEmpty,
                "\"\(key)\" passes or no longer exists; remove it from the allowlist"
            )
        }
    }

    @Test("Format signatures pair positional and sequential arguments", arguments: [
        ("%@ of %lld", "%2$lld з %1$@", true),
        ("%1$lld%%", "%lld%%", true),
        ("%lldh %lldm", "%lld год %lld хв", true),
        ("%@ of %lld", "%lld з %@", false),
        ("%lld min", "хв", false),
    ])
    func formatSignature(english: String, ukrainian: String, matches: Bool) {
        #expect(
            (Self.formatSignature(of: [english]) == Self.formatSignature(of: [ukrainian]))
                == matches
        )
    }

    // MARK: - Checks

    static func problems(forKey key: String, in catalog: Catalog) -> [String] {
        let entry = catalog.strings[key]
        guard entry?.shouldTranslate != false else { return [] }
        let localizations = entry?.localizations ?? [:]
        var problems: [String] = []

        // A key without a source-language localization is its own English copy.
        let englishValues = localizations[catalog.sourceLanguage].map { localization in
            localization.stringUnits.map(\.value)
        } ?? [key]
        if englishValues.isEmpty || englishValues.contains(where: \.isBlank) {
            problems.append("\(key): missing English value")
        }

        guard let ukrainian = localizations["uk"] else {
            return problems + ["\(key): missing Ukrainian localization"]
        }
        let units = ukrainian.stringUnits
        if units.isEmpty {
            problems.append("\(key): Ukrainian localization has no string units")
        }
        for unit in units where unit.state != "translated" {
            problems.append("\(key): Ukrainian state is \"\(unit.state)\"")
        }
        if units.contains(where: \.value.isBlank) {
            problems.append("\(key): empty Ukrainian value")
        }

        let englishFormat = formatSignature(of: englishValues)
        let ukrainianFormat = formatSignature(of: units.map(\.value))
        if englishFormat != ukrainianFormat {
            problems.append(
                "\(key): format arguments \(ukrainianFormat.sorted()) differ from English \(englishFormat.sorted())"
            )
        }
        return problems
    }

    /// The argument positions and conversions used across all variants, so
    /// `%@ … %lld` matches a reordered `%2$lld … %1$@`. `%%` is a literal.
    static func formatSignature(of values: [String]) -> Set<String> {
        var signature: Set<String> = []
        for value in values {
            var nextPosition = 1
            let specifiers = value.matches(
                of: #/%(?:(?<position>\d+)\$)?[-+#0']*(?:\d+|\*)?(?:\.(?:\d+|\*))?(?<length>hh|h|ll|l|q|L|z|t|j)?(?<conversion>[@dDiuUxXoOfFeEgGaAcCsSp%])/#
            )
            for match in specifiers {
                let conversion = String(match.output.length ?? "") + match.output.conversion
                guard conversion != "%" else { continue }
                let position: Int
                if let explicit = match.output.position.flatMap({ Int($0) }) {
                    position = explicit
                } else {
                    position = nextPosition
                    nextPosition += 1
                }
                signature.insert("\(position):\(conversion)")
            }
        }
        return signature
    }

    // MARK: - Catalog model

    static func loadCatalog(at relativePath: String) throws -> Catalog {
        let url = repositoryRoot.appending(path: relativePath)
        return try JSONDecoder().decode(Catalog.self, from: Data(contentsOf: url))
    }

    private static let repositoryRoot = URL(filePath: #filePath)
        .deletingLastPathComponent() // Localization
        .deletingLastPathComponent() // RitliTests
        .deletingLastPathComponent()

    struct Catalog: Decodable {
        let sourceLanguage: String
        let strings: [String: Entry]
    }

    struct Entry: Decodable {
        let shouldTranslate: Bool?
        let localizations: [String: Localization]?
    }

    /// A `stringUnit`, or `variations` keyed by type (`plural`, `device`)
    /// and then case (`one`, `few`, `iphone`), which can nest further.
    struct Localization: Decodable {
        let stringUnit: StringUnit?
        let variations: [String: [String: Localization]]?

        var stringUnits: [StringUnit] {
            let nested = (variations ?? [:]).values.flatMap { cases in
                cases.values.flatMap(\.stringUnits)
            }
            return (stringUnit.map { [$0] } ?? []) + nested
        }
    }

    struct StringUnit: Decodable {
        let state: String
        let value: String
    }
}

private extension String {
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
