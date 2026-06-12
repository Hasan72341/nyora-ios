import SwiftUI
import NyoraEngine

/// Paged catalogue for one source: poster grid, sort picker, `.searchable` query, pull to
/// refresh, and infinite scroll — the core browsing surface.
struct SourceBrowseView: View {
    let source: MangaParserSource
    @EnvironmentObject var model: AppModel

    @State private var items: [Manga] = []
    @State private var page = 1
    @State private var order: NyoraEngine.SortOrder = .popularity
    @State private var query = ""
    @State private var filter: MangaListFilter = .empty
    @State private var showFilters = false
    @State private var loading = false
    @State private var loadingMore = false
    @State private var reachedEnd = false
    @State private var error: String?

    private var headers: [String: String] {
        model._jsEngine.parser(for: source.name)?.requestHeaders() ?? [:]
    }

    /// Merge the live search query into the active filter (which holds tags/states/rating).
    private func filterWith(_ q: String) -> MangaListFilter {
        MangaListFilter(
            query: q.isEmpty ? nil : q,
            tags: filter.tags,
            tagsExclude: filter.tagsExclude,
            states: filter.states,
            contentRating: filter.contentRating
        )
    }

    private var hasActiveFilters: Bool {
        !filter.tags.isEmpty || !filter.states.isEmpty || !filter.contentRating.isEmpty
    }

    var body: some View {
        ScrollView {
            if loading && items.isEmpty {
                ProgressView().padding(.top, 60)
            } else if let error, items.isEmpty {
                ContentUnavailableView("Couldn’t load", systemImage: "wifi.exclamationmark", description: Text(error))
                    .padding(.top, 40)
            } else if items.isEmpty {
                ContentUnavailableView("Nothing here", systemImage: "tray", description: Text("No results."))
                    .padding(.top, 40)
            } else {
                MangaGrid(manga: items, headers: headers) { manga in
                    MangaDetailView(manga: manga)
                }
                .padding(.bottom, 8)

                if !reachedEnd {
                    ProgressView()
                        .padding()
                        .task { await loadMore() }
                }
            }
        }
        .navigationTitle(source.title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search \(source.title)")
        .onSubmit(of: .search) { Task { await reload() } }
        .onChange(of: query) { _, new in if new.isEmpty { Task { await reload() } } }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Sort", selection: $order) {
                        ForEach(availableOrders, id: \.self) { o in
                            Text(label(for: o)).tag(o)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showFilters = true
                } label: {
                    Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
            }
        }
        .onChange(of: order) { _, _ in Task { await reload() } }
        .refreshable { await reload() }
        .task { if items.isEmpty { await reload() } }
        .sheet(isPresented: $showFilters) {
            FilterSheetView(
                source: source,
                current: filterWith(query),
                parserProvider: { model._jsEngine.parser(for: source.name) },
                onApply: { newFilter in
                    filter = newFilter
                    Task { await reload() }
                }
            )
        }
    }

    private var availableOrders: [NyoraEngine.SortOrder] {
        model._jsEngine.parser(for: source.name)?.availableSortOrders ?? [.popularity, .updated]
    }

    private func label(for order: NyoraEngine.SortOrder) -> String {
        switch order {
        case .popularity, .popularityAsc: return "Popular"
        case .updated, .updatedAsc: return "Latest"
        case .newest, .newestAsc: return "Newest"
        case .rating, .ratingAsc: return "Top Rated"
        case .alphabetical, .alphabeticalDesc: return "A–Z"
        default: return order.rawValue.capitalized
        }
    }

    @MainActor private func reload() async {
        loading = true; error = nil; page = 1; reachedEnd = false
        if !availableOrders.contains(order) { order = availableOrders.first ?? .updated }
        do {
            let result = try await model._jsEngine.parser(for: source.name)?
                .getList(page: page, order: order, filter: filterWith(query)) ?? []
            items = result
            reachedEnd = result.isEmpty
        } catch {
            self.error = error.localizedDescription
            items = []
        }
        loading = false
    }

    @MainActor private func loadMore() async {
        guard !loadingMore, !reachedEnd, !loading else { return }
        loadingMore = true
        defer { loadingMore = false }
        let next = page + 1
        do {
            let result = try await model._jsEngine.parser(for: source.name)?
                .getList(page: next, order: order, filter: filterWith(query)) ?? []
            if result.isEmpty {
                reachedEnd = true
            } else {
                let existing = Set(items.map(\.id))
                items.append(contentsOf: result.filter { !existing.contains($0.id) })
                page = next
            }
        } catch {
            reachedEnd = true
        }
    }
}
