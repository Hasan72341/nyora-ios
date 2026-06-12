import Foundation
import NyoraEngine

/// Lightweight Codable snapshot of a manga, enough to render library/history rows without
/// re-fetching. Stores the source name so we can rebuild the live `Manga` on demand.
struct MangaRef: Codable, Identifiable, Hashable {
    let id: Int64
    let title: String
    let url: String
    let publicUrl: String
    let coverUrl: String?
    let sourceName: String
    var updatedAt: Date
    var deletedAt: Date?

    init(_ manga: Manga) {
        self.id = manga.id
        self.title = manga.title
        self.url = manga.url
        self.publicUrl = manga.publicUrl
        self.coverUrl = manga.coverUrl
        self.sourceName = manga.source.name
        self.updatedAt = Date()
    }

    // Used by Supabase pull — reconstructs a ref from cloud row data.
    init(id: Int64, title: String, url: String, publicUrl: String, coverUrl: String?, sourceName: String, updatedAt: Date = Date(), deletedAt: Date? = nil) {
        self.id = id; self.title = title; self.url = url
        self.publicUrl = publicUrl; self.coverUrl = coverUrl; self.sourceName = sourceName
        self.updatedAt = updatedAt; self.deletedAt = deletedAt
    }
}

/// One history entry: where the reader left off.
struct HistoryEntry: Codable, Identifiable, Hashable {
    var id: Int64 { manga.id }
    let manga: MangaRef
    var chapterId: Int64
    var chapterTitle: String
    var page: Int
    var totalPages: Int
    var updatedAt: Date
    var deletedAt: Date?

    var percent: Double {
        totalPages > 0 ? min(1, Double(page + 1) / Double(totalPages)) : 0
    }
}

/// A reader bookmark on a specific page.
struct BookmarkEntry: Codable, Identifiable, Hashable {
    var id: String { "\(manga.id):\(chapterId):\(page)" }
    let manga: MangaRef
    let chapterId: Int64
    let chapterTitle: String
    let page: Int
    let createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
}

/// A user-defined library category (e.g. "Reading", "Completed").
struct Category: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var updatedAt: Date
    var deletedAt: Date?
}

/// Tracking record for a chapter read event.
struct ReadEvent: Codable, Hashable {
    let mangaId: Int64
    let chapterId: Int64
    let sourceName: String
    let timestamp: Date
}

final class LibraryStore {
    /// Set to true after SupabaseConfig is configured and the user has signed in.
    /// When true, every local persist triggers a background push to Supabase.
    var supabaseSyncEnabled = false
    /// Persisted state. Uses a custom decoder so adding fields stays backward-compatible
    /// with snapshots written by earlier builds (missing keys → defaults instead of failing).
    struct Snapshot: Codable {
        var favourites: [MangaRef] = []
        var history: [HistoryEntry] = []
        var bookmarks: [BookmarkEntry] = []
        var categories: [Category] = []
        var mangaCategories: [String: [String]] = [:]   // mangaId → [categoryId]
        var lastSeenChapters: [String: Int] = [:]        // mangaId → chapter count at last update check
        var readChapterIds: [Int64] = []                 // chapters opened/read (for stats)
        var readEvents: [ReadEvent] = []
        var readLater: [MangaRef] = []

