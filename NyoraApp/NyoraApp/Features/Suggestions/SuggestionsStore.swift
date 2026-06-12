import Foundation
import NyoraEngine

/// One recommendation rail: a heading plus the manga to display in it.
/// `seed` carries the favourite/tag this rail was derived from so the UI can label it
/// ("Because you read …", "Popular in <genre>") without re-deriving anything.
struct SuggestionRail: Codable, Identifiable, Hashable {
    enum Kind: String, Codable { case becauseYouRead, popularInGenre }

    let id: String
    let kind: Kind
    /// Display seed: favourite title, or genre/tag title.
    let seed: String
    /// Lightweight refs (mirrors MangaRef shape) so the cache survives relaunch and we can
    /// rebuild live `Manga` on tap via AppModel.manga(from:).
    let items: [MangaRef]
}

/// Persisted, timestamped recommendation snapshot. Mirrors `LibraryStore`'s JSON-in-
/// Application-Support pattern (its own file, never touching library.json).
final class SuggestionsStore {
    static let shared = SuggestionsStore()

    struct Snapshot: Codable {
        var rails: [SuggestionRail] = []
        var generatedAt: Date?
        /// favourite ids the snapshot was built from, to detect a stale cache cheaply.
        var basis: [Int64] = []

        init() {}

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            rails = try c.decodeIfPresent([SuggestionRail].self, forKey: .rails) ?? []
            generatedAt = try c.decodeIfPresent(Date.self, forKey: .generatedAt)
            basis = try c.decodeIfPresent([Int64].self, forKey: .basis) ?? []
        }
    }

    private let url: URL
    private let queue = DispatchQueue(label: "nyora.suggestionsstore")
    private(set) var snapshot: Snapshot

    private init() {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Nyora", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.url = dir.appendingPathComponent("suggestions.json")
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            self.snapshot = decoded
        } else {
            self.snapshot = Snapshot()
        }
    }

    func save(rails: [SuggestionRail], basis: [Int64], at date: Date) {
        snapshot.rails = rails
        snapshot.basis = basis
        snapshot.generatedAt = date
        persist()
    }

    func clear() {
        snapshot = Snapshot()
        persist()
    }

    private func persist() {
        let snap = snapshot
        queue.async { [url] in
            if let data = try? JSONEncoder().encode(snap) {
                try? data.write(to: url, options: .atomic)
            }
        }
    }
}
