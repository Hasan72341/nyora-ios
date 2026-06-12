import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage("color_theme") private var colorTheme = "indigo"
    @AppStorage("appTheme") private var theme: AppTheme = .system
    @AppStorage("wallpaper") private var wallpaper: WallpaperOption = .default
    // Manga list
    @AppStorage("list_mode_2") private var listMode: ListModeOption = .grid
    @AppStorage("grid_size") private var gridSize: Double = 100
    @AppStorage("quick_filter") private var quickFilter = true
    @AppStorage("progress_indicators") private var progressIndicators: ProgressIndicatorOption = .percentRead
    @AppStorage("manga_list_badges") private var listBadges = "favorites,saved"
    // Details
    @AppStorage("description_collapse") private var descriptionCollapse = true
    @AppStorage("pages_tab") private var pagesTab = true
    @AppStorage("details_tab") private var detailsTab: DetailsTabOption = .lastUsed
    // Main screen
    @AppStorage("search_suggest_types") private var searchSuggest = "recent,queries,sources"
    @AppStorage("main_fab") private var mainFab = true
    @AppStorage("nav_labels") private var navLabels = false
    @AppStorage("nav_pinned") private var navPinned = false
    @AppStorage("exit_confirm") private var exitConfirm = false
    @AppStorage("dynamic_shortcuts") private var dynamicShortcuts = true
    // Privacy
    @AppStorage("protect_app") private var protectApp = false
    @AppStorage("screenshots_policy") private var screenshotsPolicy: ScreenshotsPolicyOption = .allow

    private let accentColors: [(String, Color)] = [
        ("indigo", .indigo), ("blue", .blue), ("teal", .teal), ("green", .green),
        ("orange", .orange), ("red", .red), ("pink", .pink), ("mint", .mint)
    ]

    var body: some View {
        List {
            Section { SettingsHeader("Appearance", systemImage: "paintbrush.fill") }

            Section("Accent Color") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Spacing.md) {
                        ForEach(accentColors, id: \.0) { name, color in
                            Button { colorTheme = name } label: {
                                Circle()
                                    .fill(color)
                                    .frame(width: 34, height: 34)
                                    .overlay(
                                        Circle().strokeBorder(Color.accentColor, lineWidth: colorTheme == name ? 3 : 0)
                                    )
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.caption.weight(.bold)).foregroundStyle(.white)
                                            .opacity(colorTheme == name ? 1 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, DS.Spacing.xs)
                }
            }

            Section {
                SingleSelectRow(title: "Theme", selection: $theme)
                SingleSelectRow(title: "Wallpaper", selection: $wallpaper)
                ActionRow(title: "Language", systemImage: nil, summary: "Open system language settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }
            }

            Section("Manga list") {
                SingleSelectRow(title: "List mode", selection: $listMode)
                SliderRow(title: "Grid size", range: 50...150, step: 5, unit: "%", value: $gridSize)
                ToggleRow(title: "Show quick filters", isOn: $quickFilter)
                SingleSelectRow(title: "Show reading indicators", selection: $progressIndicators)
                MultiSelectRow<ListBadgeOption>(title: "Badges in lists", rawSelection: $listBadges)
            }

            Section("Details") {
                ToggleRow(title: "Collapse long description", isOn: $descriptionCollapse)
                ToggleRow(title: "Show pages thumbnails", isOn: $pagesTab)
                SingleSelectRow(title: "Default tab", selection: $detailsTab)
                    .disabled(!pagesTab)
            }

            Section("Main screen") {
                MultiSelectRow<SearchSuggestionOption>(title: "Search suggestions", rawSelection: $searchSuggest)
                ToggleRow(title: "Main screen FAB", isOn: $mainFab)
                ToggleRow(title: "Show labels in navigation bar", isOn: $navLabels)
                ToggleRow(title: "Pin navigation UI", isOn: $navPinned)
                ToggleRow(title: "Exit confirmation", isOn: $exitConfirm)
                ToggleRow(title: "History shortcuts", isOn: $dynamicShortcuts)
            }

            Section {
                ToggleRow(title: "Protect application", summary: "Require Face ID / Touch ID to open", isOn: $protectApp)
                SingleSelectRow(title: "Screenshots policy", footer: "iOS cannot fully block screenshots; this is best-effort.", selection: $screenshotsPolicy)
            } header: { Text("Privacy") }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}
