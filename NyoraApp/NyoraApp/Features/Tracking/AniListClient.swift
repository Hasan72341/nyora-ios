import Foundation

/// Status values AniList accepts for a media-list entry. Mapped to AniList's
/// `MediaListStatus` enum (uppercased on the wire).
enum AniListStatus: String, Codable, CaseIterable, Identifiable {
    case current = "CURRENT"
    case planning = "PLANNING"
    case completed = "COMPLETED"
    case dropped = "DROPPED"
    case paused = "PAUSED"
    case repeating = "REPEATING"

    var id: String { rawValue }

    /// Human-readable label for pickers.
    var label: String {
        switch self {
        case .current: return "Reading"
        case .planning: return "Planning"
        case .completed: return "Completed"
        case .dropped: return "Dropped"
        case .paused: return "Paused"
        case .repeating: return "Rereading"
        }
    }
}

/// One AniList manga search result, flattened for the UI.
struct AniListMedia: Identifiable, Hashable {
    let id: Int
    let title: String
    let coverUrl: String?
}

/// Errors surfaced to the UI from AniList calls.
enum AniListError: LocalizedError {
    case notAuthenticated
    case http(Int)
    case decoding
    case graphQL(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "No AniList access token. Paste one in Tracking settings."
        case .http(let code): return "AniList request failed (HTTP \(code))."
        case .decoding: return "Couldn’t read AniList’s response."
        case .graphQL(let msg): return msg
        }
    }
}

/// Minimal AniList GraphQL client. Stateless w.r.t. auth — the caller passes the access
/// token per request so the actor never needs mutable shared state.
///
/// NOTE: Full OAuth (implicit/authorization-code redirect) is DEFERRED. The app uses a
/// pasted access token instead; see `TrackingView` for the instructions shown to users.
actor AniListClient {
    static let shared = AniListClient()

    private let endpoint = URL(string: "https://graphql.anilist.co")!
    private let session: URLSession

    init() {
        let cfg = URLSessionConfiguration.default
        cfg.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: cfg)
    }

    // MARK: GraphQL transport

    /// POST a GraphQL query and return the decoded `data` object as a dictionary.
    private func post(query: String, variables: [String: Any], token: String?) async throws -> [String: Any] {
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token, !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let body: [String: Any] = ["query": query, "variables": variables]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw AniListError.decoding }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AniListError.decoding
        }
        // GraphQL errors come back with a 200 sometimes; surface their message.
        if let errors = json["errors"] as? [[String: Any]],
           let first = errors.first, let msg = first["message"] as? String {
            throw AniListError.graphQL(msg)
        }
        guard (200...299).contains(http.statusCode) else { throw AniListError.http(http.statusCode) }
        guard let payload = json["data"] as? [String: Any] else { throw AniListError.decoding }
        return payload
    }

    // MARK: Queries

    /// Validate a token and return the viewer's display name.
    func getViewer(token: String) async throws -> String {
        let query = """
        query { Viewer { id name } }
        """
        let data = try await post(query: query, variables: [:], token: token)
        guard let viewer = data["Viewer"] as? [String: Any],
              let name = viewer["name"] as? String else {
            throw AniListError.decoding
        }
        return name
    }

    /// Search AniList for manga matching `title`.
    func searchManga(title: String) async throws -> [AniListMedia] {
        let query = """
        query ($q: String) {
          Page(perPage: 25) {
            media(search: $q, type: MANGA) {
              id
              title { romaji english }
              coverImage { large }
            }
          }
        }
        """
        let data = try await post(query: query, variables: ["q": title], token: nil)
        guard let page = data["Page"] as? [String: Any],
              let media = page["media"] as? [[String: Any]] else {
            return []
        }
        return media.compactMap { item in
            guard let id = item["id"] as? Int else { return nil }
            let titleObj = item["title"] as? [String: Any]
            let name = (titleObj?["english"] as? String)
                ?? (titleObj?["romaji"] as? String)
                ?? "Untitled"
            let cover = (item["coverImage"] as? [String: Any])?["large"] as? String
            return AniListMedia(id: id, title: name, coverUrl: cover)
        }
    }

    // MARK: Mutations

    /// Save (create or update) the viewer's list entry for a media id.
    @discardableResult
    func saveProgress(mediaId: Int, progress: Int, status: AniListStatus, token: String) async throws -> Int {
        let mutation = """
        mutation ($mediaId: Int, $progress: Int, $status: MediaListStatus) {
          SaveMediaListEntry(mediaId: $mediaId, progress: $progress, status: $status) {
            id
            progress
          }
        }
        """
        let vars: [String: Any] = [
            "mediaId": mediaId,
            "progress": progress,
            "status": status.rawValue
        ]
        let data = try await post(query: mutation, variables: vars, token: token)
        guard let entry = data["SaveMediaListEntry"] as? [String: Any],
              let saved = entry["progress"] as? Int else {
            throw AniListError.decoding
        }
        return saved
    }
}
