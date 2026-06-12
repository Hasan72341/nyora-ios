import Foundation

/// Query parameters for a list/search request.
/// Mirrors `org.koitharu.nyora.parsers.model.MangaListFilter`.
public struct MangaListFilter: Hashable, Sendable {
    public let query: String?
    public let tags: Set<MangaTag>
    public let tagsExclude: Set<MangaTag>
    public let locale: String?
    public let originalLocale: String?
    public let states: Set<MangaState>
    public let contentRating: Set<ContentRating>
    public let types: Set<ContentType>
    public let demographics: Set<Demographic>
    public let year: Int
    public let yearFrom: Int
    public let yearTo: Int
    public let author: String?

    public init(
        query: String? = nil,
        tags: Set<MangaTag> = [],
        tagsExclude: Set<MangaTag> = [],
        locale: String? = nil,
        originalLocale: String? = nil,
        states: Set<MangaState> = [],
        contentRating: Set<ContentRating> = [],
        types: Set<ContentType> = [],
        demographics: Set<Demographic> = [],
        year: Int = NyoraConstants.yearUnknown,
        yearFrom: Int = NyoraConstants.yearUnknown,
        yearTo: Int = NyoraConstants.yearUnknown,
        author: String? = nil
    ) {
        self.query = query
        self.tags = tags
        self.tagsExclude = tagsExclude
        self.locale = locale
        self.originalLocale = originalLocale
        self.states = states
        self.contentRating = contentRating
        self.types = types
        self.demographics = demographics
        self.year = year
        self.yearFrom = yearFrom
        self.yearTo = yearTo
        self.author = author
    }

    public static let empty = MangaListFilter()

    /// True when no constraint other than a free-text query is set.
    public var isEmpty: Bool {
        tags.isEmpty && tagsExclude.isEmpty && states.isEmpty && contentRating.isEmpty &&
        types.isEmpty && demographics.isEmpty && year == NyoraConstants.yearUnknown &&
        yearFrom == NyoraConstants.yearUnknown && yearTo == NyoraConstants.yearUnknown &&
        author == nil && locale == nil && originalLocale == nil
    }
}

/// What a source can filter/search by.
/// Mirrors `org.koitharu.nyora.parsers.model.MangaListFilterCapabilities`.
public struct MangaListFilterCapabilities: Hashable, Sendable {
    public let isMultipleTagsSupported: Bool
    public let isTagsExclusionSupported: Bool
    public let isSearchSupported: Bool
    public let isSearchWithFiltersSupported: Bool
    public let isYearSupported: Bool
    public let isYearRangeSupported: Bool
    public let isOriginalLocaleSupported: Bool
    public let isAuthorSearchSupported: Bool

    public init(
        isMultipleTagsSupported: Bool = false,
        isTagsExclusionSupported: Bool = false,
        isSearchSupported: Bool = false,
        isSearchWithFiltersSupported: Bool = false,
        isYearSupported: Bool = false,
        isYearRangeSupported: Bool = false,
        isOriginalLocaleSupported: Bool = false,
        isAuthorSearchSupported: Bool = false
    ) {
        self.isMultipleTagsSupported = isMultipleTagsSupported
        self.isTagsExclusionSupported = isTagsExclusionSupported
        self.isSearchSupported = isSearchSupported
        self.isSearchWithFiltersSupported = isSearchWithFiltersSupported
        self.isYearSupported = isYearSupported
        self.isYearRangeSupported = isYearRangeSupported
        self.isOriginalLocaleSupported = isOriginalLocaleSupported
        self.isAuthorSearchSupported = isAuthorSearchSupported
    }
}

/// The concrete filter values a source offers (populated by `getFilterOptions`).
/// Mirrors `org.koitharu.nyora.parsers.model.MangaListFilterOptions`.
public struct MangaListFilterOptions: Hashable, Sendable {
    public let availableTags: Set<MangaTag>
    public let availableStates: Set<MangaState>
    public let availableContentRating: Set<ContentRating>
    public let availableContentTypes: Set<ContentType>
    public let availableDemographics: Set<Demographic>
    public let availableLocales: Set<String>

    public init(
        availableTags: Set<MangaTag> = [],
        availableStates: Set<MangaState> = [],
        availableContentRating: Set<ContentRating> = [],
        availableContentTypes: Set<ContentType> = [],
        availableDemographics: Set<Demographic> = [],
        availableLocales: Set<String> = []
    ) {
        self.availableTags = availableTags
        self.availableStates = availableStates
        self.availableContentRating = availableContentRating
        self.availableContentTypes = availableContentTypes
        self.availableDemographics = availableDemographics
        self.availableLocales = availableLocales
    }

    public static let empty = MangaListFilterOptions()
}

/// Source favicon set. Mirrors `org.koitharu.nyora.parsers.model.Favicons`.
public struct Favicons: Hashable, Sendable {
    public struct Favicon: Hashable, Sendable {
        public let url: String
        public let size: Int
        public let rel: String?
        public init(url: String, size: Int, rel: String?) {
            self.url = url; self.size = size; self.rel = rel
        }
    }
    public let favicons: [Favicon]
    public let referer: String
    public init(favicons: [Favicon] = [], referer: String = "") {
        self.favicons = favicons; self.referer = referer
    }
}
