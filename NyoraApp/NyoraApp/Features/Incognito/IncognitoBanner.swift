import SwiftUI

/// Small inline banner indicating incognito mode is active (reading history is not being
/// recorded). Optional; place at the top of any screen. Renders nothing when incognito is off.
struct IncognitoBanner: View {
    @StateObject private var incognito = IncognitoState.shared

    var body: some View {
        if incognito.enabled {
            HStack(spacing: 8) {
                Image(systemName: "eyeglasses")
                Text("Private reading — your history won't be saved.")
                    .font(.caption)
                Spacer(minLength: 0)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

/// Self-contained entry view: a settings-style screen exposing the incognito toggle plus an
/// explainer. Reachable on its own (e.g. from More) in addition to the inline toggle snippet.
struct IncognitoSettingsView: View {
    @StateObject private var incognito = IncognitoState.shared

    var body: some View {
        List {
            Section {
                Toggle(isOn: $incognito.enabled) {
                    Label("Private reading", systemImage: "eyeglasses")
                }
            } footer: {
                Text("When private reading is on, your reading progress and history are not recorded. Bookmarks are unaffected.")
            }

            if incognito.enabled {
                Section { IncognitoBanner() }
            }
        }
        .navigationTitle("Private Reading")
        .navigationBarTitleDisplayMode(.inline)
    }
}
