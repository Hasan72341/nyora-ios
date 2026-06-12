import SwiftUI
import WebKit
import NyoraEngine

/// Visible WebView that renders a Cloudflare managed/Turnstile challenge so it can clear
/// (interactively if needed). Polls for the `cf_clearance` cookie; once present, syncs all
/// cookies into the shared store (which the engine's URLSession reads) and finishes.
struct CloudflareChallengeView: UIViewRepresentable {
    let url: URL
    let userAgent: String
    let onCleared: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(host: url.host, onCleared: onCleared) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.customUserAgent = userAgent
        wv.navigationDelegate = context.coordinator
        context.coordinator.webView = wv
        wv.load(URLRequest(url: url))
        context.coordinator.startPolling()
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
        let host: String?
        let onCleared: () -> Void
        private var done = false
        private var timer: Timer?

        init(host: String?, onCleared: @escaping () -> Void) {
            self.host = host; self.onCleared = onCleared
        }

        func startPolling() {
            timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
                Task { @MainActor in await self?.check() }
            }
        }

        @MainActor private func check() async {
            guard !done, let store = webView?.configuration.websiteDataStore.httpCookieStore else { return }
            let cookies = await withCheckedContinuation { (c: CheckedContinuation<[HTTPCookie], Never>) in
                store.getAllCookies { c.resume(returning: $0) }
            }
            guard cookies.contains(where: { $0.name == "cf_clearance" }) else { return }
            done = true
            timer?.invalidate(); timer = nil
            for cookie in cookies { HTTPCookieStorage.shared.setCookie(cookie) }
            onCleared()
        }

        deinit { timer?.invalidate() }
    }
}

/// Sheet wrapper presented by the host modifier.
struct CloudflareChallengeSheet: View {
    let request: CloudflareInteractive.Request
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("Complete the verification if prompted. This clears automatically.")
                    .font(.footnote).foregroundStyle(.secondary)
                    .padding(.horizontal).padding(.top, 8)
                CloudflareChallengeView(url: request.url, userAgent: request.userAgent) {
                    CloudflareInteractive.shared.finish(success: true)
                    dismiss()
                }
            }
            .navigationTitle("Verifying…")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        CloudflareInteractive.shared.finish(success: false)
                        dismiss()
                    }
                }
            }
            .interactiveDismissDisabled(true)
        }
    }
}

/// Attach near the app root: registers as the interactive CF presenter and shows the sheet
/// whenever the engine needs a managed challenge solved.
struct CloudflareChallengeHost: ViewModifier {
    @StateObject private var coordinator = CloudflareInteractive.shared

    func body(content: Content) -> some View {
        content
            .onAppear { CloudflareInteractive.shared.isPresenterAttached = true }
            .sheet(item: Binding(
                get: { coordinator.pending },
                set: { if $0 == nil { /* dismissed elsewhere */ } }
            )) { req in
                CloudflareChallengeSheet(request: req)
            }
    }
}

extension View {
    func cloudflareChallengeHost() -> some View { modifier(CloudflareChallengeHost()) }
}
