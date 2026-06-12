import Foundation

/// Publication status of a manga. Mirrors `org.koitharu.nyora.parsers.model.MangaState`.
public enum MangaState: String, Codable, Sendable, CaseIterable {
    case ongoing = "ONGOING"
    case finished = "FINISHED"
    case abandoned = "ABANDONED"
    case paused = "PAUSED"
    case upcoming = "UPCOMING"
    case restricted = "RESTRICTED"
}

/// Mirrors `org.koitharu.nyora.parsers.model.ContentRating`.
public enum ContentRating: String, Codable, Sendable, CaseIterable {
    case safe = "SAFE"
    case suggestive = "SUGGESTIVE"
    case adult = "ADULT"
}

/// Mirrors `org.koitharu.nyora.parsers.model.ContentType`.
public enum ContentType: String, Codable, Sendable, CaseIterable {
    case manga = "MANGA"
    case manhwa = "MANHWA"
    case manhua = "MANHUA"
    case comics = "COMICS"
    case novel = "NOVEL"
    case oneShot = "ONE_SHOT"
    case doujinshi = "DOUJINSHI"
    case image = "IMAGE"
    case hentai = "HENTAI"
    case other = "OTHER"
}

/// Mirrors `org.koitharu.nyora.parsers.model.Demographic`.
public enum Demographic: String, Codable, Sendable, CaseIterable {
    case shounen = "SHOUNEN"
    case shoujo = "SHOUJO"
    case seinen = "SEINEN"
    case josei = "JOSEI"
    case kodomo = "KODOMO"
    case none = "NONE"
}

/// Mirrors `org.koitharu.nyora.parsers.model.SortOrder`.
/// Declaration order matters: parsers expose `availableSortOrders` and the first
/// supported one is used as the default when none is requested.
public enum SortOrder: String, Codable, Sendable, CaseIterable {
    case updated = "UPDATED"
    case updatedAsc = "UPDATED_ASC"
    case popularity = "POPULARITY"
    case popularityAsc = "POPULARITY_ASC"
    case newest = "NEWEST"
    case newestAsc = "NEWEST_ASC"
    case rating = "RATING"
    case ratingAsc = "RATING_ASC"
    case alphabetical = "ALPHABETICAL"
    case alphabeticalDesc = "ALPHABETICAL_DESC"
    case relevance = "RELEVANCE"
    case addedToLib = "ADDED_TO_LIBRARY"
    case addedToLibAsc = "ADDED_TO_LIBRARY_ASC"
}

public enum NyoraConstants {
    /// `Manga.rating == RATING_UNKNOWN` means the source did not report a rating.
    public static let ratingUnknown: Float = -1.0
    /// `MangaListFilter.year == YEAR_UNKNOWN` means no year filter is applied.
    public static let yearUnknown: Int = 0
}
