import Foundation

/// Shikimori tracker client. OAuth2 authorization-code flow with a client secret.
/// Mirrors the Android `ShikimoriRepository`. Shikimori requires a `User-Agent` identifying
/// the app on every request, or it returns 429/403.
struct ShikimoriClient: TrackerClient {
    let service: TrackerService = .shikimori

    private let domain = "shikimori.one"
    private var base: String { "https://\(domain)" }
    /// Shikimori's API rules mandate a descriptive User-Agent.
    private let userAgent = "Nyora"

    func makeAuthorization() -> (url: URL, attemptState: String?) {
        var comp = URLComponents(string: "\(base)/oauth/authorize")!
        comp.queryItems = [
            .init(name: "client_id", value: TrackerCredentials.SHIKIMORI_CLIENT_ID),
            .init(name: "redirect_uri", value: service.redirectURI),
            .init(name: "response_type", value: "code"),
            .init(name: "scope", value: ""),
        ]
        return (comp.url!, nil)
    }

    func exchange(callback: URL, attemptState: String?) async throws -> TrackerTokens {
        guard let code = callback.queryValue("code") else { throw TrackerOAuthError.missingCode }
        return try await token(params: [
            "grant_type": "authorization_code",
            "client_id": TrackerCredentials.SHIKIMORI_CLIENT_ID,
            "client_secret": TrackerCredentials.SHIKIMORI_CLIENT_SECRET,
            "code": code,
            "redirect_uri": service.redirectURI,
        ])
    }

    func refresh(refreshToken: String) async throws -> TrackerTokens {
        try await token(params: [
            "grant_type": "refresh_token",
            "client_id": TrackerCredentials.SHIKIMORI_CLIENT_ID,
            "client_secret": TrackerCredentials.SHIKIMORI_CLIENT_SECRET,
            "refresh_token": refreshToken,
        ])
    }

    private func token(params: [String: String]) async throws -> TrackerTokens {
        var req = URLRequest(url: URL(string: "\(base)/oauth/token")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.httpBody = TrackerHTTP.formBody(params)
        let json = try await TrackerHTTP.json(req)
        guard let access = json["access_token"] as? String else { throw TrackerOAuthError.decoding }
        return TrackerTokens(accessToken: access, refreshToken: json["refresh_token"] as? String)
    }

    private func authed(_ url: URL, method: String = "GET", json body: [String: Any]? = nil, token: String) throws -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        return req
    }

    func fetchUserName(accessToken: String) async throws -> String {
        let req = try authed(URL(string: "\(base)/api/users/whoami")!, token: accessToken)
        let json = try await TrackerHTTP.json(req)
        guard let name = json["nickname"] as? String else { throw TrackerOAuthError.decoding }
        return name
    }

    func search(title: String, accessToken: String) async throws -> [TrackerMedia] {
        var comp = URLComponents(string: "\(base)/api/mangas")!
        comp.queryItems = [
            .init(name: "search", value: title),
            .init(name: "limit", value: "20"),
        ]
        let req = try authed(comp.url!, token: accessToken)
        let (data, response) = try await TrackerHTTP.session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw TrackerOAuthError.http((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        guard let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }
        return arr.compactMap { item in
            guard let id = item["id"] as? Int,
                  let name = (item["russian"] as? String).flatMap({ $0.isEmpty ? nil : $0 }) ?? item["name"] as? String
            else { return nil }
            let img = (item["image"] as? [String: Any])?["preview"] as? String
            let cover = img.map { $0.hasPrefix("http") ? $0 : "\(base)\($0)" }
            return TrackerMedia(remoteId: String(id), title: name, coverUrl: cover)
        }
    }

    @discardableResult
    func pushProgress(media: TrackerMedia, rateId: String?, chapter: Int, status: TrackerStatus, accessToken: String) async throws -> String? {
        let userId = try await whoamiId(token: accessToken)
        // If we have a rate id, PATCH it; otherwise POST a new user-rate.
        let payload: [String: Any] = [
            "user_rate": [
                "user_id": userId,
                "target_id": Int(media.remoteId) ?? 0,
                "target_type": "Manga",
                "status": shikiStatus(status),
                "chapters": chapter,
            ]
        ]
        if let rateId, let rid = Int(rateId) {
            let req = try authed(URL(string: "\(base)/api/v2/user_rates/\(rid)")!, method: "PATCH", json: payload, token: accessToken)
            _ = try await TrackerHTTP.json(req)
            return rateId
        } else {
            let req = try authed(URL(string: "\(base)/api/v2/user_rates")!, method: "POST", json: payload, token: accessToken)
            let json = try await TrackerHTTP.json(req)
            if let id = json["id"] as? Int { return String(id) }
            return rateId
        }
    }

    private func whoamiId(token: String) async throws -> Int {
        let req = try authed(URL(string: "\(base)/api/users/whoami")!, token: token)
        let json = try await TrackerHTTP.json(req)
        guard let id = json["id"] as? Int else { throw TrackerOAuthError.decoding }
        return id
    }

    private func shikiStatus(_ s: TrackerStatus) -> String {
        switch s {
        case .reading: return "watching"
        case .rereading: return "rewatching"
        case .planning: return "planned"
        case .completed: return "completed"
        case .dropped: return "dropped"
        case .paused: return "on_hold"
        }
    }
}
