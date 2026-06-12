import SwiftUI

// MARK: - All ListPreference / MultiSelect option enums for the Settings tree.
//
// Each is String-backed for @AppStorage parity with Android entryValues where
// reasonable. Conforms to SettingsOption so it can drive SingleSelect/MultiSelect
// screens directly.

// Appearance
enum WallpaperOption: String, SettingsOption {
    case `default`, tinted, warm, cool, dark
    var label: String {
        switch self {
        case .default: "Default"
        case .tinted: "Tinted"
        case .warm: "Warm"
        case .cool: "Cool"
        case .dark: "Dark"
        }
    }
}

enum ThemeOption: String, SettingsOption {
    case system = "-1", light = "1", dark = "2"
    var label: String { switch self { case .system: "Follow system"; case .light: "Light"; case .dark: "Dark" } }
}

enum ListModeOption: String, SettingsOption {
    case list, detailed, grid
    var label: String { switch self { case .list: "List"; case .detailed: "Detailed list"; case .grid: "Grid" } }
}

enum ProgressIndicatorOption: String, SettingsOption {
    case disabled, percentRead, percentLeft, chaptersRead, chaptersLeft
    var label: String {
        switch self {
        case .disabled: "Disabled"
        case .percentRead: "Percent read"
        case .percentLeft: "Percent left"
        case .chaptersRead: "Chapters read"
        case .chaptersLeft: "Chapters left"
        }
    }
}

enum ListBadgeOption: String, SettingsOption {
    case favorites, saved
    var label: String { switch self { case .favorites: "Favorites"; case .saved: "Saved manga" } }
}

enum DetailsTabOption: String, SettingsOption {
    case lastUsed = "-1", chapters, pages, bookmarks
    var label: String {
        switch self {
        case .lastUsed: "Last used"
        case .chapters: "Chapters"
        case .pages: "Pages"
        case .bookmarks: "Bookmarks"
        }
    }
}

enum SearchSuggestionOption: String, SettingsOption {
    case recent, queries, sources, genres, manga
    var label: String {
        switch self {
        case .recent: "Recently read"
        case .queries: "Search history"
        case .sources: "Sources"
        case .genres: "Genres"
        case .manga: "Manga"
        }
    }
}

enum ScreenshotsPolicyOption: String, SettingsOption {
    case allow, blockNsfw, blockIncognito, alwaysBlock
    var label: String {
        switch self {
        case .allow: "Allow"
        case .blockNsfw: "Block on NSFW"
        case .blockIncognito: "Block when incognito"
        case .alwaysBlock: "Always block"
        }
    }
}

// Sources
enum SourcesSortOption: String, SettingsOption {
    case alphabetical, popularity, manual
    var label: String { switch self { case .alphabetical: "Alphabetical"; case .popularity: "Popularity"; case .manual: "Manual" } }
}

enum IncognitoNsfwOption: String, SettingsOption {
    case enable, ask, disable
    var label: String { switch self { case .enable: "Enable"; case .ask: "Ask every time"; case .disable: "Disable" } }
}

// Reader
enum ReaderModeOption: String, SettingsOption {
    case standard, rtl, vertical, webtoon
    var label: String {
        switch self {
        case .standard: "Standard"
        case .rtl: "Right-to-left"
        case .vertical: "Vertical"
        case .webtoon: "Webtoon"
        }
    }
}

enum ZoomModeOption: String, SettingsOption {
    case fitCenter, fitHeight, fitWidth, keepStart
    var label: String {
        switch self {
        case .fitCenter: "Fit center"
        case .fitHeight: "Fit to height"
        case .fitWidth: "Fit to width"
        case .keepStart: "Keep at start"
        }
    }
}

enum ReaderControlOption: String, SettingsOption {
    case prevChapter, nextChapter, pageSlider, chaptersPages, orientation, savePage, autoScroll, addBookmark
    var label: String {
        switch self {
        case .prevChapter: "Previous chapter"
        case .nextChapter: "Next chapter"
        case .pageSlider: "Page switch slider"
        case .chaptersPages: "Chapters and pages"
        case .orientation: "Screen orientation"
        case .savePage: "Save page"
        case .autoScroll: "Automatic scroll"
        case .addBookmark: "Add bookmark"
        }
    }
}

enum PageAnimationOption: String, SettingsOption {
    case disabled, standard, advanced
    var label: String { switch self { case .disabled: "Disabled"; case .standard: "Default"; case .advanced: "Advanced" } }
}

