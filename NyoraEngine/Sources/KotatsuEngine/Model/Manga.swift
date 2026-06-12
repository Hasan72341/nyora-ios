import Foundation

/// A tag/genre. Mirrors `org.koitharu.nyora.parsers.model.MangaTag`.
public struct MangaTag: Hashable, Codable, Sendable {
    public let title: String
    public let key: String
    public let source: MangaParserSource

    public init(title: String, key: String, source: MangaParserSource) {
        self.title = title
        self.key = key
        self.source = source
    }
}

/// A single chapter. Mirrors `org.koitharu.nyora.parsers.model.MangaChapter`.
public struct MangaChapter: Hashable, Codable, Sendable {
    public let id: Int64
    /// Raw chapter title as parsed; `name` derives a display string when nil.
    public let title: String?
    /// Chapter number; `0` when unknown.
    public let number: Float
    /// Volume number; `0` when unknown.
    public let volume: Int
    /// Source-relative or absolute chapter URL.
    public let url: String
    public let scanlator: String?
    /// Upload time in epoch milliseconds; `0` when unknown.
    public let uploadDate: Int64
    public let branch: String?
    public let source: MangaParserSource

    public init(
        id: Int64,
        title: String?,
        number: Float,
        volume: Int,
        url: String,
        scanlator: String?,
        uploadDate: Int64,
        branch: String?,
        source: MangaParserSource
    ) {
        self.id = id
        self.title = title
        self.number = number
        self.volume = volume
        self.url = url
        self.scanlator = scanlator
        self.uploadDate = uploadDate
        self.branch = branch
        self.source = source
    }

    /// Display name, falling back to "Vol. x Ch. y" when no explicit title was parsed.
    public var name: String {
        if let title, !title.isEmpty { return title }
        var parts: [String] = []
        if volume > 0 { parts.append("Vol. \(volume)") }
        if number > 0 {
            let n = number.rounded() == number ? String(Int(number)) : String(number)
            parts.append("Ch. \(n)")
        }
        return parts.isEmpty ? "Chapter" : parts.joined(separator: " ")
    }
}

/// A single readable page. Mirrors `org.koitharu.nyora.parsers.model.MangaPage`.
public struct MangaPage: Hashable, Codable, Sendable {
    public let id: Int64
    /// Either a direct image URL or a page URL that `getPageUrl` later resolves.
    public let url: String
    public let preview: String?
    public let source: MangaParserSource

    public init(id: Int64, url: String, preview: String?, source: MangaParserSource) {
        self.id = id
        self.url = url
        self.preview = preview
        self.source = source
    }
}

/// Core manga entity. Mirrors `org.koitharu.nyora.parsers.model.Manga`.
public struct Manga: Hashable, Codable, Sendable {
    public let id: Int64
    public let title: String
    public let altTitles: Set<String>
    /// Source-relative manga URL (the canonical id basis).
    public let url: String
    /// Absolute, shareable URL.
    public let publicUrl: String
    /// `NyoraConstants.ratingUnknown` when the source reports no rating.
    public let rating: Float
    public let contentRating: ContentRating?
    public let coverUrl: String?
    public let tags: Set<MangaTag>
    public let state: MangaState?
    public let authors: Set<String>
    public let largeCoverUrl: String?
    public let description: String?
    /// nil until `getDetails` populates it.
    public let chapters: [MangaChapter]?
    public let source: MangaParserSource

    public init(
        id: Int64,
        title: String,
        altTitles: Set<String> = [],
        url: String,
        publicUrl: String,
        rating: Float = NyoraConstants.ratingUnknown,
        contentRating: ContentRating? = nil,
        coverUrl: String? = nil,
        tags: Set<MangaTag> = [],
        state: MangaState? = nil,
        authors: Set<String> = [],
        largeCoverUrl: String? = nil,
        description: String? = nil,
        chapters: [MangaChapter]? = nil,
        source: MangaParserSource
    ) {
        self.id = id
        self.title = title
        self.altTitles = altTitles
        self.url = url
        self.publicUrl = publicUrl
        self.rating = rating
        self.contentRating = contentRating
        self.coverUrl = coverUrl
        self.tags = tags
        self.state = state
        self.authors = authors
        self.largeCoverUrl = largeCoverUrl
        self.description = description
        self.chapters = chapters
        self.source = source
    }

    public var hasRating: Bool { rating > 0 && rating <= 1 }
    public var author: String? { authors.first }
    public var altTitle: String? { altTitles.first }

    /// Returns a copy with the given fields overridden — the Swift analogue of
    /// Kotlin's `data class copy(...)`, used heavily by `getDetails`.
    public func copy(
        title: String? = nil,
        altTitles: Set<String>? = nil,
        coverUrl: String?? = nil,
        largeCoverUrl: String?? = nil,
        description: String?? = nil,
        tags: Set<MangaTag>? = nil,
        state: MangaState?? = nil,
        authors: Set<String>? = nil,
        rating: Float? = nil,
        contentRating: ContentRating?? = nil,
        chapters: [MangaChapter]?? = nil
    ) -> Manga {
        Manga(
            id: id,
            title: title ?? self.title,
            altTitles: altTitles ?? self.altTitles,
            url: url,
            publicUrl: publicUrl,
            rating: rating ?? self.rating,
            contentRating: contentRating ?? self.contentRating,
            coverUrl: coverUrl ?? self.coverUrl,
            tags: tags ?? self.tags,
            state: state ?? self.state,
            authors: authors ?? self.authors,
            largeCoverUrl: largeCoverUrl ?? self.largeCoverUrl,
            description: description ?? self.description,
            chapters: chapters ?? self.chapters,
            source: source
        )
    }
}
