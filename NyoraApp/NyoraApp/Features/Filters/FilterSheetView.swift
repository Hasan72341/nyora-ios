import SwiftUI
import NyoraEngine

/// Browse filter editor for one source. On appear it fetches the source's `MangaListFilterOptions`
/// via the injected `parserProvider` and lets the user pick genres/tags, a publication state, and a
/// content rating. Sources with no options (e.g. limited Madara) degrade gracefully to an empty
/// state. "Apply" hands a freshly built `MangaListFilter` back to the caller; the existing free-text
/// query carried in `current` is preserved.
struct FilterSheetView: View {
    let source: MangaParserSource
    let current: MangaListFilter
    /// Injected so the sheet need not depend on AppModel directly; pass
    /// `{ model._jsEngine.parser(for: source.name) }` from the call site.
    let parserProvider: () -> MangaParser?
    let onApply: (MangaListFilter) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var options: MangaListFilterOptions = .empty
    @State private var loading = true
    @State private var error: String?

    // Selections (seeded from `current`).
    @State private var selectedTags: Set<MangaTag> = []
    @State private var selectedState: MangaState?
    @State private var selectedRating: ContentRating?

    var body: some View {
        NavigationStack {
            Group {
                if loading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error {
                    ContentUnavailableView("Couldn’t load filters", systemImage: "line.3.horizontal.decrease.circle", description: Text(error))
                } else if !hasAnyOptions {
                    ContentUnavailableView("No filters", systemImage: "line.3.horizontal.decrease.circle", description: Text("This source doesn’t offer filters."))
                } else {
                    Form {
                        if !sortedStates.isEmpty { statusSection }
                        if !sortedRatings.isEmpty { ratingSection }
                        if !sortedTags.isEmpty { genresSection }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset", role: .destructive) { reset() }
                        .disabled(loading)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        onApply(buildFilter())
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(loading)
                }
            }
            .task { await loadOptions() }
        }
    }

    // MARK: Sections

    private var statusSection: some View {
        Section("Status") {
            Picker("Status", selection: $selectedState) {
                Text("Any").tag(MangaState?.none)
                ForEach(sortedStates, id: \.self) { state in
                    Text(label(for: state)).tag(MangaState?.some(state))
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var ratingSection: some View {
        Section("Content Rating") {
            Picker("Rating", selection: $selectedRating) {
                Text("Any").tag(ContentRating?.none)
                ForEach(sortedRatings, id: \.self) { rating in
                    Text(label(for: rating)).tag(ContentRating?.some(rating))
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var genresSection: some View {
        Section("Genres") {
            FlowLayout(spacing: 8) {
                ForEach(sortedTags, id: \.self) { tag in
                    FilterChip(title: tag.title, isSelected: selectedTags.contains(tag)) {
                        if selectedTags.contains(tag) { selectedTags.remove(tag) }
                        else { selectedTags.insert(tag) }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: Derived option lists

    private var hasAnyOptions: Bool {
        !sortedTags.isEmpty || !sortedStates.isEmpty || !sortedRatings.isEmpty
    }

    private var sortedTags: [MangaTag] {
        options.availableTags.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    private var sortedStates: [MangaState] {
        MangaState.allCases.filter { options.availableStates.contains($0) }
    }

    private var sortedRatings: [ContentRating] {
        ContentRating.allCases.filter { options.availableContentRating.contains($0) }
    }

    // MARK: Build / reset

    private func buildFilter() -> MangaListFilter {
        MangaListFilter(
            query: current.query,
            tags: selectedTags,
            states: selectedState.map { [$0] } ?? [],
            contentRating: selectedRating.map { [$0] } ?? []
        )
    }

    private func reset() {
        selectedTags = []
        selectedState = nil
        selectedRating = nil
    }

    private func seedFromCurrent() {
        selectedTags = current.tags
        selectedState = current.states.first
        selectedRating = current.contentRating.first
    }

    private func loadOptions() async {
        loading = true; error = nil
        seedFromCurrent()
        guard let parser = parserProvider() else {
            loading = false
            return
        }
        do {
            options = try await parser.getFilterOptions()
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }

    // MARK: Labels

    private func label(for state: MangaState) -> String {
        switch state {
        case .ongoing: return "Ongoing"
        case .finished: return "Finished"
        case .abandoned: return "Abandoned"
        case .paused: return "Paused"
        case .upcoming: return "Upcoming"
        case .restricted: return "Restricted"
        }
    }

    private func label(for rating: ContentRating) -> String {
        switch rating {
        case .safe: return "Safe"
        case .suggestive: return "Suggestive"
        case .adult: return "Adult"
        }
    }
}
