import SwiftUI
import NyoraEngine

/// Reading history with resume — tapping a row reopens detail so the user can continue.
struct HistoryView: View {
    @EnvironmentObject var model: AppModel
    @State private var filter = ""
    @State private var showClearConfirm = false
    /// IDs locally hidden via swipe-to-delete (no per-item store API exists).
    @State private var hiddenIDs: Set<Int64> = []

    /// When `true` (iPhone tab path) the view supplies its own `NavigationStack`.
    /// On iPad the split-view detail column owns the stack, so this is `false`.
    var embedInStack = true

    private var filteredEntries: [HistoryEntry] {
        model.history.filter { entry in
            guard !hiddenIDs.contains(entry.id) else { return false }
            guard !filter.isEmpty else { return true }
            return entry.manga.title.localizedCaseInsensitiveContains(filter)
        }
    }

    private var stats: HistoryStatsData {
        let titles = model.history.count
        let completed = model.history.filter { $0.percent >= 1.0 }.count
        let favourites = model.favourites.count
        let streakDays = longestStreak(model.history.map(\.updatedAt))
        let topSources = computeTopSources()
        return HistoryStatsData(
            titles: titles,
            completed: completed,
            favourites: favourites,
            streakDays: streakDays,
            topSources: topSources
        )
    }

    private var showStats: Bool {
        !model.history.isEmpty
    }

    var body: some View {
        if embedInStack {
            NavigationStack { content }
        } else {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
            Group {
                if filteredEntries.isEmpty && !showStats {
                    EmptyStateView(
                        "No history",
                        systemImage: "clock",
                        message: filter.isEmpty
                            ? "Manga you read will show up here."
                            : "No history matches \u{201C}\(filter)\u{201D}."
                    )
                } else {
                    List {
                        if showStats {
                            Section {
                                HistoryStatsCard(stats: stats)
                                    .listRowInsets(EdgeInsets(top: DS.Spacing.sm, leading: DS.Spacing.lg, bottom: DS.Spacing.sm, trailing: DS.Spacing.lg))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                            }
                        }

                        ForEach(HistorySection.grouped(filteredEntries), id: \.kind) { section in
                            Section {
                                ForEach(section.entries) { entry in
                                    Group {
                                        if let manga = model.manga(from: entry.manga) {
                                            NavigationLink {
                                                MangaDetailView(manga: manga)
                                            } label: {
                                                HistoryRow(entry: entry)
                                            }
                                        } else {
                                            HistoryRow(entry: entry)
                                        }
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            delete(entry)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            } header: {
                                Text(section.kind.title)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("History")
            .searchable(text: $filter, prompt: "Search history")
            .toolbar {
                if !model.history.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear", role: .destructive) { showClearConfirm = true }
                            .tint(DS.Color.danger)
                    }
                }
            }
            .confirmationDialog(
                "Clear all history?",
                isPresented: $showClearConfirm,
                titleVisibility: .visible
            ) {
                Button("Clear History", role: .destructive) {
                    model.clearHistory()
                    hiddenIDs.removeAll()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes every entry from your reading history.")
            }
    }

    private func delete(_ entry: HistoryEntry) {
        hiddenIDs.insert(entry.id)
    }

    private func headers(for ref: MangaRef) -> [String: String] {
        model._jsEngine.parser(for: ref.sourceName)?.requestHeaders() ?? [:]
    }

    private func computeTopSources() -> [(name: String, count: Int)] {
        var counts: [String: Int] = [:]
        for event in model.readEvents {
            counts[event.sourceName, default: 0] += 1
        }
        if counts.isEmpty {
            for entry in model.history {
                counts[entry.manga.sourceName, default: 0] += 1
            }
        }
        return counts.map { (name: $0.key, count: $0.value) }
            .sorted { $0.1 > $1.1 }
            .prefix(4)
            .map { (name: $0.0, count: $0.1) }
    }

    private func longestStreak(_ timestamps: [Date]) -> Int {
        guard !timestamps.isEmpty else { return 0 }
        let cal = Calendar.current
        let days = Set(timestamps.map { cal.startOfDay(for: $0).timeIntervalSince1970 / 86400 })
            .map { Int($0) }
            .sorted()
        guard !days.isEmpty else { return 0 }
        var longest = 1
        var current = 1
        var prev = days[0]
        for day in days.dropFirst() {
            if day == prev + 1 {
                current += 1
            } else {
                current = 1
            }
            if current > longest { longest = current }
            prev = day
        }
        return longest
    }
}

// MARK: - Stats Data

fileprivate struct HistoryStatsData {
    let titles: Int
    let completed: Int
    let favourites: Int
    let streakDays: Int
    let topSources: [(name: String, count: Int)]
}

// MARK: - Stats Card

fileprivate struct HistoryStatsCard: View {
    let stats: HistoryStatsData

    private let columns = [
        GridItem(.flexible(), spacing: DS.Spacing.sm),
        GridItem(.flexible(), spacing: DS.Spacing.sm),
        GridItem(.flexible(), spacing: DS.Spacing.sm),
        GridItem(.flexible(), spacing: DS.Spacing.sm)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            LazyVGrid(columns: columns, spacing: DS.Spacing.sm) {
                MiniStatTile(value: "\(stats.titles)", label: "Titles", systemImage: "book.closed.fill", tint: DS.Color.accent)
                MiniStatTile(value: "\(stats.completed)", label: "Completed", systemImage: "checkmark.circle.fill", tint: DS.Color.success)
                MiniStatTile(value: "\(stats.favourites)", label: "Favourites", systemImage: "heart.fill", tint: DS.Color.danger)
                MiniStatTile(value: "\(stats.streakDays)", label: "Day streak", systemImage: "flame.fill", tint: DS.Color.warning)
            }

            if !stats.topSources.isEmpty {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Text("Top Sources")
                        .font(.dsCaption.weight(.semibold))
                        .foregroundStyle(DS.Color.secondaryLabel)

                    ForEach(stats.topSources, id: \.name) { item in
                        HStack(spacing: DS.Spacing.sm) {
                            Text(item.name)
                                .font(.dsCaption)
                                .foregroundStyle(DS.Color.label)
                                .lineLimit(1)
                            Spacer()
                            Text("\(item.count)")
                                .font(.dsBadge.monospacedDigit())
                                .foregroundStyle(DS.Color.secondaryLabel)
                        }
                    }
                }
                .padding(DS.Spacing.md)
                .background(DS.Color.tertiaryFill, in: RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))
            }
        }
        .padding(DS.Spacing.lg)
        .background(DS.Color.secondaryBackground, in: RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous))
    }
}

fileprivate struct MiniStatTile: View {
    let value: String
    let label: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(spacing: DS.Spacing.xs) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
            Text(value)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.sm)
    }
}

// MARK: - Dated grouping

fileprivate enum HistorySectionKind: Int, Hashable {
    case today, yesterday, thisWeek, earlier

    var title: String {
        switch self {
        case .today: return "Today"
        case .yesterday: return "Yesterday"
        case .thisWeek: return "This week"
        case .earlier: return "Earlier"
        }
    }

    static func kind(for date: Date, now: Date = Date()) -> HistorySectionKind {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return .today }
        if cal.isDateInYesterday(date) { return .yesterday }
        if let weekAgo = cal.date(byAdding: .day, value: -7, to: now), date >= weekAgo {
            return .thisWeek
        }
        return .earlier
    }
}

