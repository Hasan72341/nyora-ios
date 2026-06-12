import Foundation
import WebKit
import CryptoKit
import NyoraEngine

// MARK: - Source entry from sources.json

private struct JSSourceEntry: Decodable {
    let id: String
    let title: String
    let locale: String
    let domain: String
    let family: String
    let isNsfw: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, locale, domain, family, isNsfw
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        locale = (try? c.decode(String.self, forKey: .locale)) ?? ""
        domain = (try? c.decode(String.self, forKey: .domain)) ?? ""
        family = (try? c.decode(String.self, forKey: .family)) ?? ""
        isNsfw = (try? c.decode(Bool.self, forKey: .isNsfw)) ?? false
    }
}

// MARK: - Errors

enum JSEngineError: LocalizedError {
    case notLoaded(String)
    case js(String)
    case timeout

    var errorDescription: String? {
        switch self {
        case .notLoaded(let m): return "JS engine not loaded: \(m)"
        case .js(let m): return m
        case .timeout: return "parser call timed out"
        }
    }
}

// MARK: - Shared HTTP fetch

enum DirectFetch {
    static let ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

    static func text(url: String, method: String, domain: String, body: String?,
                     headersJson: String? = nil,
                     allowCloudflareSolve: Bool = true) async throws -> String {
        guard let targetURL = URL(string: url) else { throw URLError(.badURL) }
        var req = URLRequest(url: targetURL)
        req.httpMethod = method
        req.timeoutInterval = 30
        req.setValue(ua, forHTTPHeaderField: "User-Agent")
        req.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        req.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        if !domain.isEmpty {
            req.setValue("https://\(domain)/", forHTTPHeaderField: "Referer")
        }
        if method == "POST" {
            if !domain.isEmpty { req.setValue("https://\(domain)", forHTTPHeaderField: "Origin") }
            req.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
            req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            req.httpBody = body?.data(using: .utf8)
        }

        // Apply custom headers
        if let headersJson, let data = headersJson.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            for (k, v) in dict {
                req.setValue("\(v)", forHTTPHeaderField: k)
            }
        }

        let (data, response) = try await URLSession.shared.data(for: req)
        let http = response as? HTTPURLResponse
        let bodyText = String(decoding: data, as: UTF8.self)

        // Cloudflare challenge → headless solver, then interactive sheet, then retry once.
        if allowCloudflareSolve, looksLikeCloudflare(status: http?.statusCode ?? 0, headers: http, body: bodyText) {
            var cleared = await CloudflareSolver.shared.solve(url: targetURL, userAgent: ua)
            if !cleared {
                cleared = await CloudflareInteractive.shared.solveInteractively(url: targetURL, userAgent: ua)
            }
            if cleared {
                return try await text(url: url, method: method, domain: domain, body: body, headersJson: headersJson, allowCloudflareSolve: false)
            }
        }

        if let http, !(200..<400).contains(http.statusCode) {
            throw NSError(domain: "Nyora", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"])
        }
        return bodyText
    }

    static func finalUrl(url: String, domain: String) async throws -> String {
        guard let targetURL = URL(string: url) else { throw URLError(.badURL) }
        var req = URLRequest(url: targetURL)
        req.httpMethod = "HEAD"
        req.timeoutInterval = 10
        req.setValue(ua, forHTTPHeaderField: "User-Agent")
        if !domain.isEmpty {
            req.setValue("https://\(domain)/", forHTTPHeaderField: "Referer")
        }
        let (_, response) = try await URLSession.shared.data(for: req)
        return (response as? HTTPURLResponse)?.url?.absoluteString ?? url
    }

    private static func looksLikeCloudflare(status: Int, headers: HTTPURLResponse?, body: String) -> Bool {
        let challengeStatus = (status == 403 || status == 503 || status == 429)
        if headers?.value(forHTTPHeaderField: "cf-mitigated") != nil { return true }
        guard challengeStatus else { return false }
        let markers = ["just a moment", "__cf_chl", "challenge-platform", "cf-browser-verification", "turnstile"]
        let lower = body.lowercased()
        return markers.contains { lower.contains($0) }
    }
}

