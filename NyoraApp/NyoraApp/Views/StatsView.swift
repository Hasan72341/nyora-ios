import SwiftUI
import NyoraEngine

struct StatsView: View {
    @EnvironmentObject var model: AppModel
    
    private let columns = [
        GridItem(.flexible(), spacing: DS.Spacing.md),
        GridItem(.flexible(), spacing: DS.Spacing.md)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                // Headline Metrics
                LazyVGrid(columns: columns, spacing: DS.Spacing.md) {
                    StatBadge(title: "Library", value: "\(model.favourites.count)", systemImage: "books.vertical.fill")
                    StatBadge(title: "Chapters read", value: "\(model.readChapterCount)", systemImage: "book.fill")
                    StatBadge(title: "In history", value: "\(model.history.count)", systemImage: "clock.fill")
                    StatBadge(title: "Weekly Activity", value: "\(calculateRecentActivity())", systemImage: "bolt.fill")
                }

                // Top Sources Leaderboard
                Section {
                    VStack(alignment: .leading, spacing: DS.Spacing.md) {
                        Text("Top Sources")
                            .font(.dsSectionTitle)
                        
                        let topSources = calculateTopSources()
                        if topSources.isEmpty {
                            Text("No reading data yet.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical)
                        } else {
                            ForEach(topSources, id: \.name) { item in
                                SourceProgressRow(name: item.name, count: item.count, max: topSources.first?.count ?? 1)
                            }
                        }
                    }
                    .padding()
                    .background(DS.Color.secondaryBackground, in: RoundedRectangle(cornerRadius: DS.Radius.md))
                }

                // Other Counts
                Section {
                    VStack(spacing: 0) {
                        HStack {
                            Label("Categories", systemImage: "folder.fill")
                            Spacer()
                            Text("\(model.categories.count)")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        
                        Divider().padding(.leading)
                        
                        HStack {
                            Label("Available Sources", systemImage: "safari.fill")
                            Spacer()
                            Text("\(model.sources.count)")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }
                    .background(DS.Color.secondaryBackground, in: RoundedRectangle(cornerRadius: DS.Radius.md))
                }
            }
            .padding(DS.Spacing.lg)
        }
        .background(DS.Color.groupedBackground)
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func calculateTopSources() -> [(name: String, count: Int)] {
        var counts: [String: Int] = [:]
        // Count from readEvents (more accurate for activity)
        for event in model.readEvents {
            counts[event.sourceName, default: 0] += 1
        }
        // Fallback to history if no events (older builds)
        if counts.isEmpty {
            for entry in model.history {
                counts[entry.manga.sourceName, default: 0] += 1
            }
        }
        return counts.map { (name: $0.key, count: $0.value) }
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map { (name: $0.0, count: $0.1) }
    }
    
    private func calculateRecentActivity() -> Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return model.readEvents.filter { $0.timestamp > weekAgo }.count
    }
}

struct SourceProgressRow: View {
    let name: String
    let count: Int
    let max: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(DS.Color.fill)
                    Capsule().fill(DS.Color.accent)
                        .frame(width: geo.size.width * CGFloat(count) / CGFloat(max))
                }
            }
            .frame(height: 6)
        }
    }
}
