import Foundation
import SwiftUI
import UIKit

/// One imported local manga: a user-selected folder of images. The folder is reached via a
/// security-scoped bookmark (so access survives relaunches). Pages are the sorted image files
/// directly inside the folder; if the folder instead contains subfolders, each subfolder is a
/// chapter and its sorted images are that chapter's pages.
struct LocalManga: Codable, Identifiable, Hashable {
    let id: String              // stable UUID string
    var title: String           // derived from the folder/archive name at import time
    var bookmark: Data          // security-scoped bookmark to the root folder (empty for extracted archives)
    var chapters: [LocalChapter]
    var importedAt: Date
    /// For archive (CBZ/ZIP) imports: the directory name under the managed "Imports" root that
    /// holds the extracted pages. `nil`/empty for folder imports, which use `bookmark` instead.
    var storeDirName: String?

    var pageCount: Int { chapters.reduce(0) { $0 + $1.pageRelativePaths.count } }

    /// True when pages live in our own managed store (extracted archive) rather than a bookmarked folder.
    var isExtracted: Bool { !(storeDirName ?? "").isEmpty }

    init(id: String, title: String, bookmark: Data, chapters: [LocalChapter],
         importedAt: Date, storeDirName: String? = nil) {
        self.id = id
        self.title = title
        self.bookmark = bookmark
        self.chapters = chapters
        self.importedAt = importedAt
        self.storeDirName = storeDirName
    }
}

/// A chapter inside a local manga. `pageRelativePaths` are paths relative to the resolved
/// root folder URL (e.g. "01.jpg" for a flat folder, or "Chapter 1/01.jpg" for subfolders).
struct LocalChapter: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var pageRelativePaths: [String]
}

/// JSON-file persistence in Application Support, mirroring `LibraryStore`'s pattern. Holds the
/// list of imported local manga and their security-scoped bookmarks in `local.json`. Deliberately
/// simple and synchronous on a background queue — the data volumes are tiny.
final class LocalLibraryStore: ObservableObject {
    static let shared = LocalLibraryStore()

    /// Persisted state. Custom decoder keeps adding fields backward-compatible.
    struct Snapshot: Codable {
        var items: [LocalManga] = []