// MARK: - Bridge objects (each conforms to exactly one protocol)

/// HTTP requests from JS — standard WKScriptMessageHandler, results posted back via __resolveHttp.
private final class HTTPReplyBridge: NSObject, WKScriptMessageHandler {
    weak var engine: JSParserEngine?

    func userContentController(_ ucc: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let id = body["id"] as? String,
              let url = body["url"] as? String,
              let method = body["method"] as? String else {
            return
        }
        let domain = body["domain"] as? String ?? ""
        let headers = body["headers"] as? String
        let postBody = body["body"] as? String
        let isRedirCheck = body["_isRedirCheck"] as? Bool ?? false

        Task {
            do {
                if isRedirCheck {
                    let finalUrl = try await DirectFetch.finalUrl(url: url, domain: domain)
                    engine?.resolveHttp(id: id, ok: true, payload: finalUrl)
                } else {
                    let text = try await DirectFetch.text(url: url, method: method, domain: domain,
                                                        body: postBody, headersJson: headers)
                    engine?.resolveHttp(id: id, ok: true, payload: text)
                }
            } catch {
                engine?.resolveHttp(id: id, ok: false, payload: error.localizedDescription)
            }
        }
    }
}

/// Generic one-way message → closure (console logs + parser results).
private final class MessageBridge: NSObject, WKScriptMessageHandler {
    let sink: (Any) -> Void
    init(sink: @escaping (Any) -> Void) { self.sink = sink }
    func userContentController(_ ucc: WKUserContentController, didReceive message: WKScriptMessage) {
        sink(message.body)
    }
}

// MARK: - Engine

/// Hosts the nyora-web JS parsers inside a single hidden WKWebView.
///
/// Design notes (hard-won): `callAsyncJavaScript` on this WebKit does NOT await the async
/// function body — it returns after the synchronous prefix and drops the result. So parser
/// calls are fully message-driven: `evaluateJavaScript` fires `window.__runParser(token,…)`
/// (fire-and-forget); the JS posts its result back via the `nyoraResult` handler, which
/// resolves a Swift continuation keyed by token. HTTP uses a WKScriptMessageHandlerWithReply
/// bridge (so JS can `await` the response). DOM parsing uses the native DOMParser.
@MainActor
final class JSParserEngine: NSObject {
    static let shared = JSParserEngine()

    let sources: [MangaParserSource]
    private let domainBySource: [String: String]

    private var webView: WKWebView!
    private var isLoaded = false
    private var loadError: String?
    private var pendingReady: [CheckedContinuation<Void, Never>] = []

    private var callSeq = 0
    private var pendingCalls: [String: CheckedContinuation<String, Error>] = [:]

    private(set) var consoleLog: [String] = []
    private var httpBridge: HTTPReplyBridge!
    private var resultBridge: MessageBridge!
    private var logBridge: MessageBridge!

    private override init() {
        var srcs: [MangaParserSource] = []
        var doms: [String: String] = [:]
        if let url = ParserOTA.sourcesURL(),
           let data = try? Data(contentsOf: url),
           let entries = try? JSONDecoder().decode([JSSourceEntry].self, from: data) {
            for e in entries {
                let ct: ContentType = e.isNsfw ? .hentai : .manga
                let src = MangaParserSource(name: e.id, title: e.title,
                                            locale: e.locale.isEmpty ? nil : e.locale, contentType: ct)
                srcs.append(src)
                doms[e.id] = e.domain
                SourceRegistry.shared.register(src)
            }
        }
        sources = srcs
        domainBySource = doms
        super.init()
        setupWebView()
        // Check for an OTA parser update in the background; applies on next launch.
        ParserOTA.checkForUpdate()
    }

    func domain(for sourceId: String) -> String {
        domainBySource[sourceId] ?? domainBySource[Self.bareSourceId(sourceId)] ?? ""
    }

