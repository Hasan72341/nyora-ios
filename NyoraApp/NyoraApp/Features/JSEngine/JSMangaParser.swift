import Foundation
import NyoraEngine

// MARK: - Decodable bridge types (JS → Swift)

private struct JSManga: Decodable {
    let id: String?
    let url: String
    let publicUrl: String?
    let coverUrl: String?
    let largeCoverUrl: String?
    let title: String
    let altTitles: [String]?
    let rating: Double?
    let tags: [JSTag]?
    let state: String?
    let authors: [String]?
    let contentRating: String?
    let description: String?
    let chapters: [JSChapter]?

    struct JSTag: Decodable {
        let title: String
        let key: String
    }

    struct JSChapter: Decodable {
        let id: String?
        let url: String
        let title: String?
        let number: Double?
        let volume: Double?
        let branch: String?
        let uploadDate: Double?
        let scanlator: String?
    }
}

private struct JSPage: Decodable {
    let id: String?
    let url: String
    let preview: String?
}

// MARK: - Decoder helpers

private func decodeManga(_ js: JSManga, source: MangaParserSource) -> Manga {
    let url = js.url
    // Trust the bundle-stamped canonical id (nyoraId) so it matches Android/Web/Mac;
    // fall back to the local hash only if the bundle didn't provide one.
    let id = js.id.flatMap { Int64($0) } ?? generateUid(url)
    let tags: Set<MangaTag> = Set((js.tags ?? []).map { t in
        MangaTag(title: t.title, key: t.key, source: source)
    })
    let state = js.state.flatMap { MangaState(rawValue: $0.uppercased()) }
    let cr = js.contentRating.flatMap { ContentRating(rawValue: $0.uppercased()) }
    return Manga(
        id: id,
        title: js.title,
        altTitles: Set(js.altTitles ?? []),
        url: url,
        publicUrl: js.publicUrl ?? url,
        rating: js.rating.map { Float($0) } ?? NyoraConstants.ratingUnknown,
        contentRating: cr,
        coverUrl: js.coverUrl,
        tags: tags,
        state: state,
        authors: Set(js.authors ?? []),
        largeCoverUrl: js.largeCoverUrl,
        description: js.description?.isEmpty == true ? nil : js.description,
        chapters: js.chapters.map { decodeChapters($0, source: source) },
        source: source
    )
}

private func decodeChapters(_ jsChapters: [JSManga.JSChapter], source: MangaParserSource) -> [MangaChapter] {
    jsChapters.map { ch in
        MangaChapter(
            id: ch.id.flatMap { Int64($0) } ?? generateUid(ch.url),
            title: ch.title?.isEmpty == true ? nil : ch.title,
            number: Float(ch.number ?? 0),
            volume: Int(ch.volume ?? 0),
            url: ch.url,
            scanlator: ch.scanlator?.isEmpty == true ? nil : ch.scanlator,
            uploadDate: Int64(ch.uploadDate ?? 0),
            branch: ch.branch,
            source: source
        )
    }
}

private func decodePages(_ jsPages: [JSPage], source: MangaParserSource) -> [MangaPage] {
    jsPages.map { p in
        MangaPage(id: generateUid(p.url), url: p.url, preview: p.preview, source: source)
    }
}

// MARK: - JSMangaParser

/// Wraps one JS parser (from the nyora-web JS bundle) as a Swift MangaParser.
/// Network calls go through JSParserEngine's WKWebView → URLSession directly (no proxy).
final class JSMangaParser: @unchecked Sendable, MangaParser {
    let source: MangaParserSource
    let domain: String
    // JSParserEngine is a @MainActor singleton; Swift hops to main actor on each await call.
    private unowned let engine: JSParserEngine

    init(source: MangaParserSource, domain: String, engine: JSParserEngine) {
        self.source = source
        self.domain = domain
        self.engine = engine
    }

    // SortOrder qualified to avoid ambiguity with Foundation's SortOrder (iOS 16+).
    var availableSortOrders: [NyoraEngine.SortOrder] {
        [.updated, .popularity, .newest, .alphabetical, .relevance]
    }

    var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(isSearchSupported: true)
    }

    func requestHeaders() -> [String: String] {
        [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
            "Referer": "https://\(domain)/",
        ]
    }

    // MARK: - MangaParser methods

    func getList(page: Int, order: NyoraEngine.SortOrder, filter: MangaListFilter) async throws -> [Manga] {
        let src = source
        var args: [String: Any] = ["page": page, "order": order.rawValue]
        if let q = filter.query, !q.isEmpty { args["filter"] = ["query": q] }
        let json = try await engine.runParser(method: "list", sourceId: src.name, args: args)
        guard let data = json.data(using: .utf8),
              let list = try? JSONDecoder().decode([JSManga].self, from: data) else { return [] }
        return list.map { decodeManga($0, source: src) }
    }

    func getDetails(_ manga: Manga) async throws -> Manga {
        let src = source
        let json = try await engine.runParser(method: "details", sourceId: src.name, args: ["url": manga.url])
        guard let data = json.data(using: .utf8),
              let js = try? JSONDecoder().decode(JSManga.self, from: data) else { return manga }
        return decodeManga(js, source: src)
    }

    func getPages(_ chapter: MangaChapter) async throws -> [MangaPage] {
        let src = source
        var args: [String: Any] = ["url": chapter.url]
        if let b = chapter.branch { args["branch"] = b }
        let json = try await engine.runParser(method: "pages", sourceId: src.name, args: args)
        guard let data = json.data(using: .utf8),
              let list = try? JSONDecoder().decode([JSPage].self, from: data) else { return [] }
        return decodePages(list, source: src)
    }

    func getPageUrl(_ page: MangaPage) async throws -> String { page.url }

    func getFilterOptions() async throws -> MangaListFilterOptions { .empty }
}
