import Foundation
import SwiftUI
import NyoraEngine

/// A manga linked to one tracker service, plus the last progress we pushed.
struct TrackedManga: Codable, Identifiable, Hashable {
    let manga: MangaRef
    /// Which service this link belongs to. Defaults to AniList for pre-existing data.
    var service: TrackerService
    /// Service-side media id (AniList Int, MAL/Kitsu/Shikimori id) as a string.
    var remoteId: String
    /// Display title from the service.
    var remoteTitle: String
    /// Service list-entry id ("rate"), when the service hands one back (MAL/Kitsu/Shikimori).
    var rateId: String?
    var lastSyncedProgress: Int

    /// Composite identity: a manga may be linked to several services at once.
    var id: String { "\(service.rawValue):\(manga.id)" }

    // Custom decoding to migrate the old AniList-only schema (mediaId: Int, aniListTitle).
    enum CodingKeys: String, CodingKey {
        case manga, service, remoteId, remoteTitle, rateId, lastSyncedProgress
        case mediaId, aniListTitle // legacy
    }

    init(manga: MangaRef, service: TrackerService, remoteId: String, remoteTitle: String, rateId: String?, lastSyncedProgress: Int) {
        self.manga = manga
        self.service = service
        self.remoteId = remoteId
        self.remoteTitle = remoteTitle
        self.rateId = rateId
        self.lastSyncedProgress = lastSyncedProgress
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        manga = try c.decode(MangaRef.self, forKey: .manga)
        lastSyncedProgress = try c.decodeIfPresent(Int.self, forKey: .lastSyncedProgress) ?? 0
        service = try c.decodeIfPresent(TrackerService.self, forKey: .service) ?? .aniList
        rateId = try c.decodeIfPresent(String.self, forKey: .rateId)
        if let rid = try c.decodeIfPresent(String.self, forKey: .remoteId) {
            remoteId = rid
            remoteTitle = try c.decodeIfPresent(String.self, forKey: .remoteTitle) ?? ""
        } else {
            // Legacy AniList-only record.
            let legacyId = try c.decodeIfPresent(Int.self, forKey: .mediaId) ?? 0
            remoteId = String(legacyId)
            remoteTitle = try c.decodeIfPresent(String.self, forKey: .aniListTitle) ?? ""
        }
    }

    // Explicit encode (the legacy CodingKeys cases block Encodable synthesis).
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(manga, forKey: .manga)
        try c.encode(service, forKey: .service)
        try c.encode(remoteId, forKey: .remoteId)
        try c.encode(remoteTitle, forKey: .remoteTitle)
        try c.encodeIfPresent(rateId, forKey: .rateId)
        try c.encode(lastSyncedProgress, forKey: .lastSyncedProgress)
    }
}

/// Per-service auth state.
struct TrackerAccount: Codable, Hashable {
    var accessToken: String
    var refreshToken: String?
    var userName: String?
}

/// @MainActor singleton owning tracking state for all services (AniList, MyAnimeList,
/// Kitsu, Shikimori). Persists tokens + links to `tracking.json` in Application Support/Nyora
/// (mirroring LibraryStore/DownloadManager). Never touches library.json.
@MainActor
final class TrackingService: ObservableObject {
    static let shared = TrackingService()

    /// service → account (present only when signed in).
    @Published private(set) var accounts: [TrackerService: TrackerAccount] = [:]
    /// "service:mangaId" → link.
    @Published private(set) var links: [String: TrackedManga] = [:]

    // MARK: Clients

    private let clients: [TrackerService: TrackerClient] = [
        .aniList: AniListTrackerClient(),
        .myAnimeList: MALClient(),
        .kitsu: KitsuClient(),
        .shikimori: ShikimoriClient(),
    ]

    func client(for service: TrackerService) -> TrackerClient { clients[service]! }

    // MARK: Back-compat (AniList-centric API used by existing call sites)

    /// True when ANY service is signed in (used by LinkSheet's gate).
    var isLoggedIn: Bool { !accounts.isEmpty }
    /// AniList viewer name kept for the old TrackingView account row.
    var viewerName: String? { accounts[.aniList]?.userName }
    var token: String? { accounts[.aniList]?.accessToken }