        init() {}

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            items = try c.decodeIfPresent([LocalManga].self, forKey: .items) ?? []
        }
    }

    private let url: URL
    /// Root directory holding extracted-archive page files (one subdirectory per imported archive).
    private let importsRoot: URL
    private let queue = DispatchQueue(label: "nyora.locallibrarystore")
    @Published private(set) var items: [LocalManga] = []

    private let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "webp", "gif", "heic", "bmp"]

    init() {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Nyora", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.importsRoot = dir.appendingPathComponent("LocalImports", isDirectory: true)
        try? FileManager.default.createDirectory(at: importsRoot, withIntermediateDirectories: true)
        self.url = dir.appendingPathComponent("local.json")
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            self.items = decoded.items
        } else {
            self.items = []
        }
    }

    private func persist() {
        let snap = Snapshot(items: items)
        queue.async { [url] in
            if let data = try? JSONEncoder().encode(snap) {
                try? data.write(to: url, options: .atomic)
            }
        }
    }

    // MARK: Import

    enum ImportError: LocalizedError {
        case accessDenied
        case noImages
        case bookmarkFailed

        var errorDescription: String? {
            switch self {
            case .accessDenied: return "Couldn’t access the selected folder."
            case .noImages: return "No image files were found in that folder."
            case .bookmarkFailed: return "Couldn’t save a reference to that folder."
            }
        }
    }

    /// Scan a user-selected folder and add it as a local manga. `folderURL` is expected to be a
    /// security-scoped URL freshly returned by `.fileImporter`.
    func importFolder(_ folderURL: URL) throws {
        let scoped = folderURL.startAccessingSecurityScopedResource()
        defer { if scoped { folderURL.stopAccessingSecurityScopedResource() } }

        let fm = FileManager.default

        // Subfolders → chapters. If none, the folder itself is a single chapter.
        let subdirs = (try? fm.contentsOfDirectory(at: folderURL,
                                                    includingPropertiesForKeys: [.isDirectoryKey],
                                                    options: [.skipsHiddenFiles]))?
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending } ?? []

        var chapters: [LocalChapter] = []
        if subdirs.isEmpty {
            let pages = imageFiles(in: folderURL).map { $0.lastPathComponent }
            if !pages.isEmpty {
                chapters.append(LocalChapter(id: UUID().uuidString, name: folderURL.lastPathComponent, pageRelativePaths: pages))
            }
        } else {
            for sub in subdirs {
                let folder = sub.lastPathComponent
                let pages = imageFiles(in: sub).map { "\(folder)/\($0.lastPathComponent)" }
                if !pages.isEmpty {
                    chapters.append(LocalChapter(id: UUID().uuidString, name: folder, pageRelativePaths: pages))
                }
            }
            // Fall back to top-level images if subfolders held no images.
            if chapters.isEmpty {
                let pages = imageFiles(in: folderURL).map { $0.lastPathComponent }
                if !pages.isEmpty {
                    chapters.append(LocalChapter(id: UUID().uuidString, name: folderURL.lastPathComponent, pageRelativePaths: pages))
                }
            }
        }

        guard !chapters.isEmpty else { throw ImportError.noImages }

        guard let bookmark = try? folderURL.bookmarkData(options: [],
                                                          includingResourceValuesForKeys: nil,
                                                          relativeTo: nil) else {
            throw ImportError.bookmarkFailed
        }

        let item = LocalManga(
            id: UUID().uuidString,
            title: folderURL.lastPathComponent,
            bookmark: bookmark,
            chapters: chapters,
            importedAt: Date()
        )
        items.insert(item, at: 0)
        persist()
    }

    /// Import a CBZ/ZIP image archive: extract its images into the managed store and register a
    /// single-chapter local manga. `fileURL` is a security-scoped URL from a document picker.
    /// Throws `ArchiveImporter.ArchiveError` (with honest messages for CBR/EPUB/unsupported).
    func importArchive(_ fileURL: URL) throws {
        let extracted = try ArchiveImporter.importArchive(fileURL, into: importsRoot)

        let chapter = LocalChapter(id: UUID().uuidString,
                                   name: extracted.title,
                                   pageRelativePaths: extracted.pageRelativePaths)
        let item = LocalManga(
            id: UUID().uuidString,
            title: extracted.title,
            bookmark: Data(),
            chapters: [chapter],
            importedAt: Date(),
            storeDirName: extracted.storeDirName
        )
        items.insert(item, at: 0)
        persist()
    }

    func delete(_ item: LocalManga) {
        // Extracted archives own their files; remove them from disk so storage isn't leaked.
        if let dir = item.storeDirName, !dir.isEmpty {
            try? FileManager.default.removeItem(at: importsRoot.appendingPathComponent(dir, isDirectory: true))
        }
        items.removeAll { $0.id == item.id }
        persist()
    }

    // MARK: Resolving files

    /// Resolve the security-scoped bookmark to a live folder URL. Caller is responsible for
    /// balancing `startAccessingSecurityScopedResource` / `stop` around any file reads.
    func resolveRoot(for item: LocalManga) -> URL? {
        // Extracted archives live in our own container — no bookmark or security scope needed.
        if let dir = item.storeDirName, !dir.isEmpty {
            return importsRoot.appendingPathComponent(dir, isDirectory: true)
        }
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: item.bookmark,
                                 options: [],
                                 relativeTo: nil,
                                 bookmarkDataIsStale: &stale) else { return nil }
        return url
    }

    /// Absolute page file URLs for a chapter, resolved against the root bookmark.
    func pageURLs(for item: LocalManga, chapter: LocalChapter) -> [URL] {
        guard let root = resolveRoot(for: item) else { return [] }
        return chapter.pageRelativePaths.map { rel in
            rel.split(separator: "/").reduce(root) { $0.appendingPathComponent(String($1)) }
        }
    }

    /// Load an arbitrary image file from disk into a `UIImage`, performing the security-scoped
    /// dance around the root folder. Used for both covers and reader pages.
    func loadImage(for item: LocalManga, at fileURL: URL) async -> UIImage? {
        guard let root = resolveRoot(for: item) else { return nil }
        // Extracted archives are in our container; skip the security-scoped dance for them.
        let needsScope = !item.isExtracted
        return await Task.detached(priority: .userInitiated) {
            let scoped = needsScope && root.startAccessingSecurityScopedResource()
            defer { if scoped { root.stopAccessingSecurityScopedResource() } }
            guard let data = try? Data(contentsOf: fileURL) else { return nil }
            return UIImage(data: data)
        }.value
    }

    /// The first page of the first chapter — used as the grid cover.
    func coverURL(for item: LocalManga) -> URL? {
        guard let first = item.chapters.first else { return nil }
        return pageURLs(for: item, chapter: first).first
    }

    // MARK: Helpers

    private func imageFiles(in directory: URL) -> [URL] {
        let fm = FileManager.default
        let contents = (try? fm.contentsOfDirectory(at: directory,
                                                     includingPropertiesForKeys: [.isRegularFileKey],
                                                     options: [.skipsHiddenFiles])) ?? []
        return contents
            .filter { imageExtensions.contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }
}

private extension LocalLibraryStore.Snapshot {
    init(items: [LocalManga]) {
        self.init()
        self.items = items
    }
}
