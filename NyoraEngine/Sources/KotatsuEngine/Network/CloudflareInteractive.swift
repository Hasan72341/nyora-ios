import Foundation

/// Bridges an unsolved (managed / Turnstile) Cloudflare challenge from the non-UI engine up
/// to the app, which presents a *visible* WebView so the challenge can render and clear
/// (the standard manga-reader approach to managed CF). The app attaches a presenter by
/// observing `pending`; when no presenter is attached (engine tests, headless runs),
/// interactive solving is unavailable and returns false immediately.
@MainActor
public final class CloudflareInteractive: ObservableObject {
    public static let shared = CloudflareInteractive()
    private init() {}

    public struct Request: Identifiable, Equatable {
        public let id = UUID()
        public let url: URL
        public let userAgent: String
        public static func == (a: Request, b: Request) -> Bool { a.id == b.id }
    }

    /// The app observes this and presents a challenge sheet when non-nil.
    @Published public private(set) var pending: Request?
    /// Set true by the app's challenge host so the engine knows interactive solving is possible.
    public var isPresenterAttached = false

    private var continuation: CheckedContinuation<Bool, Never>?

    /// Engine entry point: called after the headless solver couldn't clear a challenge.
    /// Suspends until the app's sheet reports clearance or cancellation.
    public func solveInteractively(url: URL, userAgent: String) async -> Bool {
        guard isPresenterAttached, pending == nil else { return false }
        return await withCheckedContinuation { cont in
            continuation = cont
            pending = Request(url: url, userAgent: userAgent)
        }
    }

    /// App entry point: called by the challenge sheet when the challenge clears or the user
    /// cancels. Resumes the suspended engine request.
    public func finish(success: Bool) {
        let cont = continuation
        continuation = nil
        pending = nil
        cont?.resume(returning: success)
    }
}