    func isSignedIn(_ service: TrackerService) -> Bool { accounts[service] != nil }
    func userName(_ service: TrackerService) -> String? { accounts[service]?.userName }

    private let queue = DispatchQueue(label: "nyora.trackingstore")

    // MARK: Paths (mirror DownloadManager)

    private static let baseDir: URL = {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Nyora", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private let stateURL = TrackingService.baseDir.appendingPathComponent("tracking.json")

    // MARK: Persistence

    private struct Snapshot: Codable {
        var accounts: [TrackerService: TrackerAccount] = [:]
        var links: [TrackedManga] = []
        // legacy fields
        var token: String?
        var viewerName: String?

        init() {}
        init(accounts: [TrackerService: TrackerAccount], links: [TrackedManga]) {
            self.accounts = accounts
            self.links = links
        }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            links = try c.decodeIfPresent([TrackedManga].self, forKey: .links) ?? []
            if let accs = try c.decodeIfPresent([TrackerService: TrackerAccount].self, forKey: .accounts) {
                accounts = accs
            } else {
                // Migrate the old single-token AniList schema.
                let token = try c.decodeIfPresent(String.self, forKey: .token)
                let name = try c.decodeIfPresent(String.self, forKey: .viewerName)
                if let token, !token.isEmpty {
                    accounts[.aniList] = TrackerAccount(accessToken: token, refreshToken: nil, userName: name)
                }
            }
        }
    }

