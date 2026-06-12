import SwiftUI
import NyoraEngine

/// Updates feed: checks favourites for new chapters (nyora-android's Feed/Updates).
/// Tapping a row opens the manga; bookmarks live in a second section.
struct UpdatesView: View {
    @EnvironmentObject var model: AppModel

    /// Locally dismissed update ids (model.updates is private(set), so we hide rows here).
    @State private var dismissedUpdates: Set<Int64> = []

    /// When `true` (iPhone tab path) the view supplies its own `NavigationStack`.
    /// On iPad the split-view detail column owns the stack, so this is `false`.
    var embedInStack = true

    private var visibleUpdates: [AppModel.UpdateEntry] {
        model.updates.filter { !dismissedUpdates.contains($0.id) }
    }

    private var showEmptyState: Bool {
        !model.favourites.isEmpty && !model.checkingUpdates && visibleUpdates.isEmpty && model.bookmarks.isEmpty
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
            List {
                if model.favourites.isEmpty {
                    Section {
                        EmptyStateView("No favourites to track",
                                       systemImage: "bell",
                                       message: "Add manga to your library to see new-chapter updates.")
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                } else {
                    Section {
                        if model.checkingUpdates {
                            HStack(spacing: DS.Spacing.sm) {
                                ProgressView()
                                Text("Checking \(model.favourites.count) titles…")
                                    .foregroundStyle(DS.Color.secondaryLabel)
                            }
                        } else if visibleUpdates.isEmpty {
                            Text("No new chapters since the last check.")
                                .foregroundStyle(DS.Color.secondaryLabel)
                        } else {
                            ForEach(visibleUpdates) { update in
                                if let manga = model.manga(from: update.manga) {
                                    NavigationLink { MangaDetailView(manga: manga) } label: {
                                        UpdateRow(update: update, headers: headers(update.manga))
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button {
                                            markAsRead(update)
                                        } label: {
                                            Label("Mark as read", systemImage: "checkmark.circle")
                                        }
                                        .tint(DS.Color.success)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("New chapters")
                    }
                }

                if !model.bookmarks.isEmpty {
                    Section("Bookmarks") {
                        ForEach(model.bookmarks) { b in
                            if let manga = model.manga(from: b.manga) {
                                NavigationLink { MangaDetailView(manga: manga) } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(b.manga.title).font(.subheadline.weight(.medium))
                                        Text("\(b.chapterTitle) · page \(b.page + 1)")
                                            .font(.dsCaption).foregroundStyle(DS.Color.secondaryLabel)
                                    }
                                }
                            }
                        }
                        .onDelete { idx in idx.map { model.bookmarks[$0] }.forEach(model.removeBookmark) }
                    }
                }
            }
            .navigationTitle("Updates")
            .overlay {
                if showEmptyState {
                    EmptyStateView("No updates",
                                   systemImage: "bell.slash.fill",
                                   message: "You're all caught up. Pull to refresh or check again for new chapters.")
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await model.checkForUpdates() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(model.favourites.isEmpty || model.checkingUpdates)
                }
            }
            .refreshable { await model.checkForUpdates() }
    }

    private func markAsRead(_ update: AppModel.UpdateEntry) {
        withAnimation { _ = dismissedUpdates.insert(update.id) }
    }

    private func headers(_ ref: MangaRef) -> [String: String] {
        model._jsEngine.parser(for: ref.sourceName)?.requestHeaders() ?? [:]
    }
}

struct UpdateRow: View {
    let update: AppModel.UpdateEntry
    let headers: [String: String]

    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            RemoteImage(url: update.manga.coverUrl.flatMap(URL.init(string:)), headers: headers)
                .aspectRatio(2.0/3.0, contentMode: .fill)
                .frame(width: DS.CoverSize.rowSmall.width, height: DS.CoverSize.rowSmall.height)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(update.manga.title).font(.subheadline.weight(.medium)).lineLimit(2)
                NumberBadge(text: "\(update.newCount) new", tint: DS.Color.accent)
            }
            Spacer()
        }
        .padding(.vertical, DS.Spacing.xs / 2)
    }
}
