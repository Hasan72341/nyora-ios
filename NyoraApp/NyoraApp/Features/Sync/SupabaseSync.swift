import Foundation
import NyoraEngine

// MARK: - Config

enum SupabaseConfig {
    // Canonical project shared across all variants (mac/linux/windows/web/iOS).
    // Falls back to the hardcoded values so sign-in/sync works out of the box;
    // an env var or Info.plist entry can still override per build.
    static var url: String = {
        let v = ProcessInfo.processInfo.environment["SUPABASE_URL"]
            ?? Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? envSync["SUPABASE_URL"] ?? ""
        return v.isEmpty ? "https://fqguzcoytnbnjwaddakn.supabase.co" : v
    }()
    static var anonKey: String = {
        let v = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]
            ?? Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? envSync["SUPABASE_ANON_KEY"] ?? ""
        return v.isEmpty ? "sb_publishable_RZTcdZZlzb_UhYAxtB09AQ_URTEftE4" : v
    }()

    /// Parsed key=value pairs from the bundled env.sync (active, uncommented lines),
    /// so a committed env file can override the baked defaults. Empty if absent.
    private static let envSync: [String: String] = {
        guard let fileURL = Bundle.main.url(forResource: "env", withExtension: "sync"),
              let text = try? String(contentsOf: fileURL, encoding: .utf8) else { return [:] }
        var map: [String: String] = [:]
        for rawLine in text.split(separator: "\n", omittingEmptySubsequences: true) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            guard let eq = line.firstIndex(of: "=") else { continue }
            let key = String(line[..<eq]).trimmingCharacters(in: .whitespaces)
            let value = String(line[line.index(after: eq)...]).trimmingCharacters(in: .whitespaces)
            if !key.isEmpty { map[key] = value }
        }
        return map
    }()

    static var accessToken: String {
        get { UserDefaults.standard.string(forKey: "sb_access_token") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "sb_access_token") }
    }
    static var refreshToken: String {
        get { UserDefaults.standard.string(forKey: "sb_refresh_token") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "sb_refresh_token") }
    }
    static var userId: String {
        get { UserDefaults.standard.string(forKey: "sb_user_id") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "sb_user_id") }
    }
    static var lastSyncTimestamp: String {
        get { UserDefaults.standard.string(forKey: "sb_last_sync_timestamp") ?? "1970-01-01T00:00:00Z" }
        set { UserDefaults.standard.set(newValue, forKey: "sb_last_sync_timestamp") }
    }

    static var isConfigured: Bool { !url.isEmpty && !anonKey.isEmpty }
    static var isAuthenticated: Bool { !accessToken.isEmpty && !userId.isEmpty }

    static func parseUserId(fromJwt jwt: String) -> String {
        let json = decodeJwt(jwt)
        return json?["sub"] as? String ?? ""
    }

    static func parseEmail(fromJwt jwt: String) -> String {
        let json = decodeJwt(jwt)
        return json?["email"] as? String ?? ""
    }

    /// The cloud stores `source_ref` as a JSON object — `{"name":"JS_ASURASCANS_US"}`
    /// (canonical, written by mac/android) or `{"type":"...MangaSourceRef.Unknown"}`.
    /// Older rows may be a bare string. Return the usable source name; "" for
    /// genuinely-unknown sources so the client degrades gracefully.
    static func sourceName(fromRef raw: String) -> String {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard s.hasPrefix("{") else { return s }   // already a bare name
        guard let data = s.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return s }
        if let name = obj["name"] as? String, !name.isEmpty {
            return name.hasSuffix(".MangaSourceRef.Unknown") ? "" : name
        }
        if let type = obj["type"] as? String {
            if type.hasSuffix(".Local") { return "LOCAL" }
            return ""   // Unknown / unresolvable
        }
        return s
    }

    /// Encode a local (bare, e.g. "ASURASCANS_US") source name into the canonical
    /// cloud form `{"name":"JS_…"}` so iOS-originated rows match mac/android.
    static func encodeSourceRef(_ name: String) -> String {
        let n: String
        switch name {
        case "", "UNKNOWN": n = "UNKNOWN"
        case "LOCAL": n = "LOCAL"
        default: n = (name.hasPrefix("JS_") || name.hasPrefix("MIHON_")) ? name : "JS_\(name)"
        }
        if let data = try? JSONSerialization.data(withJSONObject: ["name": n]),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "{\"name\":\"\(n)\"}"
    }

    private static func decodeJwt(_ jwt: String) -> [String: Any]? {
        let parts = jwt.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count >= 2 else { return nil }
        var payload = String(parts[1])
        let padding = (4 - payload.count % 4) % 4
        payload += String(repeating: "=", count: padding)
        guard let data = Data(base64Encoded: payload, options: .ignoreUnknownCharacters),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return json
    }

    static func signOut() {
        accessToken = ""; refreshToken = ""; userId = ""; lastSyncTimestamp = "1970-01-01T00:00:00Z"
    }
}

