import Foundation
import NyoraEngine

/// One discover rail: a heading plus the items to display in it.
struct DiscoverRail: Identifiable, Hashable {
    enum Kind: String, CaseIterable {
        case trending = "Trending Now"
        case popular = "All-Time Popular"
        case topRated = "Top Rated"
        case seasonal = "Ongoing Now"
        case newReleases = "New Releases"
        case action = "Action"
        case romance = "Romance"
        case sourcePopular = "Popular on Source"
        case suggestions = "Suggestions"
        case continueReading = "Continue Reading"
        
        var title: String { rawValue }
    }

    let id: String
    let kind: Kind
    let title: String
    let items: [DiscoverItem]
}

enum DiscoverItem: Identifiable, Hashable {
    case manga(MangaRef)
    case anilist(AniListDiscoverMedia)
    
    var id: String {
        switch self {
        case .manga(let ref): return "m-\(ref.id)"
        case .anilist(let media): return "a-\(media.id)"
        }
    }
    
    var title: String {
        switch self {
        case .manga(let ref): return ref.title
        case .anilist(let media): return media.title.preferred
        }
    }
    
    var coverUrl: String? {
        switch self {
        case .manga(let ref): return ref.coverUrl
        case .anilist(let media): return media.coverImage.preferred
        }
    }
}
