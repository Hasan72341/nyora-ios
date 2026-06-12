import WidgetKit
import SwiftUI

/// Home-screen widgets mirroring nyora-android's "Shelf" (favourites) and "Recent"
/// (continue-reading) widgets.
@main
struct NyoraWidgetsBundle: WidgetBundle {
    var body: some Widget {
        ShelfWidget()
        RecentWidget()
    }
}

// MARK: - Shared look

/// Flat card with a subtle linear gradient (matches the app's flat+gradient design; no purple).
private let nyoraGradient = LinearGradient(
    colors: [Color(red: 0.20, green: 0.40, blue: 0.95), Color(red: 0.10, green: 0.78, blue: 0.85)],
    startPoint: .topLeading, endPoint: .bottomTrailing
)

struct WidgetRow: View {
    let item: WidgetItem
    var body: some View {
        Link(destination: URL(string: "nyora://manga/\(item.id)")!) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(nyoraGradient)
                    .frame(width: 30, height: 42)
                    .overlay(Image(systemName: "book.closed.fill").font(.caption2).foregroundStyle(.white))
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.title).font(.caption.weight(.semibold)).lineLimit(1)
                    Text(item.subtitle).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

struct WidgetList: View {
    let title: String
    let systemImage: String
    let items: [WidgetItem]
    let limit: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: systemImage).font(.caption2)
                Text(title).font(.caption2.weight(.bold))
                Spacer()
            }
            .foregroundStyle(LinearGradient(colors: [Color(red: 0.20, green: 0.40, blue: 0.95), Color(red: 0.10, green: 0.78, blue: 0.85)], startPoint: .leading, endPoint: .trailing))
            if items.isEmpty {
                Spacer()
                Text("Open Nyora to sync your library.").font(.caption2).foregroundStyle(.secondary)
                Spacer()
            } else {
                ForEach(items.prefix(limit)) { WidgetRow(item: $0) }
                Spacer(minLength: 0)
            }
        }
    }
}
