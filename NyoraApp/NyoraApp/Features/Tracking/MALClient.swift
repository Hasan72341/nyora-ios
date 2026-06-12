import Foundation

/// MyAnimeList tracker client. OAuth2 authorization-code flow with PKCE (`plain` method, as
/// MAL requires). Mirrors the Android `MALRepository`.
struct MALClient: TrackerClient {
    let service: TrackerService = .myAnimeList

    private let webBase = "https://myanimelist.net"
    private let apiBase = "https://api.myanimelist.net/v2"

    func makeAuthorization() -> (url: URL, attemptState: String?) {
        let pkce = PKCEPair.generate()
        var comp = URLComponents(string: "\(webBase)/v1/oauth2/authorize")!
        comp.queryItems = [
            .init(name: "response_type", value: "code"),
            .init(name: "client_id", value: TrackerCredentials.MAL_CLIENT_ID),
            .init(name: "redirect_uri", value: service.redirectURI),
            .init(name: "code_challenge", value: pkce.challengePlain),
            .init(name: "code_challenge_method", value: "plain"),
        ]
        // Carry the verifier as attemptState so exchange() can use it.
        return (comp.url!, pkce.verifier)
    }

    func exchange(callback: URL, attemptState: String?) async throws -> TrackerTokens {
        guard let code = callback.queryValue("code") else { throw TrackerOAuthError.missingCode }
        guard let verifier = attemptState else { throw TrackerOAuthError.missingCode }
        var req = URLRequest(url: URL(string: "\(webBase)/v1/oauth2/token")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = TrackerHTTP.formBody([
            "client_id": TrackerCredentials.MAL_CLIENT_ID,
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": service.redirectURI,
            "code_verifier": verifier,
        ])
        let json = try await TrackerHTTP.json(req)
        guard let access = json["access_token"] as? String else { throw TrackerOAuthError.decoding }
        return TrackerTokens(accessToken: access, refreshToken: json["refresh_token"] as? String)
    }

    func refresh(refreshToken: String) async throws -> TrackerTokens {
        var req = URLRequest(url: URL(string: "\(webBase)/v1/oauth2/token")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = TrackerHTTP.formBody([
            "client_id": TrackerCredentials.MAL_CLIENT_ID,
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
        ])
        let json = try await TrackerHTTP.json(req)
        guard let access = json["access_token"] as? String else { throw TrackerOAuthError.decoding }
        return TrackerTokens(accessToken: access, refreshToken: json["refresh_token"] as? String ?? refreshToken)
    }

    private func authed(_ url: URL, method: String = "GET", body: Data? = nil, token: String) -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if body != nil {
            req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            req.httpBody = body
        }
        return req
    }

    func fetchUserName(accessToken: String) async throws -> String {
        let req = authed(URL(string: "\(apiBase)/users/@me")!, token: accessToken)
        let json = try await TrackerHTTP.json(req)
        guard let name = json["name"] as? String else { throw TrackerOAuthError.decoding }
        return name
    }

    func search(title: String, accessToken: String) async throws -> [TrackerMedia] {
        var comp = URLComponents(string: "\(apiBase)/manga")!
        comp.queryItems = [
            .init(name: "q", value: String(title.prefix(64))), // MAL 400s past 64 chars
            .init(name: "nsfw", value: "true"),
            .init(name: "fields", value: "main_picture"),
        ]
        let req = authed(comp.url!, token: accessToken)
        let json = try await TrackerHTTP.json(req)
        guard let data = json["data"] as? [[String: Any]] else { return [] }
        return data.compactMap { item in
            guard let node = item["node"] as? [String: Any],
                  let id = node["id"] as? Int,
                  let name = node["title"] as? String else { return nil }
            let cover = (node["main_picture"] as? [String: Any])?["large"] as? String
            return TrackerMedia(remoteId: String(id), title: name, coverUrl: cover)
        }
    }

    @discardableResult
    func pushProgress(media: TrackerMedia, rateId: String?, chapter: Int, status: TrackerStatus, accessToken: String) async throws -> String? {
        let url = URL(string: "\(apiBase)/manga/\(media.remoteId)/my_list_status")!
        let body = TrackerHTTP.formBody([
            "status": malStatus(status),
            "num_chapters_read": String(chapter),
        ])
        let req = authed(url, method: "PUT", body: body, token: accessToken)
        _ = try await TrackerHTTP.json(req)
        return media.remoteId
    }

    private func malStatus(_ s: TrackerStatus) -> String {
        switch s {
        case .reading, .rereading: return "reading"
        case .planning: return "plan_to_read"
        case .completed: return "completed"
        case .dropped: return "dropped"
        case .paused: return "on_hold"
        }
    }
}