    /// iOS catalog ids are bare ("ASURASCANS_US") but synced/canonical source
    /// refs (from mac/android/cloud) are "JS_"-prefixed ("JS_ASURASCANS_US").
    static func bareSourceId(_ id: String) -> String {
        id.hasPrefix("JS_") ? String(id.dropFirst(3)) : id
    }

    func parser(for sourceId: String) -> JSMangaParser? {
        // Resolve tolerantly so history/favourites synced from other platforms
        // (which carry the "JS_"-prefixed name) still map to the right parser.
        let bare = Self.bareSourceId(sourceId)
        guard let src = sources.first(where: { $0.name == sourceId || $0.name == bare }) else { return nil }
        return JSMangaParser(source: src, domain: domainBySource[src.name] ?? "", engine: self)
    }

    // MARK: WebView setup

    private static let bridgeScript = """
(function() {
    var pend = {}, n = 0;
    function dec(b64) {
        try {
            return decodeURIComponent(escape(atob(b64)));
        } catch (e) {
            // Fallback for cases where atob result is already valid UTF8 or has invalid chars
            try { return atob(b64); } catch(e2) { return ""; }
        }
    }

    function mergeHeaders(parser, extra) {
        var out = {};
        if (parser && parser.headers) { for (var k in parser.headers) out[k] = parser.headers[k]; }
        if (extra) { for (var k2 in extra) out[k2] = extra[k2]; }
        return Object.keys(out).length ? JSON.stringify(out) : null;
    }

    window.__resolveHttp = function(id, ok, b64) {
        var p = pend[id]; if (!p) return; delete pend[id];
        var t = dec(b64);
        if (ok) p.resolve(t); else p.reject(new Error(t));
    };

    window.__context = {
        httpGet: function(url, extraHeaders, parser) {
            return new Promise(function(res, rej) {
                var id = 'h' + (++n); pend[id] = { resolve: res, reject: rej };
                var actualHeaders = extraHeaders;
                var actualParser = parser;
                // Match Android's argument-count-aware logic
                if (arguments.length < 3 && extraHeaders && typeof extraHeaders === 'object' && !Array.isArray(extraHeaders)) {
                    actualParser = extraHeaders;
                    actualHeaders = null;
                }
                webkit.messageHandlers.nyoraHttp.postMessage({
                    id: id, url: url, method: 'GET',
                    headers: mergeHeaders(actualParser, actualHeaders),
                    domain: (actualParser && actualParser.domain) ? actualParser.domain : ''
                });
            });
        },
        httpPost: function(url, body, extraHeaders, parser) {
            return new Promise(function(res, rej) {
                var id = 'h' + (++n); pend[id] = { resolve: res, reject: rej };
                webkit.messageHandlers.nyoraHttp.postMessage({
                    id: id, url: url, method: 'POST', body: body || '',
                    headers: mergeHeaders(parser, extraHeaders),
                    domain: (parser && parser.domain) ? parser.domain : ''
                });
            });
        },
        parseHTML: function(html) {
            return new DOMParser().parseFromString(html, 'text/html');
        },
        decodeContent: function(s) { return s; }
    };

    // Fire-and-forget async runner. Result posted back via nyoraResult keyed by token.
    window.__runParser = async function(token, sid, method, b64args) {
        try {
            var args = JSON.parse(dec(b64args));
            var p = NyoraParsers.getParser(sid, window.__context);
            if (!p) throw new Error('parser not found: ' + sid);

            // AUTO-REDIRECTION SUPPORT:
            try {
                if (method === 'list' && args.page === 1 && (!args.filter || !args.filter.query)) {
                    var testUrl = 'https://' + p.domain + '/';
                    var finalUrl = await new Promise(function(res, rej) {
                        var id = 'r' + (++n); pend[id] = { resolve: res, reject: rej };
                        webkit.messageHandlers.nyoraHttp.postMessage({
                            id: id, url: testUrl, method: 'HEAD', domain: p.domain, _isRedirCheck: true
                        });
                    });
                    if (finalUrl && finalUrl.startsWith('http')) {
                         var newDomain = new URL(finalUrl).hostname;
                         if (newDomain && newDomain !== p.domain) {
                             console.log('[Redir] Domain changed: ' + p.domain + ' -> ' + newDomain);
                             p.domain = newDomain;
                         }
                    }
                }
            } catch (e) { console.error('[Redir] check failed', e); }

            var r;
            if (method === 'list') {
                r = await p.getListPage(args.page, args.order, args.filter || {});
            } else if (method === 'details') {
                r = await p.getDetails({ id: args.url, url: args.url, source: { id: sid, name: sid } });
            } else if (method === 'pages') {
                r = await p.getPages({ id: args.url, url: args.url, branch: args.branch, source: { id: sid } });
            } else {
                throw new Error('unknown method ' + method);
            }
            webkit.messageHandlers.nyoraResult.postMessage({ token: token, ok: true, json: JSON.stringify(r === undefined ? null : r) });
        } catch (e) {
            webkit.messageHandlers.nyoraResult.postMessage({ token: token, ok: false, error: (e && e.message ? e.message : String(e)) });
        }
    };

    function send(level, args) {
        try {
            var s = Array.prototype.map.call(args, function(a) {
                if (a instanceof Error) return a.message;
                if (typeof a === 'object') { try { return JSON.stringify(a); } catch (e) { return String(a); } }
                return String(a);
            }).join(' ');
            webkit.messageHandlers.nyoraLog.postMessage(level + ': ' + s);
        } catch (e) {}
    }
    var _err = console.error;
    console.error = function() { send('error', arguments); if (_err) _err.apply(console, arguments); };
    window.onerror = function(msg, src, line, col) { send('onerror', [msg + ' @' + line + ':' + col]); };
    window.addEventListener('unhandledrejection', function(e) {
        send('unhandledrejection', [e.reason && e.reason.message ? e.reason.message : String(e.reason)]);
    });
})();
"""

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        let ucc = config.userContentController