    private init() {
        if let data = try? Data(contentsOf: stateURL),
           let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            accounts = decoded.accounts
            links = Dictionary(uniqueKeysWithValues: decoded.links.map { ($0.id, $0) })
        }
    }

    private func persist() {
        let snap = Snapshot(accounts: accounts, links: Array(links.values))
        queue.async { [stateURL] in
            if let data = try? JSONEncoder().encode(snap) {
                try? data.write(to: stateURL, options: .atomic)
            }
        }
    }

    // MARK: OAuth sign-in

    /// Run the browser-based OAuth flow for a service, then validate and store the account.
    /// Used for AniList / MyAnimeList / Shikimori. Throws on cancel/error.
    func signInViaOAuth(_ service: TrackerService) async throws {
        let client = self.client(for: service)
        let (url, attemptState) = client.makeAuthorization()
        let callback = try await TrackerOAuth.shared.authorize(url: url)
        let tokens = try await client.exchange(callback: callback, attemptState: attemptState)
        try await finishSignIn(service, tokens: tokens)
    }

    /// Kitsu password-grant sign-in (no browser).
    func signInKitsu(username: String, password: String) async throws {
        guard let kitsu = client(for: .kitsu) as? KitsuClient else { return }
        let tokens = try await kitsu.signInWithPassword(username: username, password: password)
        try await finishSignIn(.kitsu, tokens: tokens)
    }

    /// Legacy AniList token-paste path (kept so the old TrackingView keeps working).
    func signIn(token rawToken: String) async throws {
        let trimmed = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TrackerOAuthError.notAuthenticated }
        try await finishSignIn(.aniList, tokens: TrackerTokens(accessToken: trimmed, refreshToken: nil))
    }

    private func finishSignIn(_ service: TrackerService, tokens: TrackerTokens) async throws {
        let name = try await client(for: service).fetchUserName(accessToken: tokens.accessToken)
        accounts[service] = TrackerAccount(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken, userName: name)
        persist()
    }

    func signOut(_ service: TrackerService) {
        accounts[service] = nil
        persist()
    }

    /// Back-compat: AniList sign-out.
    func signOut() { signOut(.aniList) }

    // MARK: Search

    func search(_ service: TrackerService, title: String) async throws -> [TrackerMedia] {
        guard let acc = accounts[service] else {
            // AniList search works without auth; others need a token.
            if service == .aniList {
                return try await client(for: .aniList).search(title: title, accessToken: "")
            }
            throw TrackerOAuthError.notAuthenticated
        }
        return try await withRefresh(service, account: acc) { token in
            try await self.client(for: service).search(title: title, accessToken: token)
        }
    }

    // MARK: Linking

    func linkKey(_ service: TrackerService, _ mangaId: Int64) -> String { "\(service.rawValue):\(mangaId)" }

    /// True if linked to ANY service (used by MangaDetailView's badge).
    func isLinked(_ mangaId: Int64) -> Bool {
        links.values.contains { $0.manga.id == mangaId }
    }

    func isLinked(_ service: TrackerService, _ mangaId: Int64) -> Bool {
        links[linkKey(service, mangaId)] != nil
    }

    func link(_ ref: MangaRef, service: TrackerService, media: TrackerMedia) {
        let key = linkKey(service, ref.id)
        links[key] = TrackedManga(
            manga: ref,
            service: service,
            remoteId: media.remoteId,
            remoteTitle: media.title,
            rateId: nil,
            lastSyncedProgress: 0
        )
        persist()
    }

    func unlink(_ service: TrackerService, _ mangaId: Int64) {
        links[linkKey(service, mangaId)] = nil
        persist()
    }

    /// Back-compat: unlink from all services for a manga (old single-id API).
    func unlink(_ mangaId: Int64) {
        for key in links.keys where links[key]?.manga.id == mangaId { links[key] = nil }
        persist()
    }

    /// All links for one manga (across services).
    func links(for mangaId: Int64) -> [TrackedManga] {
        links.values.filter { $0.manga.id == mangaId }
    }

    /// Sorted list of every linked manga for the UI.
    var trackedList: [TrackedManga] {
        links.values.sorted {
            let t = $0.manga.title.localizedCaseInsensitiveCompare($1.manga.title)
            if t == .orderedSame { return $0.service.rawValue < $1.service.rawValue }
            return t == .orderedAscending
        }
    }

    // MARK: Sync

    /// Push a chapter number as read progress to every service the manga is linked to.
    /// No-op per-link if not signed in or the number isn't ahead of what we last synced.
    func syncProgress(mangaId: Int64, chapterNumber: Int, status: TrackerStatus = .reading) async {
        for tracked in links(for: mangaId) {
            await syncOne(tracked, chapterNumber: chapterNumber, status: status)
        }
    }

    private func syncOne(_ tracked: TrackedManga, chapterNumber: Int, status: TrackerStatus) async {
        guard let acc = accounts[tracked.service] else { return }
        guard chapterNumber > tracked.lastSyncedProgress else { return }
        let media = TrackerMedia(remoteId: tracked.remoteId, title: tracked.remoteTitle, coverUrl: nil)
        do {
            let newRate = try await withRefresh(tracked.service, account: acc) { token in
                try await self.client(for: tracked.service).pushProgress(
                    media: media, rateId: tracked.rateId, chapter: chapterNumber, status: status, accessToken: token
                )
            }
            var updated = tracked
            updated.lastSyncedProgress = chapterNumber
            if let newRate { updated.rateId = newRate }
            links[tracked.id] = updated
            persist()
        } catch {
            // Best-effort; never interrupt reading.
        }
    }

    /// Run a token-using closure, transparently refreshing the access token once on auth failure.
    private func withRefresh<T>(_ service: TrackerService, account: TrackerAccount, _ body: (String) async throws -> T) async throws -> T {
        do {
            return try await body(account.accessToken)
        } catch let TrackerOAuthError.http(code) where code == 401 {
            guard let refresh = account.refreshToken else { throw TrackerOAuthError.notAuthenticated }
            let tokens = try await client(for: service).refresh(refreshToken: refresh)
            var updated = account
            updated.accessToken = tokens.accessToken
            if let r = tokens.refreshToken { updated.refreshToken = r }
            accounts[service] = updated
            persist()
            return try await body(updated.accessToken)
        }
    }

    // MARK: OAuth callback routing

    /// Whether a `nyora://` URL is one of our OAuth callbacks.
    static func isOAuthCallback(_ url: URL) -> Bool {
        guard url.scheme == kNyoraOAuthScheme else { return false }
        return TrackerService.allCases.contains { $0.callbackHost == url.host }
    }
}
