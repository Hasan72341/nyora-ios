import SwiftUI
import NyoraEngine

/// Async image loader that honours per-source request headers (Referer/User-Agent), which
/// `AsyncImage` cannot do. Backed by a small in-memory + URLCache layer.
struct RemoteImage: View {
    let url: URL?
    var headers: [String: String] = [:]
    var contentMode: ContentMode = .fill

    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                Rectangle()
                    .fill(.quaternary)
                    .overlay {
                        if failed {
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        } else {
                            ProgressView()
                        }
                    }
            }
        }
        .clipped()
        .task(id: url) { await load() }
    }

    private func load() async {
        guard let url else { failed = true; return }
        image = nil; failed = false
        if let cached = ImageLoader.shared.cached(url) {
            image = cached
            return
        }
        do {
            let img = try await ImageLoader.shared.load(url, headers: headers)
            if !Task.isCancelled { image = img }
        } catch {
            if !Task.isCancelled { failed = true }
        }
    }
}

/// Shared image fetcher with an NSCache and URLCache-backed session.
final class ImageLoader: @unchecked Sendable {
    static let shared = ImageLoader()
    private let cache = NSCache<NSURL, UIImage>()
    /// Shared URLCache reused across session rebuilds so HTTP image caching survives a
    /// proxy-settings change (the session is rebuilt, but its disk/memory cache persists).
    private let urlCache = URLCache(memoryCapacity: 32 << 20, diskCapacity: 256 << 20)
    private let lock = NSLock()
    private var session: URLSession
    /// Fingerprint of the proxy settings the current `session` was built with.
    private var sessionProxyFingerprint: String

    init() {
        cache.countLimit = 200
        self.sessionProxyFingerprint = ProxyConfiguration.fingerprint()
        self.session = ImageLoader.makeSession(urlCache: urlCache)
    }

    private static func makeSession(urlCache: URLCache) -> URLSession {
        let cfg = URLSessionConfiguration.default
        cfg.urlCache = urlCache
        cfg.requestCachePolicy = .returnCacheDataElseLoad
        if let proxy = ProxyConfiguration.currentDictionary() {
            cfg.connectionProxyDictionary = proxy
        }
        return URLSession(configuration: cfg)
    }

    /// Returns the active session, rebuilding it (keeping the same URLCache) if the
    /// persisted proxy settings changed since it was created.
    private func currentSession() -> URLSession {
        let fp = ProxyConfiguration.fingerprint()
        lock.lock()
        defer { lock.unlock() }
        if fp != sessionProxyFingerprint {
            session.finishTasksAndInvalidate()
            session = ImageLoader.makeSession(urlCache: urlCache)
            sessionProxyFingerprint = fp
        }
        return session
    }

    func cached(_ url: URL) -> UIImage? { cache.object(forKey: url as NSURL) }

    /// Bytes currently held by this loader's private URLCache (disk + memory). Used by the
    /// storage-usage breakdown. NSCache size isn't queryable, so only the URLCache is counted.
    var diskCacheBytes: Int64 {
        Int64(urlCache.currentDiskUsage + urlCache.currentMemoryUsage)
    }

    /// Drop everything this loader is holding: the in-memory decoded-image NSCache and the
    /// backing URLCache (the on-disk/in-memory cached HTTP responses for page/cover images).
    func clearAll() {
        cache.removeAllObjects()
        urlCache.removeAllCachedResponses()
    }

    func load(_ url: URL, headers: [String: String]) async throws -> UIImage {
        if url.isFileURL {
            guard let img = UIImage(contentsOfFile: url.path) else {
                throw URLError(.cannotDecodeContentData)
            }
            cache.setObject(img, forKey: url as NSURL)
            return img
        }
        var req = URLRequest(url: url)
        for (k, v) in headers { req.setValue(v, forHTTPHeaderField: k) }
        let (data, _) = try await currentSession().data(for: req)
        guard let img = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        cache.setObject(img, forKey: url as NSURL)
        return img
    }
}
