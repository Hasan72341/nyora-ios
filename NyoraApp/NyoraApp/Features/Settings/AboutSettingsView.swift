import SwiftUI

/// SCREEN 9 — About. Mirrors pref_about.xml.
struct AboutSettingsView: View {
    @State private var checkingParsers = false
    @State private var parserCheckMessage: String? = nil

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "Version \(v)"
    }

    private var parserVersionText: String {
        let v = ParserOTA.localVersion
        return (ParserOTA.isActive && v > 0) ? "v\(v) (OTA)" : "Bundled"
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: DS.Spacing.sm) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 88, height: 88)
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous))
                    Text("Nyora").font(.system(.title2, design: .rounded).weight(.bold))
                    Text(version).font(.dsCaption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.md)
            }

            Section(header: Text("Content Updates")) {
                if let msg = parserCheckMessage {
                    Text(msg)
                        .font(.dsCaption)
                        .foregroundStyle(.secondary)
                }
                Button(action: checkForParserUpdates) {
                    HStack {
                        Label("Check for Updates", systemImage: "arrow.down.circle")
                        Spacer()
                        if checkingParsers {
                            ProgressView().scaleEffect(0.8)
                        }
                    }
                }
                .disabled(checkingParsers)
                if ParserOTA.isActive {
                    Text("Restart the app to load updated content sources.")
                        .font(.dsCaption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Link(destination: URL(string: "https://github.com")!) {
                    rowLabel(title: "View on GitHub", systemImage: "chevron.left.forwardslash.chevron.right", value: nil)
                }
                Link(destination: URL(string: "https://github.com")!) {
                    rowLabel(title: "Report a problem", systemImage: "exclamationmark.bubble", value: nil)
                }
            }

            Section {
                Text("Nyora — your manga library, everywhere. Available on iOS, Android, and macOS.")
                    .font(.dsCaption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func checkForParserUpdates() {
        checkingParsers = true
        parserCheckMessage = nil
        Task {
            do {
                try await ParserOTA.checkForUpdateSync()
                let v = ParserOTA.localVersion
                parserCheckMessage = ParserOTA.isActive
                    ? "Content sources updated. Restart to apply."
                    : "Content sources are up to date."
            } catch {
                parserCheckMessage = "Couldn't check for updates. Please try again later."
            }
            checkingParsers = false
        }
    }
}
