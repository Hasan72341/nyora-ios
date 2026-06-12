import SwiftUI
import NyoraEngine

enum AppTheme: String, CaseIterable, Identifiable, SettingsOption {
    case system, light, dark
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self { case .system: return nil; case .light: return .light; case .dark: return .dark }
    }
}

/// Settings / about, plus entries into Stats and Categories.
struct MoreView: View {
    @EnvironmentObject var model: AppModel
    @AppStorage("readerMode") private var mode: ReaderMode = .paged
    @AppStorage("appTheme") private var theme: AppTheme = .system
    @AppStorage("translateTarget") private var targetLang = "English"
    @AppStorage("translateUseAI") private var useAI = true
    @StateObject private var incognito = IncognitoState.shared
    @State private var showClearConfirm = false

    var embedInStack = true

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
                    NavigationLink { AppearanceSettingsView() } label: {
                        Label("Appearance", systemImage: "paintbrush.fill")
                    }
                }

                Section("Reading") {
                    Picker("Default mode", selection: $mode) {
                        ForEach(ReaderMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    NavigationLink { ReaderSettingsView() } label: {
                        Label("Reader settings", systemImage: "textformat.size")
                    }
                }

                Section("Privacy") {
                    Toggle(isOn: $incognito.enabled) {
                        Label("Private reading", systemImage: "eyeglasses")
                    }
                }

                Section("Translation") {
                    Picker("Translate to", selection: $targetLang) {
                        ForEach(TranslationConfig.supportedLanguages.filter { $0 != "AUTO" }, id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    Toggle("Smart translation", isOn: $useAI)
                }

                Section("Library") {
                    NavigationLink { UpdatesView(embedInStack: false) } label: { Label("Updates", systemImage: "bell.fill") }
                    NavigationLink { BookmarksView(embedInStack: false) } label: { Label("Bookmarks", systemImage: "bookmark.fill") }
                    NavigationLink { StatsView() } label: { Label("Stats", systemImage: "chart.bar.fill") }
                    NavigationLink { MangaCategoriesView() } label: { Label("Categories", systemImage: "folder.fill") }
                    NavigationLink { DownloadsSettingsView() } label: { Label("Downloads", systemImage: "arrow.down.circle.fill") }
                    NavigationLink { LocalView(embedInStack: false) } label: { Label("On Device", systemImage: "folder.badge.plus.fill") }
                    NavigationLink { BackupSettingsView() } label: { Label("Backup & Restore", systemImage: "arrow.up.arrow.down.circle.fill") }
                    NavigationLink { SupabaseSyncSettingsView().environmentObject(model) } label: { Label("Cloud Sync", systemImage: "cloud.fill") }
                }

                Section("Tracking") {
                    NavigationLink { TrackerSettingsView() } label: {
                        Label("Update checks", systemImage: "bell.badge.fill")
                    }
                    NavigationLink { TrackingView() } label: {
                        Label("Manage accounts", systemImage: "person.2.fill")
                    }
                }

                Section("Services") {
                    NavigationLink { ServicesSettingsView() } label: {
                        Label("Services", systemImage: "puzzlepiece.fill")
                    }
                }

                Section("Content") {
                    NavigationLink { SourceManagementView() } label: {
                        Label("Sources", systemImage: "slider.horizontal.3")
                    }
                    NavigationLink { MangaSourcesSettingsView() } label: {
                        Label("Source settings", systemImage: "gearshape.2.fill")
                    }
                }

                Section("Network") {
                    NavigationLink { StorageNetworkSettingsView() } label: {
                        Label("Storage & Network", systemImage: "internaldrive.fill")
                    }
                }

                Section {
                    NavigationLink { AboutSettingsView() } label: {
                        Label("About Nyora", systemImage: "info.circle")
                    }
                }

                Section {
                    Button("Clear history", role: .destructive) {
                        showClearConfirm = true
                    }
                    .disabled(model.history.isEmpty)
                }
            }
            .navigationTitle("More")
            .confirmationDialog(
                "Clear all reading history?",
                isPresented: $showClearConfirm,
                titleVisibility: .visible
            ) {
                Button("Clear history", role: .destructive) { model.clearHistory() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This removes all your reading history. This cannot be undone.")
            }
    }
}
