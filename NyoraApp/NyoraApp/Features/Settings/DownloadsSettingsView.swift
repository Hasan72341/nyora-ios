import SwiftUI

/// SCREEN 5 — Downloads. Mirrors pref_downloads.xml. Android-only ignore_dose omitted.
struct DownloadsSettingsView: View {
    @AppStorage("downloads_format") private var format: DownloadFormatOption = .automatic
    @AppStorage("downloads_metered_network") private var metered: MeteredNetworkOption = .ask
    @AppStorage("pages_dir_ask") private var askDir = true
    @State private var showPagesDirPicker = false
    @State private var pagesDirPath: String? = resolveBookmarkedFolderPath("pages_save_dir_bookmark")

    var body: some View {
        List {
            Section { SettingsHeader("Downloads", systemImage: "arrow.down.circle.fill") }

            Section {
                NavigationLink { LocalView() } label: {
                    rowLabel(title: "Local manga directories", systemImage: "folder", value: nil)
                }
                NavigationLink { DownloadsView() } label: {
                    rowLabel(title: "Manga save location", systemImage: "externaldrive", value: nil)
                }
                SingleSelectRow(title: "Preferred download format", selection: $format)
                SingleSelectRow(title: "Download over cellular", selection: $metered)
            }

            Section {
                InfoRow(text: "Downloads run in the background while the app is open. Large libraries may take time to sync.")
            }

            Section("Pages saving") {
                ActionRow(title: "Default page save directory",
                          systemImage: "square.and.arrow.down",
                          summary: pagesDirPath ?? "Not set — tap to choose a folder") {
                    showPagesDirPicker = true
                }
                ToggleRow(title: "Ask for destination directory every time", isOn: $askDir)
            }
        }
        .navigationTitle("Downloads")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPagesDirPicker) {
            FolderPicker(bookmarkKey: "pages_save_dir_bookmark") { url in
                pagesDirPath = resolveBookmarkedFolderPath("pages_save_dir_bookmark") ?? url.lastPathComponent
            }
            .ignoresSafeArea()
        }
    }
}