        init() {}

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            favourites = try c.decodeIfPresent([MangaRef].self, forKey: .favourites) ?? []
            history = try c.decodeIfPresent([HistoryEntry].self, forKey: .history) ?? []
            bookmarks = try c.decodeIfPresent([BookmarkEntry].self, forKey: .bookmarks) ?? []
            categories = try c.decodeIfPresent([Category].self, forKey: .categories) ?? []
            mangaCategories = try c.decodeIfPresent([String: [String]].self, forKey: .mangaCategories) ?? [:]
            lastSeenChapters = try c.decodeIfPresent([String: Int].self, forKey: .lastSeenChapters) ?? [:]
            readChapterIds = try c.decodeIfPresent([Int64].self, forKey: .readChapterIds) ?? []
            readEvents = try c.decodeIfPresent([ReadEvent].self, forKey: .readEvents) ?? []
            readLater = try c.decodeIfPresent([MangaRef].self, forKey: .readLater) ?? []
        }
    }

    private let url: URL
    private let queue = DispatchQueue(label: "nyora.librarystore")
    private(set) var snapshot: Snapshot

    var hasLocalData: Bool {
        snapshot.favourites.contains { $0.deletedAt == nil } ||
        snapshot.history.contains { $0.deletedAt == nil } ||
        snapshot.bookmarks.contains { $0.deletedAt == nil } ||
        snapshot.categories.contains { $0.deletedAt == nil } ||
        snapshot.readLater.contains { $0.deletedAt == nil }
    }

    init() {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Nyora", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.url = dir.appendingPathComponent("library.json")
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            self.snapshot = decoded
        } else {
            self.snapshot = Snapshot()
        }
        dedupeCategories()
    }

    private func persist() {
        let snap = snapshot
        let syncEnabled = supabaseSyncEnabled
        queue.async { [url] in
            if let data = try? JSONEncoder().encode(snap) {
                try? data.write(to: url, options: .atomic)
            }
        }
        if syncEnabled {
            // SupabaseSync is @MainActor; schedule a push on the next run-loop turn.
            let store = self
            DispatchQueue.main.async {
                Task { await SupabaseSync.shared.pushAll(store: store) }
            }
        }
    }

    // MARK: Favourites

    func isFavourite(_ id: Int64) -> Bool { 
        snapshot.favourites.contains { $0.id == id && $0.deletedAt == nil } 
    }

    func toggleFavourite(_ manga: Manga) {
        if let idx = snapshot.favourites.firstIndex(where: { $0.id == manga.id }) {
            if snapshot.favourites[idx].deletedAt == nil {
                snapshot.favourites[idx].deletedAt = Date()
            } else {
                snapshot.favourites[idx].deletedAt = nil
            }
            snapshot.favourites[idx].updatedAt = Date()
        } else {
            snapshot.favourites.insert(MangaRef(manga), at: 0)
        }
        persist()
    }

    // MARK: History

    func recordProgress(manga: Manga, chapter: MangaChapter, page: Int, totalPages: Int, now: Date) {
        let entry = HistoryEntry(
            manga: MangaRef(manga),
            chapterId: chapter.id,
            chapterTitle: chapter.name,
            page: page,
            totalPages: totalPages,
            updatedAt: now,
            deletedAt: nil
        )
        snapshot.history.removeAll { $0.manga.id == manga.id }
        snapshot.history.insert(entry, at: 0)
        persist()
    }

    func history(for mangaId: Int64) -> HistoryEntry? {
        snapshot.history.first { $0.manga.id == mangaId && $0.deletedAt == nil }
    }

    /// Backfill a missing cover for a manga across history / favourites /
    /// readLater. Synced rows from other devices often arrive with a blank
    /// `coverUrl`; we fetch it from the source's search (like Explore) and fill
    /// it here. Purely local enrichment — `updatedAt` is preserved and no
    /// Supabase push is triggered.
    func updateCover(mangaId: Int64, coverUrl: String) {
        guard !coverUrl.isEmpty else { return }
        func filled(_ ref: MangaRef) -> MangaRef {
            guard ref.id == mangaId, (ref.coverUrl ?? "").isEmpty else { return ref }
            return MangaRef(id: ref.id, title: ref.title, url: ref.url, publicUrl: ref.publicUrl,
                            coverUrl: coverUrl, sourceName: ref.sourceName,
                            updatedAt: ref.updatedAt, deletedAt: ref.deletedAt)
        }
        var changed = false
        for i in snapshot.history.indices
        where snapshot.history[i].manga.id == mangaId && (snapshot.history[i].manga.coverUrl ?? "").isEmpty {
            let e = snapshot.history[i]
            snapshot.history[i] = HistoryEntry(manga: filled(e.manga), chapterId: e.chapterId,
                                               chapterTitle: e.chapterTitle, page: e.page,
                                               totalPages: e.totalPages, updatedAt: e.updatedAt,
                                               deletedAt: e.deletedAt)
            changed = true
        }
        for i in snapshot.favourites.indices
        where snapshot.favourites[i].id == mangaId && (snapshot.favourites[i].coverUrl ?? "").isEmpty {
            snapshot.favourites[i] = filled(snapshot.favourites[i]); changed = true
        }
        for i in snapshot.readLater.indices
        where snapshot.readLater[i].id == mangaId && (snapshot.readLater[i].coverUrl ?? "").isEmpty {
            snapshot.readLater[i] = filled(snapshot.readLater[i]); changed = true
        }
        guard changed else { return }
        let snap = snapshot
        queue.async { [url] in
            if let data = try? JSONEncoder().encode(snap) {
                try? data.write(to: url, options: .atomic)
            }
        }
    }

    func clearHistory() { 
        let now = Date()
        for i in 0..<snapshot.history.count {
            if snapshot.history[i].deletedAt == nil {
                snapshot.history[i].deletedAt = now
                snapshot.history[i].updatedAt = now
            }
        }
        persist() 
    }

    // MARK: Categories

    func addCategory(name: String) {
        let id = "cat-\(snapshot.categories.count)-\(name.hashValue)"
        if let idx = snapshot.categories.firstIndex(where: { $0.name == name }) {
            if snapshot.categories[idx].deletedAt != nil {
                snapshot.categories[idx].deletedAt = nil
                snapshot.categories[idx].updatedAt = Date()
            }
            return
        }
        snapshot.categories.append(Category(id: id, name: name, updatedAt: Date(), deletedAt: nil))
        persist()
    }

    func deleteCategory(_ id: String) {
        if let idx = snapshot.categories.firstIndex(where: { $0.id == id }) {
            snapshot.categories[idx].deletedAt = Date()
            snapshot.categories[idx].updatedAt = Date()
            
            // Also mark associations for deletion? 
            // In Android they might be hard-deleted or cascaded.
            // For now let's just keep the associations as-is, they only point to this ID.
        }
        persist()
    }

    func categories(for mangaId: Int64) -> [String] {
        snapshot.mangaCategories["\(mangaId)"] ?? []
    }

    func setCategories(_ ids: [String], for mangaId: Int64) {
        snapshot.mangaCategories["\(mangaId)"] = ids
        persist()
    }

    /// Collapse duplicate same-title categories that accumulate across synced devices
    /// (e.g. several "Read later" tabs each with a different id). Mirrors the Android
    /// `repointDuplicateFavourites` / `softDeleteDuplicateCategories` cleanup.
    ///
    /// Among non-deleted categories, group by name. For each group of size > 1 the
    /// canonical category is the member with the smallest id (String comparison).
    /// Every other (duplicate) member is repointed in `mangaCategories` onto the
    /// canonical id (deduped per manga) and then SOFT-deleted so the deletion
    /// propagates through the existing Supabase push.
    func dedupeCategories() {
        let active = snapshot.categories.filter { $0.deletedAt == nil }
        let groups = Dictionary(grouping: active, by: { $0.name })
        // duplicateId -> canonicalId for every non-canonical member of a duplicate group.
        var canonicalFor: [String: String] = [:]
        for (_, members) in groups where members.count > 1 {
            guard let canonical = members.map({ $0.id }).min() else { continue }
            for member in members where member.id != canonical {
                canonicalFor[member.id] = canonical
            }
        }
        guard !canonicalFor.isEmpty else { return }   // nothing to collapse — skip persist

        // (a) Repoint manga -> category associations onto the canonical id, deduped.
        for (mangaId, ids) in snapshot.mangaCategories {
            var changed = false
            var seen = Set<String>()
            var remapped: [String] = []
            for id in ids {
                let target = canonicalFor[id] ?? id
                if target != id { changed = true }
                if seen.insert(target).inserted { remapped.append(target) }
                else { changed = true }   // collapsed a now-duplicate entry
            }
            if changed { snapshot.mangaCategories[mangaId] = remapped }
        }

        // (b) Soft-delete the duplicate categories so the deletion syncs out.
        let now = Date()
        for i in snapshot.categories.indices where canonicalFor[snapshot.categories[i].id] != nil {
            snapshot.categories[i].deletedAt = now
            snapshot.categories[i].updatedAt = now
        }

        persist()
    }

    func favourites(inCategory id: String?) -> [MangaRef] {
        let activeFavs = snapshot.favourites.filter { $0.deletedAt == nil }
        guard let id else { return activeFavs }
        return activeFavs.filter { (snapshot.mangaCategories["\($0.id)"] ?? []).contains(id) }
    }

    // MARK: Read Later

    func isReadLater(_ id: Int64) -> Bool { 
        snapshot.readLater.contains { $0.id == id && $0.deletedAt == nil } 
    }

    func toggleReadLater(_ manga: Manga) {
        if let idx = snapshot.readLater.firstIndex(where: { $0.id == manga.id }) {
            if snapshot.readLater[idx].deletedAt == nil {
                snapshot.readLater[idx].deletedAt = Date()
            } else {
                snapshot.readLater[idx].deletedAt = nil
            }
            snapshot.readLater[idx].updatedAt = Date()
        } else {
            var ref = MangaRef(manga)
            ref.updatedAt = Date()
            snapshot.readLater.insert(ref, at: 0)
        }
        persist()
    }

    var readLater: [MangaRef] { snapshot.readLater.filter { $0.deletedAt == nil } }

    // MARK: Update detection (new chapters for favourites)

    func recordChapterCount(mangaId: Int64, count: Int) -> Int {
        let key = "\(mangaId)"
        defer { snapshot.lastSeenChapters[key] = count; persist() }
        guard let previous = snapshot.lastSeenChapters[key] else { return 0 }
        return max(0, count - previous)
    }

    // MARK: Read tracking (stats)

    func markChapterRead(mangaId: Int64, chapterId: Int64, sourceName: String) {
        if !snapshot.readChapterIds.contains(chapterId) {
            snapshot.readChapterIds.append(chapterId)
        }
        let event = ReadEvent(mangaId: mangaId, chapterId: chapterId, sourceName: sourceName, timestamp: Date())
        snapshot.readEvents.append(event)
        persist()
    }

    var readChapterCount: Int { snapshot.readChapterIds.count }
    var readEvents: [ReadEvent] { snapshot.readEvents }

    // MARK: Bookmarks

    func addBookmark(manga: Manga, chapter: MangaChapter, page: Int, now: Date) {
        if let idx = snapshot.bookmarks.firstIndex(where: { 
            $0.manga.id == manga.id && $0.chapterId == chapter.id && $0.page == page 
        }) {
            if snapshot.bookmarks[idx].deletedAt != nil {
                snapshot.bookmarks[idx].deletedAt = nil
                snapshot.bookmarks[idx].updatedAt = now
                persist()
            }
            return
        }
        
        let b = BookmarkEntry(
            manga: MangaRef(manga),
            chapterId: chapter.id,
            chapterTitle: chapter.name,
            page: page,
            createdAt: now,
            updatedAt: now,
            deletedAt: nil
        )
        snapshot.bookmarks.insert(b, at: 0)
        persist()
    }

    func removeBookmark(_ b: BookmarkEntry) {
        if let idx = snapshot.bookmarks.firstIndex(where: { $0.id == b.id }) {
            snapshot.bookmarks[idx].deletedAt = Date()
            snapshot.bookmarks[idx].updatedAt = Date()
            persist()
        }
    }

    // MARK: Bulk removal (Data removal screen)

    func resetAll() {
        snapshot = Snapshot()
        persist()
    }

    func clearUpdateBaseline() {
        snapshot.lastSeenChapters.removeAll()
        persist()
    }

    var readChapterIds: Set<Int64> { Set(snapshot.readChapterIds) }

    // MARK: Sync insertion (Supabase pull path — bypass NyoraEngine model requirement)

    func syncInsertFavourite(_ ref: MangaRef) {
        if let idx = snapshot.favourites.firstIndex(where: { $0.id == ref.id }) {
            if snapshot.favourites[idx].updatedAt < ref.updatedAt {
                snapshot.favourites[idx] = ref
            }
        } else {
            snapshot.favourites.insert(ref, at: 0)
        }
        persist()
    }

    func syncRemoveFavourite(mangaId: Int64, deletedAt: Date) {
        if let idx = snapshot.favourites.firstIndex(where: { $0.id == mangaId }) {
            if snapshot.favourites[idx].updatedAt < deletedAt {
                snapshot.favourites[idx].deletedAt = deletedAt
                snapshot.favourites[idx].updatedAt = deletedAt
            }
        } else {
            // Not here? Maybe it was already gone. But we could insert a deleted record if we wanted to be strict.
        }
        persist()
    }

    func syncUpsertHistory(manga: MangaRef, chapterId: Int64, chapterTitle: String,
                           page: Int, totalPages: Int, updatedAt: Date, deletedAt: Date? = nil) {
        if let idx = snapshot.history.firstIndex(where: { $0.manga.id == manga.id }) {
            if snapshot.history[idx].updatedAt < updatedAt {
                snapshot.history[idx] = HistoryEntry(manga: manga, chapterId: chapterId, chapterTitle: chapterTitle,
                                                     page: page, totalPages: totalPages, updatedAt: updatedAt, deletedAt: deletedAt)
            }
        } else {
            snapshot.history.insert(HistoryEntry(manga: manga, chapterId: chapterId, chapterTitle: chapterTitle,
                                                 page: page, totalPages: totalPages, updatedAt: updatedAt, deletedAt: deletedAt), at: 0)
        }
        persist()
    }

    func syncRemoveHistory(mangaId: Int64, deletedAt: Date) {
        if let idx = snapshot.history.firstIndex(where: { $0.manga.id == mangaId }) {
            if snapshot.history[idx].updatedAt < deletedAt {
                snapshot.history[idx].deletedAt = deletedAt
                snapshot.history[idx].updatedAt = deletedAt
            }
        }
        persist()
    }

    func syncInsertBookmark(manga: MangaRef, chapterId: Int64, chapterTitle: String,
                            page: Int, createdAt: Date, updatedAt: Date, deletedAt: Date? = nil) {
        let id = "\(manga.id):\(chapterId):\(page)"
        if let idx = snapshot.bookmarks.firstIndex(where: { $0.id == id }) {
            if snapshot.bookmarks[idx].updatedAt < updatedAt {
                snapshot.bookmarks[idx] = BookmarkEntry(manga: manga, chapterId: chapterId, chapterTitle: chapterTitle,
                                                        page: page, createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt)
            }
        } else {
            snapshot.bookmarks.insert(BookmarkEntry(manga: manga, chapterId: chapterId, chapterTitle: chapterTitle,
                                                    page: page, createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt), at: 0)
        }
        persist()
    }

    func syncRemoveBookmark(id: String, deletedAt: Date) {
        if let idx = snapshot.bookmarks.firstIndex(where: { $0.id == id }) {
            if snapshot.bookmarks[idx].updatedAt < deletedAt {
                snapshot.bookmarks[idx].deletedAt = deletedAt
                snapshot.bookmarks[idx].updatedAt = deletedAt
            }
        }
        persist()
    }

    func syncInsertCategory(_ category: Category) {
        if let idx = snapshot.categories.firstIndex(where: { $0.id == category.id }) {
            if snapshot.categories[idx].updatedAt < category.updatedAt {
                snapshot.categories[idx] = category
            }
        } else {
            snapshot.categories.append(category)
        }
        persist()
    }

    func syncRemoveCategory(id: String, deletedAt: Date) {
        if let idx = snapshot.categories.firstIndex(where: { $0.id == id }) {
            if snapshot.categories[idx].updatedAt < deletedAt {
                snapshot.categories[idx].deletedAt = deletedAt
                snapshot.categories[idx].updatedAt = deletedAt
            }
        }
        persist()
    }
}
