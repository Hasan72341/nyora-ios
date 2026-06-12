import SwiftUI

/// Settings root — entry point from MoreView. Mirrors nyora-android's top-level
/// settings tree: 9 nav rows, each pushing a dedicated screen. Flat surfaces with
/// gradient accents (no purple). Keys match Android pref keys for parity.
struct SettingsView: View {
    /// When `true` (iPhone tab path) the view supplies its own `NavigationStack`.
    /// On iPad the split-view detail column owns the stack, so this is `false`.
    var embedInStack = true

    @EnvironmentObject private var model: AppModel

    var body: some View {
        if embedInStack {
            NavigationStack { content }
        } else {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
            List {
                Section {
                    SettingsHeader("Settings", subtitle: "Nyora", systemImage: "gearshape.fill")
                }

                Section {
                    NavigationLink { AppearanceSettingsView() } label: {
                        rowLabel(title: "Appearance", systemImage: "paintbrush.fill", value: nil)
                    }
                    NavigationLink { MangaSourcesSettingsView() } label: {
                        rowLabel(title: "Manga sources", systemImage: "globe", value: nil)
                    }
                    NavigationLink { ReaderSettingsScreen() } label: {
                        rowLabel(title: "Reader settings", systemImage: "book.fill", value: nil)
                    }
                    NavigationLink { StorageNetworkSettingsView() } label: {
                        rowLabel(title: "Storage and network", systemImage: "internaldrive.fill", value: nil)
                    }
                    NavigationLink { DownloadsSettingsView() } label: {
                        rowLabel(title: "Downloads", systemImage: "arrow.down.circle.fill", value: nil)
                    }
                    NavigationLink { SupabaseSyncSettingsView().environmentObject(model) } label: {
                        rowLabel(title: "Account & Sync", systemImage: "person.crop.circle.fill", value: "Cloud sync")
                    }
                    NavigationLink { TrackerSettingsView() } label: {
                        rowLabel(title: "Check for new chapters", systemImage: "bell.fill", value: nil)
                    }
                    NavigationLink { ServicesSettingsView() } label: {
                        rowLabel(title: "Services", systemImage: "puzzlepiece.fill", value: nil)
                    }
                    NavigationLink { BackupSettingsView() } label: {
                        rowLabel(title: "Backup and restore", systemImage: "arrow.up.arrow.down.circle.fill", value: nil)
                    }
                    NavigationLink { AboutSettingsView() } label: {
                        rowLabel(title: "About", systemImage: "info.circle.fill", value: nil)
                    }
                }
            }
            .navigationTitle("Settings")
    }
}

#Preview { SettingsView() }
