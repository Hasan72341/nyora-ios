import SwiftUI

@main
struct NyoraApp: App {
    @StateObject private var model = AppModel()
    @AppStorage("appTheme") private var theme: AppTheme = .system
    @AppStorage("color_theme") private var colorTheme = "indigo"
    @AppStorage("wallpaper") private var wallpaper: WallpaperOption = .default
    @AppStorage("onboarding_done") private var onboardingDone = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        BackgroundRefresh.shared.registerLaunchHandler()
    }

    private var accentColor: Color {
        switch colorTheme {
        case "blue": return .blue
        case "teal": return .teal
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "pink": return .pink
        case "mint": return .mint
        default: return .indigo
        }
    }

    @ViewBuilder
    private var wallpaperBackground: some View {
        switch wallpaper {
        case .tinted:
            accentColor.opacity(0.06).ignoresSafeArea()
        case .warm:
            Color(red: 0.12, green: 0.09, blue: 0.07).ignoresSafeArea()
        case .cool:
            Color(red: 0.07, green: 0.09, blue: 0.13).ignoresSafeArea()
        case .dark:
            Color.black.ignoresSafeArea()
        case .default:
            Color(.systemGroupedBackground).ignoresSafeArea()
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                wallpaperBackground
                Group {
                    if let jsSource = DebugJSView.requestedSource {
                        DebugJSView(sourceId: jsSource)
                    } else if let cfURL = DebugCFView.requestedURL {
                        DebugCFView(url: cfURL)
                    } else if let source = DebugReaderLoader.requestedSource {
                        DebugReaderLoader(sourceName: source)
                    } else if let source = DebugDetailLoader.requestedSource {
                        DebugDetailLoader(sourceName: source)
                    } else if !onboardingDone {
                        WelcomeView()
                    } else {
                        AdaptiveRootView()
                    }
                }
            }
            .environmentObject(model)
            .tint(accentColor)
            .preferredColorScheme(theme.colorScheme)
            .cloudflareChallengeHost()
            .task {
                BackgroundRefresh.shared.attach(model: model)
                await UpdateNotifier.shared.requestAuthorization()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .background { BackgroundRefresh.shared.scheduleIfEnabled() }
            }
        }
    }
}

/// Bottom tab bar mirroring nyora-android's primary navigation
/// (Explore / Library / History / Updates / More), the native iOS way.
struct RootTabView: View {
    var body: some View {
        TabView {
            DiscoverView()
                .tabItem { Label("Discover", systemImage: "newspaper.fill") }

            LibraryView()
                .tabItem { Label("Library", systemImage: "books.vertical.fill") }

            ExploreView()
                .tabItem { Label("Explore", systemImage: "safari") }

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }

            MoreView()
                .tabItem { Label("More", systemImage: "ellipsis.circle.fill") }
        }
    }
}
