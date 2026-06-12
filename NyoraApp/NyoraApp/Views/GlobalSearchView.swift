import SwiftUI
import NyoraEngine

/// Searches every source at once and shows results grouped by source — the iOS take on
/// nyora-android's global search.
struct GlobalSearchView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var groups: [AppModel.SearchGroup] = []
    @State private var searching = false
    @State private var searched = false

    var initialQuery: String? = nil

    private let row = [GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 10)]

    var body: some View {
        NavigationStack {
            Group {
                if searching {
                    ProgressView("Searching all sources…")
                } else if searched && groups.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else if groups.isEmpty {
                    ContentUnavailableView("Search every source",
                                           systemImage: "magnifyingglass",
                                           description: Text("Type a title to search all \(model.sources.count) sources at once."))
                } else {
                    ScrollView {
                        ForEach(groups) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(group.source.title)
                                    .font(.headline)
                                    .padding(.horizontal)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 12) {
                                        ForEach(group.results, id: \.id) { manga in
                                            NavigationLink {
                                                MangaDetailView(manga: manga)
                                            } label: {
                                                MangaCard(manga: manga, headers: headers(group.source))
                                                    .frame(width: 120)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
            .navigationTitle("Global Search")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search all sources")
            .onSubmit(of: .search) { Task { await run() } }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                if let initialQuery, query.isEmpty {
                    query = initialQuery
                    Task { await run() }
                }
            }
        }
    }

    private func headers(_ source: MangaParserSource) -> [String: String] {
        model._jsEngine.parser(for: source.name)?.requestHeaders() ?? [:]
    }

    @MainActor private func run() async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        SearchHistoryStore.record(q)   // populates the history that "Clear search history" removes
        searching = true; searched = false
        groups = await model.globalSearch(query: query)
        searching = false; searched = true
    }
}
