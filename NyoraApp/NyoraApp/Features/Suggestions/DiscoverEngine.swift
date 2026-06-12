import Foundation
import SwiftUI
import NyoraEngine

/// Orchestrates the discovery surface, mirroring nyora-android's multi-rail discovery.
/// Combines AniList network rails with local rails (Continue Reading, Suggestions, Popular on Source).
@MainActor
final class DiscoverEngine: ObservableObject {
    static let shared = DiscoverEngine()

    @Published private(set) var rails: [DiscoverRail] = []
    @Published private(set) var hero: AniListDiscoverMedia?
    @Published private(set) var loading = false
    @Published private(set) var errorText: String?
    
    private let client = AniListDiscoverClient.shared
    private let suggestions = SuggestionsStore.shared
    
    private var cachedAniList: AniListMultiRailsResponse?

    private init() {}

    func refresh(using model: AppModel, force: Bool = false) async {
        guard !loading else { return }
        loading = true
        errorText = nil
        
        do {
            // 1. Fetch AniList rails (cached for session)
            if cachedAniList == nil || force {
                cachedAniList = try await client.getMultiRails()
            }
            
            // 2. Build the combined rail list
            var built: [DiscoverRail] = []
            
            // Hero from first trending
            if let firstTrending = cachedAniList?.trending.media.first {
                hero = firstTrending
            }

            // Local: Continue Reading
            if let recent = model.history.first {
                built.append(DiscoverRail(
                    id: "continue",
                    kind: .continueReading,
                    title: "Continue Reading",
                    items: [.manga(recent.manga)]
                ))
            }

            // Pinned Source: Popular on Source
            if let popularOnSource = await fetchPopularOnSource(using: model) {
                built.append(popularOnSource)
            }

            // AniList Rails
            if let ani = cachedAniList {
                built.append(DiscoverRail(id: "trending", kind: .trending, title: "Trending Now", items: ani.trending.media.map { .anilist($0) }))
                built.append(DiscoverRail(id: "popular", kind: .popular, title: "All-Time Popular", items: ani.popular.media.map { .anilist($0) }))
                built.append(DiscoverRail(id: "topRated", kind: .topRated, title: "Top Rated", items: ani.topRated.media.map { .anilist($0) }))
                built.append(DiscoverRail(id: "seasonal", kind: .seasonal, title: "Ongoing Now", items: ani.seasonal.media.map { .anilist($0) }))
                built.append(DiscoverRail(id: "newReleases", kind: .newReleases, title: "New Releases", items: ani.newReleases.media.map { .anilist($0) }))
                built.append(DiscoverRail(id: "action", kind: .action, title: "Action", items: ani.action.media.map { .anilist($0) }))
                built.append(DiscoverRail(id: "romance", kind: .romance, title: "Romance", items: ani.romance.media.map { .anilist($0) }))
            }

            // Local: Suggestions (based on favourites)
            // Note: For now, I am using the cached suggestions rails directly.
            // In a more complete pass, we would trigger SuggestionsEngine.refresh() here.
            for sugRail in suggestions.snapshot.rails {
                built.append(DiscoverRail(
                    id: sugRail.id,
                    kind: .suggestions,
                    title: sugRail.kind == .becauseYouRead ? "Because you read \(sugRail.seed)" : "Popular in \(sugRail.seed)",
                    items: sugRail.items.map { .manga($0) }
                ))
            }

            self.rails = built
        } catch {
            self.errorText = "Couldn’t load discovery feed. \(error.localizedDescription)"
        }
        
        loading = false
    }

    private func fetchPopularOnSource(using model: AppModel) async -> DiscoverRail? {
        let prefs = SourcePrefs.shared
        let enabledSources = model.sources.filter { prefs.isEnabled($0.name) }
        
        // Try up to 3 sources (prioritize pinned)
        let candidates = enabledSources.sorted { prefs.isPinned($0.name) && !prefs.isPinned($1.name) }
        
        for src in candidates.prefix(3) {
            if let results = try? await model.browse(sourceName: src.name, page: 1, order: .popularity, query: nil),
               !results.isEmpty {
                return DiscoverRail(
                    id: "source-popular-\(src.name)",
                    kind: .sourcePopular,
                    title: "Popular on \(src.title)",
                    items: results.prefix(20).map { .manga(MangaRef($0)) }
                )
            }
        }
        return nil
    }
}
