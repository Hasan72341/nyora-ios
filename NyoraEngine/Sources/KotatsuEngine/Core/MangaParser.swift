import Foundation

/// The capability surface every source implements. Mirrors
/// `org.koitharu.nyora.parsers.MangaParser` (minus JVM-only OkHttp `Interceptor` and the
/// search-query DSL, which `AbstractMangaParser` adapts to the `MangaListFilter` path).
public protocol MangaParser: AnyObject, Sendable {
    var source: MangaParserSource { get }
    var domain: String { get }
    var availableSortOrders: [SortOrder] { get }
    var filterCapabilities: MangaListFilterCapabilities { get }

    /// HTTP headers attached to every request (User-Agent, Referer, etc.).
    func requestHeaders() -> [String: String]

    /// One page of the catalog/search. `page` is 1-based.
    func getList(page: Int, order: SortOrder, filter: MangaListFilter) async throws -> [Manga]

    /// Fill in description, tags, cover, and the chapter list for a manga.
    func getDetails(_ manga: Manga) async throws -> Manga

    /// Page list for a chapter.
    func getPages(_ chapter: MangaChapter) async throws -> [MangaPage]

    /// Resolve a page to its final image URL (sources that defer image URLs).
    func getPageUrl(_ page: MangaPage) async throws -> String

    /// Available filter values (tags, states, locales…).
    func getFilterOptions() async throws -> MangaListFilterOptions
}

public extension MangaParser {
    func getPageUrl(_ page: MangaPage) async throws -> String { page.url }

    /// Default order = first declared available order (matches Nyora's behaviour).
    var defaultSortOrder: SortOrder {
        availableSortOrders.first ?? .updated
    }
}