        httpBridge = HTTPReplyBridge()
        httpBridge.engine = self
        resultBridge = MessageBridge(sink: { [weak self] body in
            Task { @MainActor in self?.handleResult(body) }
        })
        logBridge = MessageBridge(sink: { [weak self] body in
            if let s = body as? String { Task { @MainActor in self?.appendLog(s) } }
        })

        ucc.add(httpBridge, name: "nyoraHttp")
        ucc.add(resultBridge, name: "nyoraResult")
        ucc.add(logBridge, name: "nyoraLog")

        let userScript = WKUserScript(source: Self.bridgeScript,
                                      injectionTime: .atDocumentStart,
                                      forMainFrameOnly: true, in: .page)
        ucc.addUserScript(userScript)

        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), configuration: config)
        webView.navigationDelegate = self
        webView.isHidden = true
        webView.loadHTMLString("<html><body></body></html>", baseURL: URL(string: "https://nyora.local/"))
    }

    private func appendLog(_ s: String) {
        consoleLog.append(s)
        if consoleLog.count > 200 { consoleLog.removeFirst(consoleLog.count - 200) }
    }

    private func handleResult(_ body: Any) {
        guard let dict = body as? [String: Any], let token = dict["token"] as? String,
              let cont = pendingCalls.removeValue(forKey: token) else { return }
        if (dict["ok"] as? Bool) == true, let json = dict["json"] as? String {
            cont.resume(returning: json)
        } else {
            cont.resume(throwing: JSEngineError.js((dict["error"] as? String) ?? "unknown JS error"))
        }
    }

    // MARK: Ready gating

    func waitUntilLoaded() async {
        guard !isLoaded else { return }
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            if isLoaded { cont.resume() } else { pendingReady.append(cont) }
        }
    }

    private func markLoaded(error: String? = nil) {
        if isLoaded { return }
        loadError = error
        isLoaded = true
        let cbs = pendingReady
        pendingReady = []
        cbs.forEach { $0.resume() }
    }

    // MARK: Parser call

    /// Invokes a parser method in JS and returns the JSON-encoded result (or throws).
    /// `method` ∈ {"list","details","pages"}; `args` is encoded to the JS `args` object.
    func runParser(method: String, sourceId: String, args: [String: Any]) async throws -> String {
        await waitUntilLoaded()
        if let loadError { throw JSEngineError.notLoaded(loadError) }
        callSeq += 1
        let token = "c\(callSeq)"

        let argsData = try JSONSerialization.data(withJSONObject: args)
        let b64 = argsData.base64EncodedString()
        // `void` so the async fn's returned Promise isn't serialized back (evaluateJavaScript
        // can't serialize a Promise → "unsupported type"). The fn runs fire-and-forget and
        // posts its result via the nyoraResult handler.
        let driver = "void window.__runParser('\(token)','\(jsEscape(sourceId))','\(method)','\(b64)')"

        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<String, Error>) in
            pendingCalls[token] = cont
            webView.evaluateJavaScript(driver) { [weak self] _, error in
                // Only a *synchronous* dispatch error matters here; the real result arrives
                // asynchronously via nyoraResult. A JS throw inside the async fn is reported there.
                if let error {
                    Task { @MainActor [weak self] in
                        if let c = self?.pendingCalls.removeValue(forKey: token) {
                            c.resume(throwing: JSEngineError.js("dispatch failed: \(error.localizedDescription)"))
                        }
                    }
                }
            }
            // Safety timeout so a hung source can't leak a continuation forever.
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 45_000_000_000)
                if let c = self?.pendingCalls.removeValue(forKey: token) {
                    c.resume(throwing: JSEngineError.timeout)
                }
            }
        }
    }

    private func jsEscape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "'", with: "\\'")
    }

    func resolveHttp(id: String, ok: Bool, payload: String) {
        let b64 = payload.data(using: .utf8)?.base64EncodedString() ?? ""
        Task { @MainActor in
            webView?.evaluateJavaScript("window.__resolveHttp('\(id)', \(ok), '\(b64)')", completionHandler: nil)
        }
    }

    // MARK: Diagnostic

    func runDiagnostic(sourceId: String) async -> String {
        await waitUntilLoaded()
        var out: [String] = ["loadError = \(loadError ?? "nil")"]
        do {
            let json = try await runParser(method: "list", sourceId: sourceId, args: ["page": 1, "order": "POPULARITY", "filter": [:]])
            if let data = json.data(using: .utf8),
               let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                out.append("getListPage = \(arr.count) entries")
                if let first = arr.first, let t = first["title"] as? String { out.append("first = \(t)") }
            } else {
                out.append("getListPage raw = \(json.prefix(200))")
            }
        } catch {
            out.append("getListPage THREW: \(error.localizedDescription)")
        }
        out.append("\n--- console (\(consoleLog.count)) ---")
        out.append(contentsOf: consoleLog.suffix(20))
        return out.joined(separator: "\n")
    }

    // MARK: URLSession fetch (debug views)

    nonisolated func fetchDirect(url: String, method: String, domain: String, body: String?) async throws -> String {
        try await DirectFetch.text(url: url, method: method, domain: domain, body: body)
    }
}

