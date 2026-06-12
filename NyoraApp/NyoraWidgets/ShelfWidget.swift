import WidgetKit
import SwiftUI

struct ShelfEntry: TimelineEntry {
    let date: Date
    let items: [WidgetItem]
}

struct ShelfProvider: TimelineProvider {
    func placeholder(in context: Context) -> ShelfEntry {
        ShelfEntry(date: Date(timeIntervalSince1970: 0), items: WidgetItem.samples)
    }
    func getSnapshot(in context: Context, completion: @escaping (ShelfEntry) -> Void) {
        let items = context.isPreview ? WidgetItem.samples : WidgetStore.read(WidgetStore.favouritesKey)
        completion(ShelfEntry(date: Date(), items: items))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ShelfEntry>) -> Void) {
        let entry = ShelfEntry(date: Date(), items: WidgetStore.read(WidgetStore.favouritesKey))
        // The app reloads timelines on library change; this is just a periodic safety refresh.
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(6 * 3600))))
    }
}

struct ShelfView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ShelfEntry
    private var limit: Int { family == .systemSmall ? 3 : (family == .systemMedium ? 4 : 8) }
    var body: some View {
        WidgetList(title: "LIBRARY", systemImage: "books.vertical.fill", items: entry.items, limit: limit)
            .containerBackground(.background, for: .widget)
    }
}

struct ShelfWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NyoraShelf", provider: ShelfProvider()) { entry in
            ShelfView(entry: entry)
        }
        .configurationDisplayName("Library Shelf")
        .description("Quick access to your favourite manga.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
