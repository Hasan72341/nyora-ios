import Foundation
import SwiftUI
import NyoraEngine

/// App-wide state and the single bridge to `NyoraEngine`. The UI observes the published
/// library collections; browsing/search/details/pages are async pass-throughs to the engine.
@MainActor
final class AppModel: ObservableObject {
    let _jsEngine = JSParserEngine.shared
    private let store: LibraryStore

    @Published private(set) var favourites: [MangaRef]
    @Published private(set) var readLater: [MangaRef]
    @Published private(set) var history: [HistoryEntry]
    @Published private(set) var bookmarks: [BookmarkEntry]
    @Published private(set) var categories: [Category]
    @Published private(set) var updates: [UpdateEntry] = []
    @Published private(set) var checkingUpdates = false

    /// A favourited manga that gained chapters since the last update check.
    struct UpdateEntry: Identifiable, Hashable {
        let manga: MangaRef
        let newCount: Int
        var id: Int64 { manga.id }
    }

    init() {
        // JSParserEngine.shared initializes itself lazily
        let store = LibraryStore()
        self.store = store
        self.favourites = store.snapshot.favourites
        self.readLater = store.snapshot.readLater
        self.history = store.snapshot.history
        self.bookmarks = store.snapshot.bookmarks
        self.categories = store.snapshot.categories.filter { $0.deletedAt == nil }
        publishWidgets()
        
        // Initial sync
        Task {
            await syncWithSupabase()
        }
    }

    /// Push a library/continue-reading snapshot to the home-screen widgets.
    func publishWidgets() {
        WidgetBridge.publish(favourites: favourites, history: history)
    }

    var sources: [MangaParserSource] { _jsEngine.sources }

    // MARK: Engine pass-throughs

    func browse(sourceName: String, page: Int, order: NyoraEngine.SortOrder, query: String?) async throws -> [Manga] {
        guard let parser = _jsEngine.parser(for: sourceName) else { return [] }
        let filter = MangaListFilter(query: query?.isEmpty == false ? query : nil)
        let order = parser.availableSortOrders.contains(order) ? order : parser.defaultSortOrder
        return try await parser.getList(page: page, order: order, filter: filter)
    }

    func details(_ manga: Manga) async throws -> Manga {
        guard let parser = _jsEngine.parser(for: manga.source.name) else { return manga }
        return try await parser.getDetails(manga)
    }

    /// One source's result row for global search.
    struct SearchGroup: Identifiable {
        let source: MangaParserSource
        let results: [Manga]
        var id: String { source.name }
    }

