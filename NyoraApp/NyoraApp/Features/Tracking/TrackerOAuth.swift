import Foundation
import AuthenticationServices
import CryptoKit
import UIKit

/// The custom URL scheme registered for OAuth callbacks. The orchestrator must add a
/// matching `CFBundleURLTypes` entry to Info.plist (scheme `nyora`). See the wiring notes.
let kNyoraOAuthScheme = "nyora"

/// Which tracker an in-flight OAuth callback belongs to. The callback host (`nyora://<host>`)
/// disambiguates between services so `.onOpenURL` can route to the right client.
enum TrackerService: String, CaseIterable, Identifiable, Codable {
    case aniList
    case myAnimeList
    case kitsu
    case shikimori

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .aniList: return "AniList"
        case .myAnimeList: return "MyAnimeList"
        case .kitsu: return "Kitsu"
        case .shikimori: return "Shikimori"
        }
    }

    /// The host portion of the `nyora://` callback URL used by each service.
    var callbackHost: String {
        switch self {
        case .aniList: return "anilist-auth"
        case .myAnimeList: return "mal-auth"
        case .kitsu: return "kitsu-auth"
        case .shikimori: return "shikimori-auth"
        }
    }

    var redirectURI: String { "\(kNyoraOAuthScheme)://\(callbackHost)" }
}

/// Errors from the OAuth dance.
enum TrackerOAuthError: LocalizedError {
    case cancelled
    case missingCode
    case http(Int)
    case decoding
    case notAuthenticated
    case missingClientID(String)
    case server(String)

    var errorDescription: String? {
        switch self {
        case .cancelled: return "Sign-in was cancelled."
        case .missingCode: return "The login callback didn’t contain an authorization code/token."
        case .http(let c): return "Request failed (HTTP \(c))."
        case .decoding: return "Couldn’t read the service’s response."
        case .notAuthenticated: return "Not signed in to this service."
        case .missingClientID(let s): return "\(s) client ID is not configured. See TrackerOAuth.swift."
        case .server(let m): return m
        }
    }
}

/// PKCE pair used by the MyAnimeList flow.
struct PKCEPair {
    let verifier: String
    /// MAL uses the `plain` challenge method, so challenge == verifier.
    var challengePlain: String { verifier }

    static func generate() -> PKCEPair {
        var bytes = [UInt8](repeating: 0, count: 50)
        _ = SecKeyboardRandom(&bytes)
        let verifier = Data(bytes).base64URLEncodedString()
        return PKCEPair(verifier: verifier)
    }
}

/// Wraps `SecRandomCopyBytes` so callers stay terse.
@discardableResult
private func SecKeyboardRandom(_ bytes: inout [UInt8]) -> Int32 {
    return SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
}

extension Data {
    /// Base64-URL without padding (RFC 7636 / RFC 4648 §5).
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

/// Drives `ASWebAuthenticationSession` for browser-based OAuth flows. `@MainActor` because
/// the session must start from the main thread and needs a presentation anchor.
@MainActor
final class TrackerOAuth: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = TrackerOAuth()

    private var activeSession: ASWebAuthenticationSession?

    /// Present the authorization URL in a system web sheet and resume with the full callback
    /// URL once the user finishes. `callbackScheme` should be `nyora`.
    func authorize(url: URL, callbackScheme: String = kNyoraOAuthScheme) async throws -> URL {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme
            ) { callbackURL, error in
                if let error {
                    let ns = error as NSError
                    if ns.domain == ASWebAuthenticationSessionError.errorDomain,
                       ns.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        cont.resume(throwing: TrackerOAuthError.cancelled)
                    } else {
                        cont.resume(throwing: error)
                    }
                    return
                }
                guard let callbackURL else {
                    cont.resume(throwing: TrackerOAuthError.missingCode)
                    return
                }
                cont.resume(returning: callbackURL)
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.activeSession = session
            if !session.start() {
                cont.resume(throwing: TrackerOAuthError.cancelled)
            }
        }
    }

    // MARK: ASWebAuthenticationPresentationContextProviding

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes
        let window = scenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        return window ?? ASPresentationAnchor()
    }
}

/// Helpers for extracting query/fragment params from a callback URL.
extension URL {
    /// Query parameter by name (e.g. `?code=...`).
    func queryValue(_ name: String) -> String? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == name }?.value
    }

    /// Fragment parameter by name (e.g. AniList's `#access_token=...`).
    func fragmentValue(_ name: String) -> String? {
        guard let fragment = URLComponents(url: self, resolvingAgainstBaseURL: false)?.fragment
        else { return nil }
        for pair in fragment.split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1).map(String.init)
            if kv.count == 2, kv[0] == name {
                return kv[1].removingPercentEncoding ?? kv[1]
            }
        }
        return nil
    }
}
