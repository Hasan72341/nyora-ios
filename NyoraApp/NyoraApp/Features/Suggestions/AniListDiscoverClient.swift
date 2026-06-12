import Foundation

actor AniListDiscoverClient {
    static let shared = AniListDiscoverClient()
    
    private let endpoint = URL(string: "https://graphql.anilist.co")!
    private let session: URLSession

    init() {
        let cfg = URLSessionConfiguration.default
        cfg.requestCachePolicy = .useProtocolCachePolicy
        self.session = URLSession(configuration: cfg)
    }

    func getMultiRails(limit: Int = 20) async throws -> AniListMultiRailsResponse {
        let (season, year) = currentSeasonAndYear()
        
        let query = """
        query ($limit: Int, $season: MediaSeason, $year: Int) {
          trending: Page(page: 1, perPage: $limit) {
            media(type: MANGA, sort: TRENDING_DESC) {
              id title { romaji english native } coverImage { extraLarge large color } genres averageScore description(asHtml: false)
            }
          }
          popular: Page(page: 1, perPage: $limit) {
            media(type: MANGA, sort: POPULARITY_DESC) {
              id title { romaji english native } coverImage { extraLarge large color } genres averageScore description(asHtml: false)
            }
          }
          topRated: Page(page: 1, perPage: $limit) {
            media(type: MANGA, sort: SCORE_DESC) {
              id title { romaji english native } coverImage { extraLarge large color } genres averageScore description(asHtml: false)
            }
          }
          seasonal: Page(page: 1, perPage: $limit) {
            media(type: MANGA, sort: POPULARITY_DESC, season: $season, seasonYear: $year) {
              id title { romaji english native } coverImage { extraLarge large color } genres averageScore description(asHtml: false)
            }
          }
          newReleases: Page(page: 1, perPage: $limit) {
            media(type: MANGA, sort: START_DATE_DESC) {
              id title { romaji english native } coverImage { extraLarge large color } genres averageScore description(asHtml: false)
            }
          }
          action: Page(page: 1, perPage: $limit) {
            media(type: MANGA, sort: POPULARITY_DESC, genre: "Action") {
              id title { romaji english native } coverImage { extraLarge large color } genres averageScore description(asHtml: false)
            }
          }
          romance: Page(page: 1, perPage: $limit) {
            media(type: MANGA, sort: POPULARITY_DESC, genre: "Romance") {
              id title { romaji english native } coverImage { extraLarge large color } genres averageScore description(asHtml: false)
            }
          }
        }
        """
        
        let variables: [String: Any] = [
            "limit": limit,
            "season": season,
            "year": year
        ]
        
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["query": query, "variables": variables]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AniListError.http((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        let decoded = try JSONDecoder().decode(AniListDiscoverResponse.self, from: data)
        return decoded.data
    }
    
    private func currentSeasonAndYear() -> (String, Int) {
        let date = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        
        let season: String
        switch month {
        case 12, 1, 2: season = "WINTER"
        case 3, 4, 5: season = "SPRING"
        case 6, 7, 8: season = "SUMMER"
        case 9, 10, 11: season = "FALL"
        default: season = "SUMMER"
        }
        
        return (season, year)
    }
}
