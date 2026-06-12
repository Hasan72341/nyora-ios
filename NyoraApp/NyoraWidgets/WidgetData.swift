import Foundation

/// One manga row shown in a widget. The app writes these into the shared App Group suite
/// (group.com.nyora.ios); the widget reads them. Kept tiny (no images) so it survives the
/// UserDefaults size limits and works without a shared file container.
struct WidgetItem: Codable, Identifiable, Hashable {
    let id: Int64
    let title: String
    let subtitle: String   // e.g. "Ch. 12 of 40" or the source name
}

extension WidgetItem {
    static let samples: [WidgetItem] = [
        WidgetItem(id: 1, title: "Solo Leveling", subtitle: "Ch. 179"),
        WidgetItem(id: 2, title: "One Piece", subtitle: "Ch. 1120"),
        WidgetItem(id: 3, title: "Chainsaw Man", subtitle: "Ch. 158"),
        WidgetItem(id: 4, title: "Berserk", subtitle: "Ch. 374"),
    ]
}

/// Shared store between the app and its widgets. Uses the App Group suite when available
/// (real signed builds), falling back to standard defaults so the extension still builds/runs.
enum WidgetStore {
    static let suiteName = "group.com.nyora.ios"
    static let favouritesKey = "widget_favourites"
    static let recentKey = "widget_recent"

    static var defaults: UserDefaults { UserDefaults(suiteName: suiteName) ?? .standard }

    static func read(_ key: String) -> [WidgetItem] {
        guard let data = defaults.data(forKey: key),
              let items = try? JSONDecoder().decode([WidgetItem].self, from: data) else { return [] }
        return items
    }

    static func write(_ items: [WidgetItem], key: String) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: key)
    }
}
