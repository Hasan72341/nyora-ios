import SwiftUI

/// SCREEN 4a — Data removal. Mirrors pref_data_cleanup.xml. Each action shows a
/// confirmation dialog before clearing, then performs the real removal and reports a result.
struct DataRemovalSettingsView: View {
    @EnvironmentObject private var model: AppModel
    @AppStorage("chapters_clear_auto") private var autoDeleteRead = false
    @State private var pending: (title: String, message: String, action: () async -> String)?
    @State private var showConfirm = false
    @State private var working = false
    @State private var result: String?

    private func confirm(_ title: String, _ message: String, _ action: @escaping () async -> String) {
        pending = (title, message, action)
        showConfirm = true
    }

    private func run(_ action: @escaping () async -> String) {
        working = true
        Task {
            let message = await action()
            await MainActor.run {
                result = message
                working = false
            }
        }
    }

    var body: some View {
        List {
            Section { SettingsHeader("Data removal", systemImage: "trash") }

            Section {
                ActionRow(title: "Clear search history") {
                    confirm("Clear search history", "Remove all saved search queries?") {
                        CacheManager.clearSearchHistory()
                        return "Search history cleared"
                    }
                }
                ActionRow(title: "Clear updates feed") {
                    confirm("Clear updates feed", "Remove all entries from the updates feed?") {
                        await model.clearUpdatesFeed()
                        return "Updates feed cleared"
                    }
                }
                ActionRow(title: "Clear thumbnails cache") {
                    confirm("Clear thumbnails cache", "Remove cached cover thumbnails?") {
                        CacheManager.clearThumbnailsCache()
                        return "Thumbnails cache cleared"
                    }
                }
                ActionRow(title: "Clear pages cache") {
                    confirm("Clear pages cache", "Remove cached reader pages?") {
                        CacheManager.clearPagesCache()
                        return "Pages cache cleared"
                    }
                }
                ActionRow(title: "Clear network cache") {
                    confirm("Clear network cache", "Remove cached network responses?") {
                        CacheManager.clearNetworkCache()
                        return "Network cache cleared"
                    }
                }
                ActionRow(title: "Clear cookies") {
                    confirm("Clear cookies", "Remove all stored cookies?") {
                        CacheManager.clearCookies()
                        return "Cookies cleared"
                    }
                }
                ActionRow(title: "Clear browser data") {
                    confirm("Clear browser data", "Remove all web view browsing data?") {
                        await CacheManager.clearBrowserData()
                        return "Browser data cleared"
                    }
                }
            }

            Section {
                ActionRow(title: "Clear database", role: .destructive) {
                    confirm("Clear database", "This permanently removes your library, history and bookmarks. This cannot be undone.") {
                        await model.resetLibraryDatabase()
                        return "Library database cleared"
                    }
                }
                ActionRow(title: "Delete read chapters", role: .destructive) {
                    confirm("Delete read chapters", "Delete downloaded chapters you have already read?") {
                        let n = await CacheManager.deleteReadChapters(model: model)
                        return n == 0 ? "No read downloads to delete" : "Deleted \(n) read chapter\(n == 1 ? "" : "s")"
                    }
                }
                ToggleRow(title: "Delete read chapters automatically", summary: "Runs when the app starts", isOn: $autoDeleteRead)
            }
        }
        .navigationTitle("Data removal")
        .navigationBarTitleDisplayMode(.inline)
        .disabled(working)
        .overlay {
            if working { ProgressView().controlSize(.large) }
        }
        .confirmationDialog(pending?.title ?? "", isPresented: $showConfirm, titleVisibility: .visible) {
            Button(pending?.title ?? "Confirm", role: .destructive) {
                if let action = pending?.action { run(action) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(pending?.message ?? "")
        }
        .alert("Done", isPresented: Binding(get: { result != nil }, set: { if !$0 { result = nil } })) {
            Button("OK", role: .cancel) { result = nil }
        } message: {
            Text(result ?? "")
        }
    }
}
