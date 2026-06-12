import SwiftUI

/// SCREEN 2 — Manga sources (title "Remote sources"). Mirrors pref_sources.xml.
struct MangaSourcesSettingsView: View {
    @AppStorage("sources_sort_order") private var sortOrder: SourcesSortOption = .alphabetical
    @AppStorage("sources_grid") private var grid = true
    @AppStorage("sources_enabled_all") private var enableAll = false
    @AppStorage("no_nsfw") private var noNsfw = true
    @AppStorage("incognito_nsfw") private var incognitoNsfw: IncognitoNsfwOption = .ask
    @AppStorage("mirror_switching") private var mirrorSwitching = false

    var body: some View {
        List {
            Section { SettingsHeader("Content Sources", systemImage: "globe") }

            Section {
                SingleSelectRow(title: "Sort order", selection: $sortOrder)
                ToggleRow(title: "Show in grid view", isOn: $grid)
                NavigationLink { SourceManagementView() } label: {
                    rowLabel(title: "Browse sources", systemImage: "slider.horizontal.3", value: nil)
                }
                ToggleRow(title: "Enable all sources", isOn: $enableAll)
                NavigationLink { SourceManagementView() } label: {
                    rowLabel(title: "All sources", systemImage: "square.grid.2x2", value: nil)
                }
                NavigationLink { SourceManagementView() } label: {
                    rowLabelContent(title: "Available sources", systemImage: "shippingbox", summary: "Browse and enable content sources")
                }
            }

            Section("Content") {
                ToggleRow(title: "Hide mature content", isOn: $noNsfw)
                SingleSelectRow(title: "Private mode for mature content", selection: $incognitoNsfw)
                ToggleRow(title: "Alternate sources", isOn: $mirrorSwitching)
                ActionRow(title: "Open links in app", systemImage: "link", summary: "Open manga links directly in Nyora") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }
            }
        }
        .navigationTitle("Content Sources")
        .navigationBarTitleDisplayMode(.inline)
    }
}
