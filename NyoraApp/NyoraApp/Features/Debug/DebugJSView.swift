import SwiftUI

/// Verification-only: `UITEST_JSDEBUG=<SOURCE_ID>` runs a self-contained probe through the
/// JS engine (checks NyoraParsers/__context globals, a live httpGet, and getListPage) and
/// renders the full report on screen so the bridge can be diagnosed from one screenshot.
struct DebugJSView: View {
    let sourceId: String
    @State private var report = "Running diagnostic…"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("JS Engine Diagnostic — \(sourceId)")
                    .font(.headline)
                Text(report)
                    .font(.system(size: 11, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .task {
            report = await JSParserEngine.shared.runDiagnostic(sourceId: sourceId)
        }
    }

    static var requestedSource: String? {
        ProcessInfo.processInfo.environment["UITEST_JSDEBUG"]
    }
}
