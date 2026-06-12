import Foundation
import SwiftUI
import NyoraEngine

/// Per-chapter download lifecycle. Mirrors nyora-android's download states.
enum DownloadState: String, Codable {
    case queued
    case downloading
    case done
    case failed
}

/// One downloaded (or in-flight) chapter, persisted to downloads.json. Page images live at
/// Application Support/Nyora/downloads/<mangaId>/<chapterId>/<index>.img.
struct DownloadedChapter: Codable, Identifiable, Hashable {
    let mangaId: Int64
    let chapterId: Int64
    let chapterTitle: String
    var pageCount: Int          // total pages discovered for the chapter
    var savedCount: Int         // pages successfully written to disk
    var state: DownloadState
    
    /// Full metadata needed to reconstruct a real `MangaChapter` for the reader.
    var originalChapter: MangaChapter?

    var id: Int64 { chapterId }

    var progress: Double {
        guard pageCount > 0 else { return state == .done ? 1 : 0 }
        return min(1, Double(savedCount) / Double(pageCount))
    }
}

/// A downloaded manga grouping (the saved ref so we can render covers offline-ish via headers).
struct DownloadedManga: Codable, Identifiable, Hashable {
    let manga: MangaRef
    var id: Int64 { manga.id }
}

/// Singleton that downloads chapter pages to disk and tracks/persists their state.
///
/// Each chapter's pages are fetched through `AppModel.pages(...)` then each image is pulled
/// with `AppModel.imageRequest(...)` headers (Referer etc.) over URLSession and written as a
/// raw `<index>.img` file. State is published for the UI and mirrored to downloads.json so a
/// relaunch knows what is already on disk.
@MainActor
final class DownloadManager: ObservableObject {
    static let shared = DownloadManager()

    /// Downloaded/queued manga, newest first.
    @Published private(set) var manga: [DownloadedManga] = []
    /// chapterId → record. Flat map keyed by chapter for O(1) progress lookups in the UI.
    @Published private(set) var chapters: [Int64: DownloadedChapter] = [:]

    private var model: AppModelBridge { AppModelBridge.shared }
    private let queue = DispatchQueue(label: "nyora.downloadstore")
    private var tasks: [Int64: Task<Void, Never>] = [:]   // chapterId → in-flight task

    // MARK: Paths

    private static let baseDir: URL = {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Nyora", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private static var downloadsDir: URL {
        let d = baseDir.appendingPathComponent("downloads", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }

    private let stateURL = DownloadManager.baseDir.appendingPathComponent("downloads.json")

    private func chapterDir(mangaId: Int64, chapterId: Int64) -> URL {
        DownloadManager.downloadsDir
            .appendingPathComponent("\(mangaId)", isDirectory: true)
            .appendingPathComponent("\(chapterId)", isDirectory: true)
    }

    /// Local file URL for a saved page image (does NOT guarantee existence).
    func pageFileURL(mangaId: Int64, chapterId: Int64, index: Int) -> URL {
        chapterDir(mangaId: mangaId, chapterId: chapterId)
            .appendingPathComponent("\(index).img")
    }

    // MARK: Persistence (mirrors LibraryStore's pattern)

    private struct Snapshot: Codable {
        var manga: [DownloadedManga] = []
        var chapters: [DownloadedChapter] = []

        init() {}
        init(manga: [DownloadedManga], chapters: [DownloadedChapter]) {
            self.manga = manga
            self.chapters = chapters
        }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            manga = try c.decodeIfPresent([DownloadedManga].self, forKey: .manga) ?? []
            chapters = try c.decodeIfPresent([DownloadedChapter].self, forKey: .chapters) ?? []
        }
    }

