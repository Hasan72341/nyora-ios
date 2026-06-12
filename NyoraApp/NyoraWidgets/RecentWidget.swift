import WidgetKit
import SwiftUI

struct RecentEntry: TimelineEntry {
    let date: Date
    let items: [WidgetItem]
}

struct RecentProvider: TimelineProvider {
    func placeholder(in context: Context) -> RecentEntry {
        RecentEntry(date: Date(timeIntervalSince1970: 0), items: WidgetItem.samples)
    }
    func getSnapshot(in context: Context, completion: @escaping (RecentEntry) -> Void) {
        let items = context.isPreview ? WidgetItem.samples : WidgetStore.read(WidgetStore.recentKey)
        completion(RecentEntry(date: Date(), items: items))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<RecentEntry>) -> Void) {
        let entry = RecentEntry(date: Date(), items: WidgetStore.read(WidgetStore.recentKey))
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600))))
    }
}

struct RecentView: View {
    @Environment(\.widgetFamily) private var family
    let entry: RecentEntry
    private var limit: Int { family == .systemSmall ? 3 : (family == .systemMedium ? 4 : 8) }
    var body: some View {
        WidgetList(title: "CONTINUE READING", systemImage: "clock.arrow.circlepath", items: entry.items, limit: limit)
            .containerBackground(.background, for: .widget)
    }
}

struct RecentWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NyoraRecent", provider: RecentProvider()) { entry in
            RecentView(entry: entry)
        }
        .configurationDisplayName("Continue Reading")
        .description("Jump back into what you were reading.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
