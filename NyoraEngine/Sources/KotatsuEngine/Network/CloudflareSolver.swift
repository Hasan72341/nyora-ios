import Foundation

/// Solves Cloudflare "Just a moment…" interactive challenges by running them in a real
/// (headless) WebKit instance, then handing the resulting `cf_clearance` cookie back to the
/// plain-URLSession `WebClient` so subsequent requests pass the WAF.
///
/// Available on iOS (WebKit + UIKit). On platforms without UIKit (the macOS test host) the
/// solver is a no-op that reports failure, so CF-walled sources simply error there — the
/// engine still builds and non-CF sources are unaffected.
public protocol CloudflareSolving: Sendable {
    /// Attempt to clear the challenge guarding `url` using `userAgent`. Returns true once a
    /// clearance cookie is obtained and synced into `HTTPCookieStorage.shared`.
    func solve(url: URL, userAgent: String) async -> Bool
}

#if canImport(WebKit) && canImport(UIKit)
import WebKit
import UIKit

@MainActor
public final class CloudflareSolver: NSObject, CloudflareSolving {
    public static let shared = CloudflareSolver()

    private var webView: WKWebView?
    private var hiddenWindow: UIWindow?
    private var inFlight: Set<String> = []
    private var waiters: [String: [CheckedContinuation<Bool, Never>]] = [:]

    private let challengeTimeout: TimeInterval = 25
    private let pollInterval: UInt64 = 700_000_000 // 0.7s

    public func solve(url: URL, userAgent: String) async -> Bool {
        let host = url.host ?? url.absoluteString
        // Coalesce concurrent solves for the same host into one challenge run.
        if inFlight.contains(host) {
            return await withCheckedContinuation { waiters[host, default: []].append($0) }
        }
        inFlight.insert(host)
        let ok = await runChallenge(url: url, userAgent: userAgent)
        inFlight.remove(host)
        for w in waiters[host] ?? [] { w.resume(returning: ok) }
        waiters[host] = nil
        return ok
    }

    private func runChallenge(url: URL, userAgent: String) async -> Bool {
        let wv = ensureWebView(userAgent: userAgent)
        wv.customUserAgent = userAgent      // cf_clearance is bound to the UA that solved it
        wv.load(URLRequest(url: url))

        let deadline = Date().addingTimeInterval(challengeTimeout)
        while Date() < deadline {
            try? await Task.sleep(nanoseconds: pollInterval)
            if await isCleared(host: url.host) {
                await syncCookiesToShared()
                return true
            }
        }
        // Last-chance sync (some sites set clearance without changing the title in time).
        await syncCookiesToShared()
        return await hasClearanceCookie(host: url.host)
    }

    /// Cleared when a `cf_clearance` cookie exists for the host, or the page title is no
    /// longer the interstitial.
    private func isCleared(host: String?) async -> Bool {
        if await hasClearanceCookie(host: host) { return true }
        guard let wv = webView else { return false }
        let title = (try? await wv.evaluateJavaScript("document.title")) as? String
        if let t = title, !t.isEmpty, !t.localizedCaseInsensitiveContains("just a moment"),
           !t.localizedCaseInsensitiveContains("attention required") {
            return true
        }
        return false
    }

    private func hasClearanceCookie(host: String?) async -> Bool {
        let cookies = await allWebViewCookies()
        return cookies.contains { $0.name == "cf_clearance" }
    }

    private func allWebViewCookies() async -> [HTTPCookie] {
        guard let store = webView?.configuration.websiteDataStore.httpCookieStore else { return [] }
        return await withCheckedContinuation { cont in
            store.getAllCookies { cont.resume(returning: $0) }
        }
    }

    /// Copy every WebKit cookie into the shared store that `WebClient`'s URLSession reads.
    private func syncCookiesToShared() async {
        let cookies = await allWebViewCookies()
        for cookie in cookies { HTTPCookieStorage.shared.setCookie(cookie) }
    }

    private func ensureWebView(userAgent: String) -> WKWebView {
        if let wv = webView { return wv }
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()   // persistent, shares cookies across solves
        let wv = WKWebView(frame: CGRect(x: 0, y: 0, width: 320, height: 480), configuration: config)
        wv.customUserAgent = userAgent

        // A WebView needs to be in a window for the challenge JS (timers/rendering) to run.
        // Use a tiny, transparent, below-normal window so it never disturbs the app UI.
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) ?? (UIApplication.shared.connectedScenes.first as? UIWindowScene) {
            let window = UIWindow(windowScene: scene)
            window.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
            window.windowLevel = UIWindow.Level(rawValue: UIWindow.Level.normal.rawValue - 1)
            window.alpha = 0.01
            window.isUserInteractionEnabled = false
            let vc = UIViewController()
            vc.view.addSubview(wv)
            window.rootViewController = vc
            window.isHidden = false
            self.hiddenWindow = window
        }
        self.webView = wv
        return wv
    }
}

#else

/// Stub for platforms without WebKit/UIKit (e.g. the macOS test host).
public struct CloudflareSolver: CloudflareSolving {
    public static let shared = CloudflareSolver()
    public func solve(url: URL, userAgent: String) async -> Bool { false }
}

#endif
