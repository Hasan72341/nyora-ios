import Foundation

/// Kitsu tracker client. Uses the OAuth2 *password* grant (Kitsu's documented flow) — the
/// user enters their Kitsu email + password directly, so there is no browser redirect.
/// Mirrors the Android `KitsuRepository`. All resource requests use the JSON:API media type.
struct KitsuClient: TrackerClient {
    let service: TrackerService = .kitsu

    private let base = "https://kitsu.app"
    private let vndJSON = "application/vnd.api+json"

    /// Kitsu has no browser auth — `makeAuthorization` is unused; the UI calls
    /// `signInWithPassword` instead. We return a dummy URL so the protocol is satisfied.
    func makeAuthorization() -> (url: URL, attemptState: String?) {
        (URL(string: "\(base)")!, nil)
    }

    func exchange(callback: URL, attemptState: String?) async throws -> TrackerTokens {
        throw TrackerOAuthError.notAuthenticated // Kitsu uses signInWithPassword.
    }

    /// Password grant: exchange Kitsu credentials for tokens.
    func signInWithPassword(username: String, password: String) async throws -> TrackerTokens {
        var req = URLRequest(url: URL(string: "\(base)/api/oauth/token")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = TrackerHTTP.formBody([
            "grant_type": "password",
            "username": username,
            "password": password,
            "client_id": TrackerCredentials.KITSU_CLIENT_ID,
            "client_secret": TrackerCredentials.KITSU_CLIENT_SECRET,
        ])
        let json = try await TrackerHTTP.json(req)
        guard let access = json["access_token"] as? String else { throw TrackerOAuthError.decoding }
        return TrackerTokens(accessToken: access, refreshToken: json["refresh_token"] as? String)
    }

    func refresh(refreshToken: String) async throws -> TrackerTokens {
        var req = URLRequest(url: URL(string: "\(base)/api/oauth/token")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = TrackerHTTP.formBody([
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": TrackerCredentials.KITSU_CLIENT_ID,
            "client_secret": TrackerCredentials.KITSU_CLIENT_SECRET,
        ])
        let json = try await TrackerHTTP.json(req)
        guard let access = json["access_token"] as? String else { throw TrackerOAuthError.decoding }
        return TrackerTokens(accessToken: access, refreshToken: json["refresh_token"] as? String ?? refreshToken)
    }

    private func req(_ url: URL, method: String = "GET", body: Data? = nil, token: String) -> URLRequest {
        var r = URLRequest(url: url)
        r.httpMethod = method
        r.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        r.setValue(vndJSON, forHTTPHeaderField: "Accept")
        if let body {
            r.setValue(vndJSON, forHTTPHeaderField: "Content-Type")
            r.httpBody = body
        }
        return r
    }

    func fetchUserName(accessToken: String) async throws -> String {
        let url = URL(string: "\(base)/api/edge/users?filter[self]=true")!
        let json = try await TrackerHTTP.json(req(url, token: accessToken))
        guard let data = json["data"] as? [[String: Any]], let first = data.first,
              let attrs = first["attributes"] as? [String: Any],
              let name = attrs["name"] as? String else { throw TrackerOAuthError.decoding }
        return name
    }

    func search(title: String, accessToken: String) async throws -> [TrackerMedia] {
        var comp = URLComponents(string: "\(base)/api/edge/manga")!
        comp.queryItems = [
            .init(name: "filter[text]", value: title),
            .init(name: "page[limit]", value: "20"),
        ]
        let json = try await TrackerHTTP.json(req(comp.url!, token: accessToken))
        guard let data = json["data"] as? [[String: Any]] else { return [] }
        return data.compactMap { item in
            guard let id = item["id"] as? String,
                  let attrs = item["attributes"] as? [String: Any] else { return nil }
            let titles = attrs["titles"] as? [String: Any]
            let canonical = (attrs["canonicalTitle"] as? String)
                ?? (titles?["en"] as? String)
                ?? (titles?.values.compactMap { $0 as? String }.first)
                ?? "Untitled"
            let cover = (attrs["posterImage"] as? [String: Any])?["small"] as? String
            return TrackerMedia(remoteId: id, title: canonical, coverUrl: cover)
        }
    }

    /// Look up the numeric Kitsu user id for the access token (needed to create library entries).
    private func userId(token: String) async throws -> String {
        let url = URL(string: "\(base)/api/edge/users?filter[self]=true")!
        let json = try await TrackerHTTP.json(req(url, token: token))
        guard let data = json["data"] as? [[String: Any]], let first = data.first,
              let id = first["id"] as? String else { throw TrackerOAuthError.decoding }
        return id
    }

    @discardableResult
    func pushProgress(media: TrackerMedia, rateId: String?, chapter: Int, status: TrackerStatus, accessToken: String) async throws -> String? {
        if let rateId {
            // PATCH an existing library entry.
            let payload: [String: Any] = [
                "data": [
                    "type": "libraryEntries",
                    "id": rateId,
                    "attributes": ["progress": chapter, "status": kitsuStatus(status)],
                ]
            ]
            let body = try JSONSerialization.data(withJSONObject: payload)
            let url = URL(string: "\(base)/api/edge/library-entries/\(rateId)")!
            _ = try await TrackerHTTP.json(req(url, method: "PATCH", body: body, token: accessToken))
            return rateId
        } else {
            // POST a new library entry.
            let uid = try await userId(token: accessToken)
            let payload: [String: Any] = [
                "data": [
                    "type": "libraryEntries",
                    "attributes": ["status": kitsuStatus(status), "progress": chapter],
                    "relationships": [
                        "manga": ["data": ["type": "manga", "id": media.remoteId]],
                        "user": ["data": ["type": "users", "id": uid]],
                    ],
                ]
            ]
            let body = try JSONSerialization.data(withJSONObject: payload)
            let url = URL(string: "\(base)/api/edge/library-entries")!
            let json = try await TrackerHTTP.json(req(url, method: "POST", body: body, token: accessToken))
            if let data = json["data"] as? [String: Any], let id = data["id"] as? String { return id }
            return nil
        }
    }

    private func kitsuStatus(_ s: TrackerStatus) -> String {
        switch s {
        case .reading, .rereading: return "current"
        case .planning: return "planned"
        case .completed: return "completed"
        case .dropped: return "dropped"
        case .paused: return "on_hold"
        }
    }
}
