import SwiftUI

/// Root navigation container that adapts to the active horizontal size class.
///
/// - Compact width (iPhone portrait): uses the existing `RootTabView` bottom tab bar.
/// - Regular width (iPad, landscape): uses a `NavigationSplitView` with a sidebar
///   listing the same primary destinations as the tab bar plus utility screens,
///   mirroring the Nyora Web information architecture.
///
/// Both paths reuse the exact same destination views, so behaviour stays in sync.
struct AdaptiveRootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .regular {
            AdaptiveSplitView()
        } else {
            RootTabView()
        }
    }
}

/// All destinations available in the app, mirrored from Nyora Web.
private enum AdaptiveDestination: String, CaseIterable, Identifiable {
    case explore
    case discover
    case library
    case history
    case bookmarks
    case updates
    case local
    case tracking
    case stats
    case downloads
    case more

    var id: String { rawValue }

    var title: String {
        switch self {
        case .explore: return "Explore"
        case .discover: return "Discover"
        case .library: return "Library"
        case .history: return "History"
        case .bookmarks: return "Bookmarks"
        case .updates: return "Updates"
        case .local: return "On Device"
        case .tracking: return "Tracking"
        case .stats: return "Stats"
        case .downloads: return "Downloads"
        case .more: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .explore: return "safari"
        case .discover: return "newspaper.fill"
        case .library: return "books.vertical.fill"
        case .history: return "clock.arrow.circlepath"
        case .bookmarks: return "bookmark.fill"
        case .updates: return "bell.fill"
        case .local: return "folder.fill"
        case .tracking: return "externaldrive.fill"
        case .stats: return "chart.bar.fill"
        case .downloads: return "arrow.down.circle.fill"
        case .more: return "gearshape.fill"
        }
    }
}

/// Sidebar + detail layout for regular-width contexts (iPad / landscape).
private struct AdaptiveSplitView: View {
    @State private var selection: AdaptiveDestination? = .discover
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $selection) {
                Section {
                    NavigationLink(value: AdaptiveDestination.discover) {
                        Label("Discover", systemImage: "newspaper.fill")
                    }
                    NavigationLink(value: AdaptiveDestination.explore) {
                        Label("Explore", systemImage: "safari")
                    }
                }
                
                Section("Library") {
                    ForEach([AdaptiveDestination.library, .history, .bookmarks, .updates, .local]) { dest in
                        NavigationLink(value: dest) {
                            Label(dest.title, systemImage: dest.systemImage)
                        }
                    }
                }

                Section("Utilities") {
                    ForEach([AdaptiveDestination.tracking, .stats, .downloads, .more]) { dest in
                        NavigationLink(value: dest) {
                            Label(dest.title, systemImage: dest.systemImage)
                        }
                    }
                }
            }
            .navigationTitle("Nyora")
            .listStyle(.sidebar)
        } detail: {
            let active = selection ?? .discover
            NavigationStack {
                detailView(for: active)
            }
            .id(active)
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func detailView(for destination: AdaptiveDestination) -> some View {
        switch destination {
        case .explore: ExploreView(embedInStack: false)
        case .discover: DiscoverView(embedInStack: false)
        case .library: LibraryView(embedInStack: false)
        case .history: HistoryView(embedInStack: false)
        case .bookmarks: BookmarksView(embedInStack: false)
        case .updates: UpdatesView(embedInStack: false)
        case .local: LocalView(embedInStack: false)
        case .tracking: TrackingView()
        case .stats: StatsView()
        case .downloads: DownloadsView(embedInStack: false)
        case .more: MoreView(embedInStack: false)
        }
    }
}