// MARK: - WKNavigationDelegate

extension JSParserEngine: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let bundleURL = ParserOTA.bundleURL(),
              let bundleCode = try? String(contentsOf: bundleURL, encoding: .utf8) else {
            markLoaded(error: "parsers.bundle.js missing")
            return
        }
        webView.evaluateJavaScript(bundleCode + "\n; (typeof NyoraParsers !== 'undefined' && !!NyoraParsers.getParser)") { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let error {
                    self.markLoaded(error: "Bundle eval error: \(error.localizedDescription)")
                } else if (result as? Bool) == true {
                    self.markLoaded()
                } else {
                    self.markLoaded(error: "NyoraParsers global not reachable (result=\(String(describing: result)))")
                }
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        markLoaded(error: "Navigation failed: \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        markLoaded(error: "Provisional navigation failed: \(error.localizedDescription)")
    }
}

/// Over-the-air updater for the JS parser bundle + source catalog.
///
/// Built from `nyora-ota-parser` (`build.mjs` publishes `dist/manifest.json` +
/// `parsers.bundle.js` + `sources.json` to GitHub-raw). On launch we check the
/// manifest; if a newer version verifies by sha256 we download it into
/// `Application Support/Nyora/ota/`. It is **applied on the NEXT launch** and is
/// strictly **fallback-first**: with no (or incomplete) OTA payload the app uses
/// the copies bundled into the app at build time, so an unreachable/invalid
/// manifest can never break parsing. Bundle + catalog are taken together
/// (both-or-neither) so `NyoraParsers.getParser`'s embedded source list stays
/// consistent with the registered catalog.
enum ParserOTA {