enum CropOption: String, SettingsOption {
    case pages, webtoon
    var label: String { switch self { case .pages: "Pages"; case .webtoon: "Webtoon" } }
}

enum OrientationOption: String, SettingsOption {
    case `default`, automatic, portrait, landscape
    var label: String { switch self { case .default: "Default"; case .automatic: "Automatic"; case .portrait: "Portrait"; case .landscape: "Landscape" } }
}

enum ReaderBackgroundOption: String, SettingsOption {
    case `default`, light, dark, white, black
    var label: String { switch self { case .default: "Default"; case .light: "Light"; case .dark: "Dark"; case .white: "White"; case .black: "Black" } }
}

enum PreloadOption: String, SettingsOption {
    case always = "0", wifi = "1", never = "2"
    var label: String { switch self { case .always: "Always"; case .wifi: "Only on Wi-Fi"; case .never: "Never" } }
}

// Storage and network
enum PrefetchOption: String, SettingsOption {
    case always = "0", wifi = "1", never = "2"
    var label: String { switch self { case .always: "Always"; case .wifi: "Only on Wi-Fi"; case .never: "Never" } }
}

enum DohOption: String, SettingsOption {
    case disabled = "0", google = "1", cloudflare = "2", adguard = "3", zeroms = "4"
    var label: String {
        switch self {
        case .disabled: "Disabled"
        case .google: "Google"
        case .cloudflare: "CloudFlare"
        case .adguard: "AdGuard"
        case .zeroms: "0ms"
        }
    }
}

enum GithubMirrorOption: String, SettingsOption {
    case keiyoushi = "KEIYOUSHI"
    var label: String { "Keiyoushi" }
}

enum ImagesProxyOption: String, SettingsOption {
    case none = "-1", wsrv = "0", zeroms = "1"
    var label: String { switch self { case .none: "None"; case .wsrv: "wsrv.nl"; case .zeroms: "0ms.dev" } }
}

enum ProxyTypeOption: String, SettingsOption {
    case direct = "DIRECT", http = "HTTP", socks = "SOCKS"
    var label: String { switch self { case .direct: "Disabled"; case .http: "HTTP"; case .socks: "SOCKS (v4/v5)" } }
}

// Downloads
enum DownloadFormatOption: String, SettingsOption {
    case automatic, singleCbz, multipleCbz
    var label: String { switch self { case .automatic: "Automatic"; case .singleCbz: "Single CBZ file"; case .multipleCbz: "Multiple CBZ files" } }
}

enum MeteredNetworkOption: String, SettingsOption {
    case allow, ask, never
    var label: String { switch self { case .allow: "Allow always"; case .ask: "Ask every time"; case .never: "Don't allow" } }
}

// Tracker
enum TrackerFreqOption: String, SettingsOption {
    case manual = "0", less = "2", `default` = "1", more = "3"
    var label: String { switch self { case .manual: "Manual"; case .less: "Less frequently"; case .default: "Default"; case .more: "More frequently" } }
}

enum TrackSourceOption: String, SettingsOption {
    case favorites, history
    var label: String { switch self { case .favorites: "Favorites"; case .history: "History" } }
}

enum TrackerDownloadOption: String, SettingsOption {
    case never, downloaded
    var label: String { switch self { case .never: "Never"; case .downloaded: "Manga with downloaded chapters" } }
}

// AI Translate
enum AiSourceLangOption: String, SettingsOption {
    case auto = "AUTO", jaV, jaH, zhV, zhH, ko
    var label: String {
        switch self {
        case .auto: "Auto Detect"
        case .jaV: "Japanese (Vertical)"
        case .jaH: "Japanese (Horizontal)"
        case .zhV: "Chinese (Vertical)"
        case .zhH: "Chinese (Horizontal)"
        case .ko: "Korean"
        }
    }
}

enum AiTargetLangOption: String, SettingsOption {
    case english, spanish, french, german, chinese, japanese, korean, portuguese, italian, russian, arabic, hindi, bengali, turkish, vietnamese, polish, dutch, thai, indonesian, greek
    var label: String { rawValue.capitalized }
}

// Backup
enum BackupFreqOption: String, SettingsOption {
    case h6 = "0", day = "1", days2 = "2", week = "7", twiceMonth = "15", month = "30"
    var label: String {
        switch self {
        case .h6: "Every 6 hours"
        case .day: "Every day"
        case .days2: "Every 2 days"
        case .week: "Once per week"
        case .twiceMonth: "Twice per month"
        case .month: "Once per month"
        }
    }
}
