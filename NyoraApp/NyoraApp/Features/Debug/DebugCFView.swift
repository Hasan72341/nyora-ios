import SwiftUI

/// Verification-only: `UITEST_CF=<url>` fetches a URL through JSParserEngine's URLSession
/// (exercises the Cloudflare solver path if challenged) and shows the result.
struct DebugCFView: View {
    let url: String
    @State private var status = "Fetching…"
    @State private var preview = ""
    @State private var ok = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Label(ok ? "PASSED" : "…", systemImage: ok ? "checkmark.seal.fill" : "hourglass")
                    .font(.title2.bold())
                    .foregroundStyle(ok ? .green : .secondary)
                Text(url).font(.caption.monospaced()).foregroundStyle(.secondary)
                Text(status).font(.headline)
                Text(preview).font(.caption.monospaced()).textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .task {
            do {
                let full = try await JSParserEngine.shared.fetchDirect(
                    url: url, method: "GET", domain: URL(string: url)?.host ?? "", body: nil
                )
                let text = String(full.prefix(600))
                let looksLikeChallenge = text.localizedCaseInsensitiveContains("just a moment")
                ok = !looksLikeChallenge && !full.isEmpty
                status = ok ? "Got \(full.count) chars of real content" : "Still challenged"
                preview = text
            } catch {
                status = "ERROR: \(error.localizedDescription)"
            }
        }
    }

    static var requestedURL: String? { ProcessInfo.processInfo.environment["UITEST_CF"] }
}
