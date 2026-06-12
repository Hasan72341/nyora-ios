import Foundation

/// `TrackerClient` adapter over the existing `AniListClient` GraphQL transport, adding the
/// implicit-grant OAuth flow (AniList returns an `access_token` in the redirect fragment;
/// there is no token exchange and tokens do not expire).
struct AniListTrackerClient: TrackerClient {
    let service: TrackerService = .aniList
    private let api = AniListClient.shared

    func makeAuthorization() -> (url: URL, attemptState: String?) {
        var comp = URLComponents(string: "https://anilist.co/api/v2/oauth/authorize")!
        comp.queryItems = [
            .init(name: "client_id", value: TrackerCredentials.aniListClientID),
            .init(name: "response_type", value: "token"),
            // AniList implicit grant ignores redirect_uri host beyond exact-match config,
            // but we register nyora://anilist-auth in the AniList client settings.
            .init(name: "redirect_uri", value: TrackerService.aniList.redirectURI),
        ]
        return (comp.url!, nil)
    }

    func exchange(callback: URL, attemptState: String?) async throws -> TrackerTokens {
        // Implicit grant: token is in the URL fragment.
        guard let token = callback.fragmentValue("access_token") else {
            throw TrackerOAuthError.missingCode
        }
        return TrackerTokens(accessToken: token, refreshToken: nil)
    }

    func fetchUserName(accessToken: String) async throws -> String {
        try await api.getViewer(token: accessToken)
    }

    func search(title: String, accessToken: String) async throws -> [TrackerMedia] {
        let results = try await api.searchManga(title: title)
        return results.map { TrackerMedia(remoteId: String($0.id), title: $0.title, coverUrl: $0.coverUrl) }
    }

    @discardableResult
    func pushProgress(media: TrackerMedia, rateId: String?, chapter: Int, status: TrackerStatus, accessToken: String) async throws -> String? {
        let aniStatus: AniListStatus
        switch status {
        case .reading: aniStatus = .current
        case .planning: aniStatus = .planning
        case .completed: aniStatus = .completed
        case .dropped: aniStatus = .dropped
        case .paused: aniStatus = .paused
        case .rereading: aniStatus = .repeating
        }
        guard let mediaId = Int(media.remoteId) else { throw TrackerOAuthError.decoding }
        _ = try await api.saveProgress(mediaId: mediaId, progress: chapter, status: aniStatus, token: accessToken)
        return rateId
    }
}