    private init() {
        if let data = try? Data(contentsOf: stateURL),
           let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            manga = decoded.manga
            // Any chapter left mid-flight from a previous run is considered failed (resumable).
            chapters = Dictionary(uniqueKeysWithValues: decoded.chapters.map { ch in
                var ch = ch
                if ch.state == .downloading || ch.state == .queued { ch.state = .failed }
                return (ch.chapterId, ch)
            })
        }
    }

    private func persist() {
        let snap = Snapshot(manga: manga, chapters: Array(chapters.values))
        queue.async { [stateURL] in
            if let data = try? JSONEncoder().encode(snap) {
                try? data.write(to: stateURL, options: .atomic)
            }
        }
    }

    // MARK: Public API

    func isDownloaded(_ chapterId: Int64) -> Bool {
        chapters[chapterId]?.state == .done
    }

    func state(for chapterId: Int64) -> DownloadState? {
        chapters[chapterId]?.state
    }

    func chapters(for mangaId: Int64) -> [DownloadedChapter] {
        chapters.values
            .filter { $0.mangaId == mangaId }
            .sorted { $0.chapterId < $1.chapterId }
    }

    /// Queue (or re-queue) a chapter for offline download.
    func download(manga: Manga, chapter: MangaChapter) {
        // Already complete or in progress — no-op.
        if let existing = chapters[chapter.id],
           existing.state == .done || existing.state == .downloading || existing.state == .queued {
            return
        }

        if !self.manga.contains(where: { $0.id == manga.id }) {
            self.manga.insert(DownloadedManga(manga: MangaRef(manga)), at: 0)
        }

        var record = DownloadedChapter(
            mangaId: manga.id,
            chapterId: chapter.id,
            chapterTitle: chapter.name,
            pageCount: 0,
            savedCount: 0,
            state: .queued,
            originalChapter: chapter
        )
        chapters[chapter.id] = record
        persist()

        let sourceName = manga.source.name
        let mangaId = manga.id
        let chapterId = chapter.id

        tasks[chapterId] = Task { [weak self] in
            guard let self else { return }
            do {
                record.state = .downloading
                self.chapters[chapterId] = record
                self.objectWillChange.send()

                let pages = try await self.model.appModel.pages(for: chapter, mangaId: mangaId, sourceName: sourceName)
                record.pageCount = pages.count
                self.chapters[chapterId] = record
                self.persist()

                let dir = self.chapterDir(mangaId: mangaId, chapterId: chapterId)
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

                for (index, page) in pages.enumerated() {
                    try Task.checkCancellation()
                    guard let req = self.model.appModel.imageRequest(for: page, sourceName: sourceName) else { continue }
                    let dest = self.pageFileURL(mangaId: mangaId, chapterId: chapterId, index: index)
                    if FileManager.default.fileExists(atPath: dest.path) {
                        record.savedCount = index + 1
                        self.chapters[chapterId] = record
                        self.objectWillChange.send()
                        continue
                    }
                    let data = try await self.fetch(url: req.url, headers: req.headers)
                    try data.write(to: dest, options: .atomic)
                    record.savedCount = index + 1
                    self.chapters[chapterId] = record
                    self.objectWillChange.send()
                }

                record.state = record.savedCount >= record.pageCount && record.pageCount > 0 ? .done : .failed
                self.chapters[chapterId] = record
                self.persist()
            } catch is CancellationError {
                // Cancellation is driven by delete(); state is handled there.
            } catch {
                record.state = .failed
                self.chapters[chapterId] = record
                self.persist()
            }
            self.tasks[chapterId] = nil
        }
    }

    /// Delete a single downloaded chapter (files + state). Cancels an in-flight download.
    func delete(chapterId: Int64) {
        tasks[chapterId]?.cancel()
        tasks[chapterId] = nil
        guard let record = chapters[chapterId] else { return }
        try? FileManager.default.removeItem(at: chapterDir(mangaId: record.mangaId, chapterId: chapterId))
        chapters[chapterId] = nil
        pruneEmptyManga(record.mangaId)
        persist()
    }

    /// Delete every downloaded chapter for a manga (files + state).
    func delete(mangaId: Int64) {
        for ch in chapters(for: mangaId) {
            tasks[ch.chapterId]?.cancel()
            tasks[ch.chapterId] = nil
            chapters[ch.chapterId] = nil
        }
        try? FileManager.default.removeItem(
            at: DownloadManager.downloadsDir.appendingPathComponent("\(mangaId)", isDirectory: true)
        )
        manga.removeAll { $0.id == mangaId }
        persist()
    }

    /// Remove everything (all manga, all chapters, all files).
    func clearAll() {
        for t in tasks.values { t.cancel() }
        tasks.removeAll()
        try? FileManager.default.removeItem(at: DownloadManager.downloadsDir)
        manga.removeAll()
        chapters.removeAll()
        persist()
    }

    /// Drop a manga grouping once it has no remaining chapters.
    private func pruneEmptyManga(_ mangaId: Int64) {
        if chapters(for: mangaId).isEmpty {
            manga.removeAll { $0.id == mangaId }
        }
    }

    // MARK: Offline reading helper

    /// File URLs (in page order) for a downloaded chapter that actually exist on disk.
    /// A reader can feed these into `UIImage(contentsOfFile:)` to read fully offline.
    func localPageURLs(mangaId: Int64, chapterId: Int64) -> [URL] {
        guard let record = chapters[chapterId], record.state == .done else { return [] }
        let fm = FileManager.default
        return (0..<record.pageCount).compactMap { index in
            let url = pageFileURL(mangaId: mangaId, chapterId: chapterId, index: index)
            return fm.fileExists(atPath: url.path) ? url : nil
        }
    }

    /// Returns local file URLs ONLY if the chapter is fully downloaded and all files are on disk.
    func localPagesIfComplete(mangaId: Int64, chapterId: Int64) -> [URL] {
        guard let record = chapters[chapterId], record.state == .done else { return [] }
        let urls = localPageURLs(mangaId: mangaId, chapterId: chapterId)
        return urls.count == record.pageCount ? urls : []
    }

    // MARK: Size reporting

    /// Total bytes used by all downloads.
    func totalSizeBytes() -> Int64 {
        directorySize(DownloadManager.downloadsDir)
    }

    /// Bytes used by one manga's downloads.
    func sizeBytes(mangaId: Int64) -> Int64 {
        directorySize(DownloadManager.downloadsDir.appendingPathComponent("\(mangaId)", isDirectory: true))
    }

    private func directorySize(_ url: URL) -> Int64 {
        let fm = FileManager.default
        guard let en = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total: Int64 = 0
        for case let fileURL as URL in en {
            let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            total += Int64(size)
        }
        return total
    }

    // MARK: Networking

    private lazy var session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: cfg)
    }()

    private func fetch(url: URL, headers: [String: String]) async throws -> Data {
        var req = URLRequest(url: url)
        for (k, v) in headers { req.setValue(v, forHTTPHeaderField: k) }
        let (data, response) = try await session.data(for: req)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        return data
    }
}

/// Bridges the singleton `DownloadManager` to the app's `AppModel`, which owns the engine
/// pass-throughs (`pages`, `imageRequest`). The orchestrator injects the live model once at
/// launch; until then a throwaway instance keeps the API non-optional.
@MainActor
final class AppModelBridge {
    static let shared = AppModelBridge()
    var appModel: AppModel = AppModel()
    private init() {}
}

extension Int64 {
    /// Human-readable byte count for size labels.
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .file)
    }
}
