import Foundation
import WidgetKit

/// Publishes a small snapshot of the library + continue-reading list into the shared App Group
/// suite that the home-screen widgets read, then asks WidgetKit to refresh. The widget target
/// can't import app types, so the wire format (id/title/subtitle JSON) is duplicated there.
enum WidgetBridge {
    static let suiteName = "group.com.nyora.ios"
    private static var defaults: UserDefaults { UserDefaults(suiteName: suiteName) ?? .standard }

    private struct Item: Codable { let id: Int64; let title: String; let subtitle: String }

    static func publish(favourites: [MangaRef], history: [HistoryEntry]) {
        let fav = favourites.prefix(12).map { Item(id: $0.id, title: $0.title, subtitle: "Favourite") }
        let recent = history
            .sorted { $0.updatedAt > $1.updatedAt }
            .prefix(12)
            .map { Item(id: $0.manga.id, title: $0.manga.title, subtitle: $0.chapterTitle) }
        if let d = try? JSONEncoder().encode(Array(fav)) { defaults.set(d, forKey: "widget_favourites") }
        if let d = try? JSONEncoder().encode(Array(recent)) { defaults.set(d, forKey: "widget_recent") }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