// MARK: - Sync

@MainActor
final class SupabaseSync {
    static let shared = SupabaseSync()
    private let session = URLSession.shared
    private let INITIAL_SYNC_TIMESTAMP = "1970-01-01T00:00:00Z"
    
    private var syncFunctionUrl: String { "\(SupabaseConfig.url)/functions/v1/nyora-sync" }

    // MARK: Auth

    func signInWithGoogle(idToken: String) async -> Bool {
        guard SupabaseConfig.isConfigured else { return false }
        let payload: [String: Any] = ["provider": "google", "id_token": idToken]
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return false }
        
        var req = URLRequest(url: URL(string: "\(SupabaseConfig.url)/auth/v1/token?grant_type=id_token")!)
        req.httpMethod = "POST"
        req.httpBody = body
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        
        guard let (data, resp) = try? await session.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let at = json["access_token"] as? String else { return false }
        
        let previousUserId = SupabaseConfig.userId
        SupabaseConfig.accessToken = at
        SupabaseConfig.refreshToken = json["refresh_token"] as? String ?? ""
        SupabaseConfig.userId = SupabaseConfig.parseUserId(fromJwt: at)
        if !previousUserId.isEmpty && previousUserId != SupabaseConfig.userId {
            SupabaseConfig.lastSyncTimestamp = INITIAL_SYNC_TIMESTAMP
        }
        return !SupabaseConfig.userId.isEmpty
    }

    func refreshToken() async -> Bool {
        guard SupabaseConfig.isConfigured, !SupabaseConfig.refreshToken.isEmpty else { return false }
        let payload: [String: Any] = ["refresh_token": SupabaseConfig.refreshToken]
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return false }
        
        var req = URLRequest(url: URL(string: "\(SupabaseConfig.url)/auth/v1/token?grant_type=refresh_token")!)
        req.httpMethod = "POST"
        req.httpBody = body
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        
        guard let (data, resp) = try? await session.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let at = json["access_token"] as? String else { return false }
        
        SupabaseConfig.accessToken = at
        if let rt = json["refresh_token"] as? String { SupabaseConfig.refreshToken = rt }
        return true
    }

    func signOut() {
        SupabaseConfig.signOut()
    }

    // MARK: Sync Logic

    func syncNow(store: LibraryStore) async {
        guard SupabaseConfig.isAuthenticated else { return }
        _ = await refreshToken()

        // Capture cutoff AFTER push so that any remote changes that arrived
        // during the push window are included in this pull cycle.
        await pushAll(store: store)
        let cutoff = SupabaseConfig.lastSyncTimestamp
        await pullAll(store: store, since: cutoff)

        SupabaseConfig.lastSyncTimestamp = ISO8601DateFormatter().string(from: Date())
    }

    func restoreFromCloud(store: LibraryStore) async {
        guard SupabaseConfig.isAuthenticated else { return }
        _ = await refreshToken()
        
        store.resetAll()
        await pullAll(store: store, since: INITIAL_SYNC_TIMESTAMP)
        
        SupabaseConfig.lastSyncTimestamp = ISO8601DateFormatter().string(from: Date())
    }

    func pushAll(store: LibraryStore, cutoff: Date = .distantPast) async {
        let uid = SupabaseConfig.userId
        let iso = ISO8601DateFormatter()
        let nowStr = iso.string(from: Date())
        
        // 1. Manga metadata
        let refs = store.snapshot.favourites + store.snapshot.history.map { $0.manga } + store.snapshot.readLater
        var seen = Set<Int64>()
        let mangaRows: [[String: Any]] = refs.compactMap { ref in
            guard seen.insert(ref.id).inserted else { return nil }
            return [
                "user_id": uid, "id": "\(ref.id)",
                "title": ref.title, "url": ref.url, "public_url": ref.publicUrl,
                "cover_url": ref.coverUrl ?? "", "source_ref": SupabaseConfig.encodeSourceRef(ref.sourceName),
                "updated_at": nowStr
            ]
        }
        if !mangaRows.isEmpty { await upsert(table: "nyora_manga", rows: mangaRows) }

        // 2. Favourites
        let favRows: [[String: Any]] = store.snapshot.favourites.map { ref in
            ["user_id": uid, "manga_id": "\(ref.id)", "updated_at": iso.string(from: ref.updatedAt), "deleted_at": ref.deletedAt != nil ? iso.string(from: ref.deletedAt!) : NSNull()]
        }
        if !favRows.isEmpty { await upsert(table: "nyora_favourite", rows: favRows) }

        // 3. History
        let historyRows: [[String: Any]] = store.snapshot.history.map { entry in
            [
                "user_id": uid, "manga_id": "\(entry.manga.id)",
                "source_id": entry.manga.sourceName,
                "chapter_id": "\(entry.chapterId)", "chapter_title": entry.chapterTitle,
                "page": entry.page, "percent": entry.percent,
                "updated_at": iso.string(from: entry.updatedAt),
                "deleted_at": entry.deletedAt != nil ? iso.string(from: entry.deletedAt!) : NSNull()
            ]
        }
        if !historyRows.isEmpty { await upsert(table: "nyora_history", rows: historyRows) }

        // 4. Bookmarks
        let bookmarkRows: [[String: Any]] = store.snapshot.bookmarks.map { b in
            [
                "user_id": uid, "id": b.id,
                "manga_id": "\(b.manga.id)", "chapter_id": "\(b.chapterId)",
                "chapter_title": b.chapterTitle, "page": b.page,
                "created_at": iso.string(from: b.createdAt),
                "updated_at": iso.string(from: b.updatedAt),
                "deleted_at": b.deletedAt != nil ? iso.string(from: b.deletedAt!) : NSNull()
            ]
        }
        if !bookmarkRows.isEmpty { await upsert(table: "nyora_bookmark", rows: bookmarkRows) }

        // 5. Categories
        let catRows: [[String: Any]] = store.snapshot.categories.map { cat in
            ["user_id": uid, "id": cat.id, "title": cat.name, "updated_at": iso.string(from: cat.updatedAt), "deleted_at": cat.deletedAt != nil ? iso.string(from: cat.deletedAt!) : NSNull()]
        }
        if !catRows.isEmpty { await upsert(table: "nyora_category", rows: catRows) }

        // 6. Manga Categories
        var mcRows: [[String: Any]] = []
        for (mId, cIds) in store.snapshot.mangaCategories {
            for cId in cIds {
                mcRows.append(["user_id": uid, "manga_id": mId, "category_id": cId, "updated_at": nowStr])
            }
        }
        if !mcRows.isEmpty { await upsert(table: "nyora_manga_category", rows: mcRows) }

        // 7. Source Prefs
        let sources = JSParserEngine.shared.sources
        if !sources.isEmpty {
            let spRows: [[String: Any]] = sources.map { s in
                [
                    "user_id": uid, "source_id": s.name,
                    "is_pinned": SourcePrefs.shared.isPinned(s.name),
                    "is_enabled": SourcePrefs.shared.isEnabled(s.name),
                    "updated_at": nowStr
                ]
            }
            await upsert(table: "nyora_source_prefs", rows: spRows)
        }
    }

    func pullAll(store: LibraryStore, since: String) async {
        // Pre-fetch the full manga metadata table (no since filter) so history and
        // bookmarks can reconstruct MangaRef on a fresh install where the manga is
        // not yet present locally.  The result is threaded through to the sub-pulls.
        let allMangaRows = await fetch(table: "nyora_manga") ?? []
        await pullFavourites(store: store, since: since, mangaRows: allMangaRows)
        await pullHistory(store: store, since: since, mangaRows: allMangaRows)
        await pullBookmarks(store: store, since: since, mangaRows: allMangaRows)
        await pullCategories(store: store, since: since)
        await pullMangaCategories(store: store, since: since)
        await pullSourcePrefs(since: since)
    }

    private func pullFavourites(store: LibraryStore, since: String, mangaRows: [[String: Any]]) async {
        guard let rows = await fetch(table: "nyora_favourite", since: since) else { return }
        let iso = ISO8601DateFormatter()
        
        for row in rows {
            guard let mangaIdStr = row["manga_id"] as? String,
                  let mangaId = Int64(mangaIdStr) else { continue }
            
            let updatedAt = iso.date(from: row["updated_at"] as? String ?? "") ?? Date.distantPast
            let deletedAt = iso.date(from: row["deleted_at"] as? String ?? "")
            
            if deletedAt != nil {
                store.syncRemoveFavourite(mangaId: mangaId, deletedAt: deletedAt!)
            } else if !store.isFavourite(mangaId) {
                if let m = mangaRows.first(where: { ($0["id"] as? String) == mangaIdStr }) {
                    let ref = MangaRef(
                        id: mangaId,
                        title: m["title"] as? String ?? "",
                        url: m["url"] as? String ?? "",
                        publicUrl: m["public_url"] as? String ?? "",
                        coverUrl: m["cover_url"] as? String,
                        sourceName: SupabaseConfig.sourceName(fromRef: m["source_ref"] as? String ?? ""),
                        updatedAt: updatedAt
                    )
                    store.syncInsertFavourite(ref)
                }
            }
        }
    }

    private func pullHistory(store: LibraryStore, since: String, mangaRows: [[String: Any]]) async {
        guard let rows = await fetch(table: "nyora_history", since: since) else { return }
        let iso = ISO8601DateFormatter()
        for row in rows {
            guard let mangaIdStr = row["manga_id"] as? String,
                  let mangaId = Int64(mangaIdStr),
                  let chapterIdStr = row["chapter_id"] as? String,
                  let chapterId = Int64(chapterIdStr) else { continue }

            let updatedAt = iso.date(from: row["updated_at"] as? String ?? "") ?? Date.distantPast
            let deletedAt = iso.date(from: row["deleted_at"] as? String ?? "")

            if deletedAt != nil { store.syncRemoveHistory(mangaId: mangaId, deletedAt: deletedAt!); continue }

            if let local = store.history(for: mangaId), local.updatedAt > updatedAt { continue }

            // Prefer local refs; fall back to nyora_manga rows for fresh-install restores.
            let ref: MangaRef
            if let local = store.snapshot.favourites.first(where: { $0.id == mangaId }) ??
                            store.snapshot.history.first(where: { $0.manga.id == mangaId })?.manga ??
                            store.snapshot.readLater.first(where: { $0.id == mangaId }) {
                ref = local
            } else if let m = mangaRows.first(where: { ($0["id"] as? String) == mangaIdStr }) {
                ref = MangaRef(
                    id: mangaId,
                    title: m["title"] as? String ?? "",
                    url: m["url"] as? String ?? "",
                    publicUrl: m["public_url"] as? String ?? "",
                    coverUrl: m["cover_url"] as? String,
                    sourceName: SupabaseConfig.sourceName(fromRef: m["source_ref"] as? String ?? "")
                )
            } else {
                continue
            }

            let page = row["page"] as? Int ?? 0
            store.syncUpsertHistory(
                manga: ref, chapterId: chapterId,
                chapterTitle: row["chapter_title"] as? String ?? "",
                page: page, totalPages: max(1, page + 1), updatedAt: updatedAt
            )
        }
    }

    private func pullBookmarks(store: LibraryStore, since: String, mangaRows: [[String: Any]]) async {
        guard let rows = await fetch(table: "nyora_bookmark", since: since) else { return }
        let iso = ISO8601DateFormatter()
        for row in rows {
            guard let remoteId = row["id"] as? String,
                  let mangaIdStr = row["manga_id"] as? String,
                  let mangaId = Int64(mangaIdStr),
                  let chapterIdStr = row["chapter_id"] as? String,
                  let chapterId = Int64(chapterIdStr) else { continue }

            let page = row["page"] as? Int ?? 0
            let createdAt = iso.date(from: row["created_at"] as? String ?? "") ?? Date()
            let updatedAt = iso.date(from: row["updated_at"] as? String ?? "") ?? Date.distantPast
            let deletedAt = iso.date(from: row["deleted_at"] as? String ?? "")

            if deletedAt != nil {
                // syncRemoveBookmark uses the local composite id; compute it here.
                let localId = "\(mangaId):\(chapterId):\(page)"
                store.syncRemoveBookmark(id: localId, deletedAt: deletedAt!)
                continue
            }

            // Use (manga.id, chapterId, page) for duplicate detection so we match
            // the locally-generated composite id rather than the remote UUID, preventing
            // duplicates from re-inserting on every pull cycle.
            guard !store.snapshot.bookmarks.contains(where: {
                $0.manga.id == mangaId && $0.chapterId == chapterId && $0.page == page
            }) else { continue }

            // Prefer local refs; fall back to nyora_manga rows for fresh-install restores.
            let ref: MangaRef
            if let local = store.snapshot.favourites.first(where: { $0.id == mangaId }) ??
                            store.snapshot.history.first(where: { $0.manga.id == mangaId })?.manga ??
                            store.snapshot.readLater.first(where: { $0.id == mangaId }) {
                ref = local
            } else if let m = mangaRows.first(where: { ($0["id"] as? String) == mangaIdStr }) {
                ref = MangaRef(
                    id: mangaId,
                    title: m["title"] as? String ?? "",
                    url: m["url"] as? String ?? "",
                    publicUrl: m["public_url"] as? String ?? "",
                    coverUrl: m["cover_url"] as? String,
                    sourceName: SupabaseConfig.sourceName(fromRef: m["source_ref"] as? String ?? "")
                )
            } else {
                continue
            }

            store.syncInsertBookmark(
                manga: ref, chapterId: chapterId,
                chapterTitle: row["chapter_title"] as? String ?? "",
                page: page, createdAt: createdAt, updatedAt: updatedAt, deletedAt: nil
            )
            _ = remoteId // remote UUID noted; local id is the composite form
        }
    }

    private func pullCategories(store: LibraryStore, since: String) async {
        guard let rows = await fetch(table: "nyora_category", since: since) else { return }
        let iso = ISO8601DateFormatter()
        for row in rows {
            guard let id = row["id"] as? String, let title = row["title"] as? String else { continue }
            let updatedAt = iso.date(from: row["updated_at"] as? String ?? "") ?? Date.distantPast
            let deletedAt = iso.date(from: row["deleted_at"] as? String ?? "")
            
            if deletedAt != nil {
                store.syncRemoveCategory(id: id, deletedAt: deletedAt!)
            } else {
                store.syncInsertCategory(Category(id: id, name: title, updatedAt: updatedAt, deletedAt: nil))
            }
        }
        // Collapse any duplicate-title categories that arrived from legacy per-device seeds.
        store.dedupeCategories()
    }

    private func pullMangaCategories(store: LibraryStore, since: String) async {
        guard let rows = await fetch(table: "nyora_manga_category", since: since) else { return }
        for row in rows {
            guard let mId = row["manga_id"] as? String,
                  let cId = row["category_id"] as? String,
                  let mangaId = Int64(mId) else { continue }
            
            let isDeleted = row["deleted_at"] != nil && !(row["deleted_at"] is NSNull)
            if isDeleted {
                var cIds = store.categories(for: mangaId)
                cIds.removeAll { $0 == cId }
                store.setCategories(cIds, for: mangaId)
            } else {
                var cIds = store.categories(for: mangaId)
                if !cIds.contains(cId) {
                    cIds.append(cId)
                    store.setCategories(cIds, for: mangaId)
                }
            }
        }
    }

    private func pullSourcePrefs(since: String) async {
        guard let rows = await fetch(table: "nyora_source_prefs", since: since) else { return }
        for row in rows {
            guard let sourceId = row["source_id"] as? String,
                  let isPinned = row["is_pinned"] as? Bool,
                  let isEnabled = row["is_enabled"] as? Bool else { continue }
            SourcePrefs.shared.setPinned(isPinned, for: sourceId)
            SourcePrefs.shared.setEnabled(isEnabled, for: sourceId)
        }
    }

    // MARK: Edge Function Helpers

    private func fetch(table: String, since: String? = nil) async -> [[String: Any]]? {
        var payload: [String: Any] = [
            "action": "select",
            "table": table
        ]
        if let since = since, since != INITIAL_SYNC_TIMESTAMP {
            payload["since"] = since
        }
        
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return nil }
        var req = URLRequest(url: URL(string: syncFunctionUrl)!)
        req.httpMethod = "POST"
        req.httpBody = body
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(SupabaseConfig.accessToken)", forHTTPHeaderField: "Authorization")
        
        guard let (data, resp) = try? await session.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rows = json["data"] as? [[String: Any]] else { return nil }
        
        return rows
    }

    private func upsert(table: String, rows: [[String: Any]]) async {
        guard !rows.isEmpty else { return }
        let payload: [String: Any] = [
            "action": "upsert",
            "table": table,
            "rows": rows
        ]
        
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
        var req = URLRequest(url: URL(string: syncFunctionUrl)!)
        req.httpMethod = "POST"
        req.httpBody = body
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(SupabaseConfig.accessToken)", forHTTPHeaderField: "Authorization")
        
        _ = try? await session.data(for: req)
    }
}
