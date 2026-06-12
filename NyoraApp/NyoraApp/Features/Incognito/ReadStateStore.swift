import Foundation
import SwiftUI
import NyoraEngine

/// Explicit per-chapter read state, independent of the history-based "continue reading" flow.
///
/// nyora-android tracks a discrete read/unread flag per chapter (set via the chapter list's
/// "Mark as read" / "Mark previous as read" actions) that is separate from where the reader
/// last left off. This store mirrors that: it keeps a `Set` of read chapter ids per manga,
/// persisted to its OWN `readstate.json` in Application Support (never touches library.json).
@MainActor
final class ReadState: ObservableObject {
    static let shared = ReadState()

    /// mangaId → set of read chapter ids. Published so chapter rows re-render on change.
    @Published private(set) var readByManga: [Int64: Set<Int64>] = [:]

    private let queue = DispatchQueue(label: "nyora.readstatestore")

    // MARK: Paths (mirrors LibraryStore / DownloadManager)

    private static let baseDir: URL = {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Nyora", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private let stateURL = ReadState.baseDir.appendingPathComponent("readstate.json")

    // MARK: Persistence

    /// Stored as arrays keyed by manga id string (JSON has no Int64/Set primitives).
    private struct Snapshot: Codable {
        var read: [String: [Int64]] = [:]

        init() {}
        init(read: [String: [Int64]]) { self.read = read }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            read = try c.decodeIfPresent([String: [Int64]].self, forKey: .read) ?? [:]
        }
    }

    private init() {
        if let data = try? Data(contentsOf: stateURL),
           let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            readByManga = decoded.read.reduce(into: [:]) { acc, pair in
                if let id = Int64(pair.key) { acc[id] = Set(pair.value) }
            }
        }
    }

    private func persist() {
        let snap = Snapshot(read: readByManga.reduce(into: [:]) { acc, pair in
            acc["\(pair.key)"] = Array(pair.value)
        })
        queue.async { [stateURL] in
            if let data = try? JSONEncoder().encode(snap) {
                try? data.write(to: stateURL, options: .atomic)
            }
        }
    }

    // MARK: Public API

    /// Whether a chapter has been explicitly marked read.
    func isRead(_ chapterId: Int64, mangaId: Int64) -> Bool {
        readByManga[mangaId]?.contains(chapterId) ?? false
    }

    /// Convenience for callers that only have a chapter id (searches all manga). Prefer the
    /// `mangaId`-qualified overload when the manga context is known.
    func isRead(_ chapterId: Int64) -> Bool {
        readByManga.values.contains { $0.contains(chapterId) }
    }

    /// Mark one or more chapters read for a manga.
    func markRead(_ chapterIds: [Int64], mangaId: Int64) {
        guard !chapterIds.isEmpty else { return }
        var set = readByManga[mangaId] ?? []
        set.formUnion(chapterIds)
        readByManga[mangaId] = set
        persist()
    }

    /// Mark a single chapter unread (toggle support).
    func markUnread(_ chapterIds: [Int64], mangaId: Int64) {
        guard var set = readByManga[mangaId] else { return }
        for id in chapterIds { set.remove(id) }
        if set.isEmpty { readByManga[mangaId] = nil } else { readByManga[mangaId] = set }
        persist()
    }

    /// Mark every chapter at or before `chapter` (by position in `chapters`) as read.
    /// `chapters` is expected in natural reading order (oldest-first), matching `manga.chapters`.
    func markAllPreviousRead(in chapters: [MangaChapter], upTo chapter: MangaChapter, mangaId: Int64) {
        guard let upToIdx = chapters.firstIndex(where: { $0.id == chapter.id }) else {
            markRead([chapter.id], mangaId: mangaId)
            return
        }
        let ids = chapters[...upToIdx].map(\.id)
        markRead(ids, mangaId: mangaId)
    }

    /// Number of read chapters for a manga.
    func readCount(mangaId: Int64) -> Int { readByManga[mangaId]?.count ?? 0 }
}
