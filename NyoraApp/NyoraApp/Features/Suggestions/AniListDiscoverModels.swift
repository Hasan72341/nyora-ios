import Foundation

struct AniListDiscoverResponse: Codable {
    let data: AniListMultiRailsResponse
}

struct AniListMultiRailsResponse: Codable {
    let trending: AniListPage
    let popular: AniListPage
    let topRated: AniListPage
    let seasonal: AniListPage
    let newReleases: AniListPage
    let action: AniListPage
    let romance: AniListPage
}

struct AniListPage: Codable {
    let media: [AniListDiscoverMedia]
}

struct AniListDiscoverMedia: Codable, Identifiable, Hashable {
    let id: Int
    let title: AniListDiscoverTitle
    let coverImage: AniListDiscoverCoverImage
    let description: String?
    let averageScore: Int?
    let genres: [String]?

    struct AniListDiscoverTitle: Codable, Hashable {
        let romaji: String?
        let english: String?
        let native: String?
        
        var preferred: String {
            english ?? romaji ?? native ?? "Unknown"
        }
    }

    struct AniListDiscoverCoverImage: Codable, Hashable {
        let extraLarge: String?
        let large: String?
        let color: String?
        
        var preferred: String {
            extraLarge ?? large ?? ""
        }
    }
}