fileprivate struct HistorySection {
    let kind: HistorySectionKind
    let entries: [HistoryEntry]

    static func grouped(_ entries: [HistoryEntry]) -> [HistorySection] {
        let now = Date()
        let buckets = Dictionary(grouping: entries) { HistorySectionKind.kind(for: $0.updatedAt, now: now) }
        let order: [HistorySectionKind] = [.today, .yesterday, .thisWeek, .earlier]
        return order.compactMap { k in
            guard let items = buckets[k], !items.isEmpty else { return nil }
            return HistorySection(kind: k, entries: items)
        }
    }
}

struct HistoryRow: View {
    let entry: HistoryEntry
    @EnvironmentObject var model: AppModel

    var body: some View {
        let req = model.imageRequest(for: entry.manga)
        HStack(spacing: DS.Spacing.md) {
            RemoteImage(url: req?.url, headers: req?.headers ?? [:])
                .aspectRatio(2.0/3.0, contentMode: .fill)
                .frame(width: DS.CoverSize.rowSmall.width, height: DS.CoverSize.rowSmall.height)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))
                .background(DS.Color.tertiaryFill, in: RoundedRectangle(cornerRadius: DS.Radius.sm))

            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(entry.manga.title)
                    .font(.dsCardTitle)
                    .foregroundStyle(DS.Color.label)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    Text(entry.chapterTitle)
                    Text("·")
                    Text(entry.manga.sourceName)
                }
                .font(.dsCaption)
                .foregroundStyle(DS.Color.secondaryLabel)
                .lineLimit(1)

                ProgressView(value: entry.percent)
                    .tint(DS.Color.accent)
            }
            Spacer(minLength: DS.Spacing.sm)
            Text(entry.updatedAt, style: .relative)
                .font(.dsBadge)
                .foregroundStyle(DS.Color.tertiaryLabel)
        }
        .padding(.vertical, DS.Spacing.xs)
    }
}
