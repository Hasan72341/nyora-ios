import Foundation
import WebKit
import NyoraEngine

/// Persisted recent-search queries. The app does not yet have a search-history feature wired
/// into the search UI, so this is a small standalone UserDefaults-backed store: the search
/// screens can call `record(_:)` to remember queries, and "Clear search history" empties it.
/// Implemented for real (not a no-op) so the Data-removal action has concrete state to clear.
enum SearchHistoryStore {
    private static let key = "search_history_queries"

    static var queries: [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    static func record(_ query: String) {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        var list = queries.filter { $0.caseInsensitiveCompare(q) != .orderedSame }
        list.insert(q, at: 0)
        if list.count > 50 { list = Array(list.prefix(50)) }
        UserDefaults.standard.set(list, forKey: key)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

/// Centralised, real implementations for the Data-removal actions and the storage-usage
/// breakdown. Heavy/IO work runs off the main thread; the few `@MainActor` collaborators
/// (AppModel, DownloadManager) are hopped to explicitly.
enum CacheManager {

    // MARK: Directory helpers (shared layout with LibraryStore/DownloadManager)

    /// Application Support/Nyora — where library.json, downloads/, etc. live.
    static var nyoraDir: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Nyora", isDirectory: true)
    }

    /// The downloads root used by DownloadManager.
    static var downloadsDir: URL {
        nyoraDir.appendingPathComponent("downloads", isDirectory: true)
    }

    /// System caches directory (NSURLCache disk store + anything we drop in Caches).
    static var cachesDir: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    }

    /// Optional dedicated reader-page cache dir, if a future reader writes one. Cleared by
    /// "Clear pages cache" when present.
    static var pagesCacheDir: URL {
        nyoraDir.appendingPathComponent("pages_cache", isDirectory: true)
    }

    // MARK: Search history

    static func clearSearchHistory() {
        SearchHistoryStore.clear()
    }

    // MARK: Thumbnails / pages (image) caches

    /// Cover thumbnails and reader page images share the same loader/URLCache, so both
    /// actions funnel through ImageLoader plus the shared URLCache.
    static func clearThumbnailsCache() {
        ImageLoader.shared.clearAll()
        URLCache.shared.removeAllCachedResponses()
    }

    static func clearPagesCache() {
        ImageLoader.shared.clearAll()
        URLCache.shared.removeAllCachedResponses()
        // Remove an on-disk reader page cache dir if one exists.
        try? FileManager.default.removeItem(at: pagesCacheDir)
    }

    // MARK: Network cache

    static func clearNetworkCache() {
        URLCache.shared.removeAllCachedResponses()
    }

    // MARK: Cookies

    static func clearCookies() {
        let storage = HTTPCookieStorage.shared
        for cookie in storage.cookies ?? [] {
            storage.deleteCookie(cookie)
        }
    }

    // MARK: Web view browsing data

    static func clearBrowserData() async {
        let store = WKWebsiteDataStore.default()
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        await store.removeData(ofTypes: types, modifiedSince: .distantPast)
    }

    // MARK: Read downloaded chapters

    /// Delete downloaded chapters whose chapterId is in the read set. Returns how many were
    /// removed. Mutates DownloadManager state on the main actor.
    @MainActor
    static func deleteReadChapters(model: AppModel) -> Int {
        let read = model.readChapterIds
        let dm = DownloadManager.shared
        let targets = dm.chapters.values.filter { read.contains($0.chapterId) }
        for ch in targets { dm.delete(chapterId: ch.chapterId) }
        return targets.count
    }

    // MARK: Sizes (off main thread)

    struct StorageBreakdown {
        var images: Int64 = 0      // decoded-image loader URLCache + shared URLCache
        var downloads: Int64 = 0   // DownloadManager downloads dir
        var caches: Int64 = 0      // system Caches dir (minus what we count elsewhere)
        var total: Int64 { images + downloads + caches }
    }

    /// Compute real byte sizes for the storage-usage bar. Runs file I/O on a background queue.
    static func computeStorage() async -> StorageBreakdown {
        // ImageLoader URLCache usage must be read on whatever thread owns it; it's a simple
        // counter read, safe to do here.
        let imageBytes = ImageLoader.shared.diskCacheBytes
            + Int64(URLCache.shared.currentDiskUsage + URLCache.shared.currentMemoryUsage)
        let downloadsURL = downloadsDir
        let cachesURL = cachesDir
        return await withCheckedContinuation { cont in
            DispatchQueue.global(qos: .utility).async {
                var b = StorageBreakdown()
                b.images = imageBytes
                b.downloads = directorySize(downloadsURL)
                if let cachesURL { b.caches = directorySize(cachesURL) }
                cont.resume(returning: b)
            }
        }
    }

    static func directorySize(_ url: URL) -> Int64 {
        let fm = FileManager.default
        guard let en = fm.enumerator(at: url, includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileSizeKey]) else { return 0 }
        var total: Int64 = 0
        for case let fileURL as URL in en {
            let vals = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileSizeKey])
            total += Int64(vals?.totalFileAllocatedSize ?? vals?.fileSize ?? 0)
        }
        return total
    }
}
