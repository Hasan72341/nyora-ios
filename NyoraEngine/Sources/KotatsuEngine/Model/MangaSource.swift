import Foundation

/// Identifies a content source. Mirrors `org.koitharu.nyora.parsers.model.MangaSource`
/// (and its concrete `MangaParserSource` enum) without enumerating ~1300 cases as Swift
/// enum members — concrete parsers carry their source value and a global `SourceRegistry`
/// resolves by name.
public struct MangaParserSource: Hashable, Codable, Sendable {
    /// Stable identifier, e.g. "MANGADEX". Equivalent to the Nyora enum constant name.
    public let name: String
    /// Human-readable title shown in UI, e.g. "MangaDex".
    public let title: String
    /// Primary content language (BCP-47), nil for multi-language sources.
    public let locale: String?
    public let contentType: ContentType

    public init(name: String, title: String, locale: String?, contentType: ContentType = .manga) {
        self.name = name
        self.title = title
        self.locale = locale
        self.contentType = contentType
    }

    public static func == (lhs: MangaParserSource, rhs: MangaParserSource) -> Bool {
        lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

/// Process-wide registry of known parser sources. The site-parser layer registers its
/// source here at definition time; the UI and persistence layers resolve by `name`.
public final class SourceRegistry: @unchecked Sendable {
    public static let shared = SourceRegistry()
    private var byName: [String: MangaParserSource] = [:]
    private let lock = NSLock()

    public func register(_ source: MangaParserSource) {
        lock.lock(); defer { lock.unlock() }
        byName[source.name] = source
    }

    public func source(named name: String) -> MangaParserSource? {
        lock.lock(); defer { lock.unlock() }
        if let s = byName[name] { return s }
        // Sources register under bare ids ("ASURASCANS_US"), but synced/canonical
        // refs from mac/android/cloud are "JS_"-prefixed. Resolve either form.
        if name.hasPrefix("JS_"), let s = byName[String(name.dropFirst(3))] { return s }
        return byName["JS_" + name]
    }

    public var all: [MangaParserSource] {
        lock.lock(); defer { lock.unlock() }
        return Array(byName.values)
    }
}
