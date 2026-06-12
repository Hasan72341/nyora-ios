import Foundation

/// Developer credentials for each tracking service.
///
/// The defaults below are the public client IDs shipped by the upstream open-source
/// Nyora/Nyora Android app (`app/src/main/res/values/constants.xml`). They work out of
/// the box, but you SHOULD replace them with your own from each service's developer console
/// if you publish your own build:
///   - MyAnimeList:  https://myanimelist.net/apidev   (App type: "Other", PKCE plain)
///   - Shikimori:    https://shikimori.one/oauth/applications  (redirect nyora://shikimori-auth)
///   - Kitsu:        password grant — no per-app client registration required by users.
///   - AniList:      https://anilist.co/settings/developer  (implicit grant)
enum TrackerCredentials {
    // AniList numeric client id (implicit-grant flow).
    static let aniListClientID = "33558"

    // MARK: - MyAnimeList (OAuth2, PKCE "plain")
    static let MAL_CLIENT_ID = "66e27ac5d5a1764e944677b42e2c4737"

    // MARK: - Kitsu (OAuth2 password grant; the client id/secret are public app creds)
    static let KITSU_CLIENT_ID = "dd031b32d2f56c990b1425efe6c42ad847e7fe3ab46bf1299f05ecd856bdb7dd"
    static let KITSU_CLIENT_SECRET = "54d7307928f63414defd96399fc31ba847961ceaecef3a5fd93144e960c0e151"

    // MARK: - Shikimori (OAuth2 authorization code)
    static let SHIKIMORI_CLIENT_ID = "Mw6F0tPEOgyV7F9U9Twg50Q8SndMY7hzIOfXg0AX_XU"
    static let SHIKIMORI_CLIENT_SECRET = "" // <-- Fill in your Shikimori client secret here.
}

/// A search result from any tracker, normalised for the UI.
struct TrackerMedia: Identifiable, Hashable {
    /// The service-specific media id (AniList Int, MAL/Kitsu/Shikimori numeric).
    let remoteId: String
    let title: String
    let coverUrl: String?
    var id: String { remoteId }
}

/// Reading status, normalised across services.
enum TrackerStatus: String, CaseIterable, Identifiable, Codable {
    case reading, planning, completed, dropped, paused, rereading
    var id: String { rawValue }
    var label: String {
        switch self {
        case .reading: return "Reading"
        case .planning: return "Planning"
        case .completed: return "Completed"
        case .dropped: return "Dropped"
        case .paused: return "Paused"
        case .rereading: return "Rereading"
        }
    }
}

/// Common surface every tracker client implements. Auth state lives in `TrackingService`,
/// which passes tokens in per call so clients stay stateless.
protocol TrackerClient {
    var service: TrackerService { get }

    /// Build the authorization URL the user is sent to. Returns the URL plus any
    /// per-attempt secret (e.g. PKCE verifier) that the token exchange will need.
    func makeAuthorization() -> (url: URL, attemptState: String?)

    /// Exchange the OAuth callback for tokens. Returns access/refresh tokens.
    /// `attemptState` is whatever `makeAuthorization` produced (PKCE verifier, etc.).
    func exchange(callback: URL, attemptState: String?) async throws -> TrackerTokens

    /// Refresh an expired access token. Throw `.notAuthenticated` if unsupported.
    func refresh(refreshToken: String) async throws -> TrackerTokens

    /// Validate the access token and return the account display name.
    func fetchUserName(accessToken: String) async throws -> String

    /// Search the service for manga by title.
    func search(title: String, accessToken: String) async throws -> [TrackerMedia]

    /// Push read progress. `rateId` is a service-side list-entry id when known (used by
    /// MAL/Kitsu). Returns an updated `rateId` to persist (may equal the input).
    @discardableResult
    func pushProgress(media: TrackerMedia, rateId: String?, chapter: Int, status: TrackerStatus, accessToken: String) async throws -> String?
}

extension TrackerClient {
    func refresh(refreshToken: String) async throws -> TrackerTokens {
        throw TrackerOAuthError.notAuthenticated
    }
}

/// Tokens returned by an auth flow.
struct TrackerTokens: Codable {
    var accessToken: String
    var refreshToken: String?
}

/// Shared HTTP helpers for the JSON-based REST trackers.
enum TrackerHTTP {
    static let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: cfg)
    }()

    static func formBody(_ params: [String: String]) -> Data {
        params.map { key, value in
            let k = key.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? key
            let v = value.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? value
            return "\(k)=\(v)"
        }.joined(separator: "&").data(using: .utf8) ?? Data()
    }

    /// Perform a request and decode the JSON body as a dictionary, surfacing HTTP errors.
    static func json(_ req: URLRequest) async throws -> [String: Any] {
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw TrackerOAuthError.decoding }
        let obj = try? JSONSerialization.jsonObject(with: data)
        guard (200...299).contains(http.statusCode) else {
            if let dict = obj as? [String: Any] {
                let msg = (dict["error_description"] as? String)
                    ?? (dict["error"] as? String)
                    ?? (dict["message"] as? String)
                if let msg { throw TrackerOAuthError.server(msg) }
            }
            throw TrackerOAuthError.http(http.statusCode)
        }
        guard let dict = obj as? [String: Any] else { throw TrackerOAuthError.decoding }
        return dict
    }
}

extension CharacterSet {
    /// Strict query-value set (RFC 3986) so `+`, `&`, `=` are percent-encoded in form bodies.
    static let urlQueryValueAllowed: CharacterSet = {
        var cs = CharacterSet.alphanumerics
        cs.insert(charactersIn: "-._~")
        return cs
    }()
}