    /// Search every enabled catalogue source concurrently for `query`, returning non-empty groups.
    func globalSearch(query: String) async -> [SearchGroup] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        let prefs = SourcePrefs.shared
        let sources = _jsEngine.sources.filter { prefs.isEnabled($0.name) }
        return await withTaskGroup(of: SearchGroup?.self) { group in
            for src in sources {
                group.addTask { [weak self] in
                    guard let self,
                          let results = try? await self.browse(sourceName: src.name, page: 1, order: .popularity, query: q),
                          !results.isEmpty
                    else { return nil }
                    return SearchGroup(source: src, results: results)
                }
            }
            var out: [SearchGroup] = []
            for await g in group { if let g { out.append(g) } }
            // Stable order matching the catalogue.
            return sources.compactMap { s in out.first { $0.source.name == s.name } }
        }
    }

    /// Fetch details for every favourite and report which gained chapters since last check.
    func checkForUpdates() async {
        guard !checkingUpdates else { return }
        checkingUpdates = true
        defer { checkingUpdates = false }
        var found: [UpdateEntry] = []
        // Track new chapters for everything the user has read (history) as well as favourites,
        // not just favourites — deduped by manga id (favourites first).
        var seen = Set<Int64>()
        var refs: [MangaRef] = []
        for r in favourites where seen.insert(r.id).inserted { refs.append(r) }
        for h in history where seen.insert(h.manga.id).inserted { refs.append(h.manga) }
        for ref in refs {
            guard let manga = manga(from: ref) else { continue }
            guard let detailed = try? await details(manga) else { continue }
            let count = detailed.chapters?.count ?? 0
            let newCount = store.recordChapterCount(mangaId: ref.id, count: count)
            if newCount > 0 { found.append(UpdateEntry(manga: ref, newCount: newCount)) }
        }
        updates = found
        // Notify the user of new chapters (respects the in-app + system notification toggles).
        let payload = found.map { UpdateNotifier.ChapterUpdate(mangaId: $0.manga.id, title: $0.manga.title, newCount: $0.newCount) }
        await UpdateNotifier.shared.notify(updates: payload)
    }

    func pages(for chapter: MangaChapter, mangaId: Int64, sourceName: String) async throws -> [MangaPage] {
        let local = DownloadManager.shared.localPagesIfComplete(mangaId: mangaId, chapterId: chapter.id)
        if !local.isEmpty {
            guard let src = SourceRegistry.shared.source(named: sourceName) else { return [] }
            return local.enumerated().map { (index, url) in
                MangaPage(id: Int64(index), url: url.absoluteString, preview: nil, source: src)
            }
        }
        guard let parser = _jsEngine.parser(for: sourceName) else { return [] }
        return try await parser.getPages(chapter)
    }

    /// Absolute image URL + request headers for a page (Referer matters for hotlink blocks).
    func imageRequest(for page: MangaPage, sourceName: String) -> (url: URL, headers: [String: String])? {
        if page.url.hasPrefix("file://") {
            return (URL(string: page.url)!, [:])
        }
        return imageRequest(url: page.url, sourceName: sourceName)
    }

    func imageRequest(for manga: MangaRef) -> (url: URL, headers: [String: String])? {
        guard let url = manga.coverUrl else { return nil }
        return imageRequest(url: url, sourceName: manga.sourceName)
    }

    func imageRequest(url: String, sourceName: String) -> (url: URL, headers: [String: String])? {
        if let parser = _jsEngine.parser(for: sourceName) {
            let abs = url.toAbsoluteUrl(domain: parser.domain)
            guard let u = URL(string: abs) else { return nil }
            var headers = parser.requestHeaders()
            headers["Referer"] = "https://\(parser.domain)/"
            return (u, headers)
        }
        // No parser (unknown/legacy source). If the cover is already an absolute
        // URL we can still load it directly, just without source headers — so
        // synced rows from a ditched source still show their thumbnail.
        if url.hasPrefix("http"), let u = URL(string: url) {
            return (u, [:])
        }
        return nil
    }

    // MARK: Library mutations

    func isFavourite(_ id: Int64) -> Bool { store.isFavourite(id) }

    func toggleFavourite(_ manga: Manga) {
        store.toggleFavourite(manga)
        favourites = store.snapshot.favourites
        publishWidgets()
    }

    func isReadLater(_ id: Int64) -> Bool { store.isReadLater(id) }

    func toggleReadLater(_ manga: Manga) {
        store.toggleReadLater(manga)
        readLater = store.snapshot.readLater
    }

    func recordProgress(manga: Manga, chapter: MangaChapter, page: Int, total: Int) {
        if IncognitoState.shared.enabled { return }   // incognito: don't record history/progress
        store.recordProgress(manga: manga, chapter: chapter, page: page, totalPages: total, now: Date())
        store.markChapterRead(mangaId: manga.id, chapterId: chapter.id, sourceName: manga.source.name)
        history = store.snapshot.history
        publishWidgets()
    }

    var readEvents: [ReadEvent] { store.readEvents }

    // MARK: Categories

    func favourites(inCategory id: String?) -> [MangaRef] { store.favourites(inCategory: id) }
    func categories(for mangaId: Int64) -> [String] { store.categories(for: mangaId) }

    func addCategory(_ name: String) {
        store.addCategory(name: name); categories = store.snapshot.categories.filter { $0.deletedAt == nil }
    }
    func deleteCategory(_ id: String) {
        store.deleteCategory(id); categories = store.snapshot.categories.filter { $0.deletedAt == nil }
    }
    func setCategories(_ ids: [String], for mangaId: Int64) {
        store.setCategories(ids, for: mangaId); objectWillChange.send()
    }

    // MARK: Stats

    var readChapterCount: Int { store.readChapterCount }

    func continueReading(for mangaId: Int64) -> HistoryEntry? { store.history(for: mangaId) }

    func clearHistory() {
        store.clearHistory()
        history = store.snapshot.history
    }

    // MARK: Bulk data removal (Data removal settings screen)

    /// Clear the updates feed: drop the in-memory entries and the persisted chapter-count
    /// baseline so re-checking starts clean.
    func clearUpdatesFeed() {
        updates = []
        store.clearUpdateBaseline()
    }

    /// Wipe the entire library database (favourites/history/bookmarks/categories/baseline)
    /// and re-publish the now-empty collections.
    func resetLibraryDatabase() {
        store.resetAll()
        favourites = store.snapshot.favourites
        history = store.snapshot.history
        bookmarks = store.snapshot.bookmarks
        categories = store.snapshot.categories.filter { $0.deletedAt == nil }
        updates = []
    }

    /// Chapter ids the user has read — drives "Delete read chapters".
    var readChapterIds: Set<Int64> { store.readChapterIds }

    func addBookmark(manga: Manga, chapter: MangaChapter, page: Int) {
        store.addBookmark(manga: manga, chapter: chapter, page: page, now: Date())
        bookmarks = store.snapshot.bookmarks
    }

    func removeBookmark(_ b: BookmarkEntry) {
        store.removeBookmark(b)
        bookmarks = store.snapshot.bookmarks
    }

    /// Rebuild a minimal live `Manga` from a stored ref so detail/reader can re-fetch.
    func manga(from ref: MangaRef) -> Manga? {
        guard let src = SourceRegistry.shared.source(named: ref.sourceName) else { return nil }
        return Manga(
            id: ref.id,
            title: ref.title,
            url: ref.url,
            publicUrl: ref.publicUrl,
            coverUrl: ref.coverUrl,
            source: src
        )
    }
    
    // MARK: Supabase Sync
    
    var hasLocalData: Bool { store.hasLocalData }

    func syncWithSupabase() async {
        // Enable incremental push on every local persist once the user is authenticated.
        if SupabaseConfig.isAuthenticated {
            store.supabaseSyncEnabled = true
        }
        await SupabaseSync.shared.syncNow(store: store)
        refreshPublishedData()
        await backfillMissingCovers()
    }

    func restoreFromCloud() async {
        await SupabaseSync.shared.restoreFromCloud(store: store)
        refreshPublishedData()
        await backfillMissingCovers()
    }

    /// Synced rows from other devices frequently arrive with a blank cover.
    /// Explore shows covers because the parser's search/list results include
    /// them — so fetch missing covers the same way (search the source by title)
    /// and persist them locally. One-time per manga; resolvable JS sources only.
    func backfillMissingCovers() async {
        let refs = store.snapshot.history.map { $0.manga }
            + store.snapshot.favourites
            + store.snapshot.readLater
        var done = Set<Int64>()
        for ref in refs {
            guard (ref.coverUrl ?? "").isEmpty, done.insert(ref.id).inserted else { continue }
            guard _jsEngine.parser(for: ref.sourceName) != nil else { continue }
            guard let results = try? await browse(sourceName: ref.sourceName, page: 1,
                                                  order: .relevance, query: ref.title),
                  !results.isEmpty else { continue }
            let match = results.first { $0.title.caseInsensitiveCompare(ref.title) == .orderedSame }
                ?? results.first
            if let cover = match?.coverUrl, !cover.isEmpty {
                store.updateCover(mangaId: ref.id, coverUrl: cover)
            }
        }
        refreshPublishedData()
    }

    func signOutSupabase() {
        store.supabaseSyncEnabled = false
        SupabaseSync.shared.signOut()
    }

    private func refreshPublishedData() {
        // Refresh local state from snapshot after pull/restore
        self.favourites = store.snapshot.favourites
        self.history = store.snapshot.history
        self.bookmarks = store.snapshot.bookmarks
        self.categories = store.snapshot.categories.filter { $0.deletedAt == nil }
        self.readLater = store.snapshot.readLater
        publishWidgets()
    }
}