    private static let manifestURLString = ProcessInfo.processInfo.environment["NYORA_OTA_MANIFEST"]
        ?? "https://hasan72341.github.io/nyora-ota-parsers/manifest.json"

    private static var dir: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Nyora/ota", isDirectory: true)
    }
    private static var bundleFile: URL { dir.appendingPathComponent("parsers.bundle.js") }
    private static var sourcesFile: URL { dir.appendingPathComponent("sources.json") }
    private static var versionFile: URL { dir.appendingPathComponent("version") }

    static var localVersion: Int {
        guard let s = try? String(contentsOf: versionFile, encoding: .utf8) else { return 0 }
        return Int(s.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    /// True only when a complete, versioned OTA payload is present.
    static var isActive: Bool {
        localVersion > 0
            && FileManager.default.fileExists(atPath: bundleFile.path)
            && FileManager.default.fileExists(atPath: sourcesFile.path)
    }

    /// Where to load the parser bundle from: OTA copy if active, else app bundle.
    static func bundleURL() -> URL? {
        isActive ? bundleFile : Bundle.main.url(forResource: "parsers.bundle", withExtension: "js")
    }

    /// Where to load the source catalog from: OTA copy if active, else app bundle.
    static func sourcesURL() -> URL? {
        isActive ? sourcesFile : Bundle.main.url(forResource: "parsers_sources", withExtension: "json")
    }

    /// Fire-and-forget background check; never throws, never blocks launch.
    static func checkForUpdate() {
        Task.detached(priority: .utility) {
            do { try await updateOnce() }
            catch { print("[OTA] check skipped: \(error.localizedDescription)") }
        }
    }

    /// Awaitable update check — throws on network/verification errors.
    static func checkForUpdateSync() async throws {
        try await updateOnce()
    }

    private struct Manifest: Decodable {
        struct Artifact: Decodable { let url: String; let sha256: String }
        let version: Int
        let bundle: Artifact
        let sources: Artifact
    }

    private static func updateOnce() async throws {
        guard let manifestURL = URL(string: manifestURLString) else { return }
        var req = URLRequest(url: manifestURL)
        req.timeoutInterval = 15
        let (mData, mResp) = try await URLSession.shared.data(for: req)
        guard (mResp as? HTTPURLResponse)?.statusCode == 200 else { return }
        let manifest = try JSONDecoder().decode(Manifest.self, from: mData)
        guard manifest.version > localVersion else {
            print("[OTA] parsers up to date (v\(manifest.version))"); return
        }

        let bundleData = try await download(manifest.bundle.url, expectedSha256: manifest.bundle.sha256)
        let sourcesData = try await download(manifest.sources.url, expectedSha256: manifest.sources.sha256)

        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try bundleData.write(to: bundleFile, options: .atomic)
        try sourcesData.write(to: sourcesFile, options: .atomic)
        try "\(manifest.version)".write(to: versionFile, atomically: true, encoding: .utf8)
        print("[OTA] parser bundle v\(manifest.version) downloaded — active on next launch")
    }

    private static func download(_ urlString: String, expectedSha256: String) async throws -> Data {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.timeoutInterval = 60
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        let sha = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        guard sha == expectedSha256 else {
            throw NSError(domain: "ParserOTA", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "sha256 mismatch"])
        }
        return data
    }
}
