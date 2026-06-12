import SwiftUI
import NyoraEngine

/// Source picker — the entry to browsing. Lists installed parser sources; tapping one opens
/// its catalogue. A global search field fans out to the selected source.
struct ExploreView: View {
    @EnvironmentObject var model: AppModel
    @StateObject private var sourcePrefs = SourcePrefs.shared
    @State private var showingSearch = false
    @State private var sourceFilter = ""
    @State private var selectedLocale: String? = nil
    @State private var selectedType: ContentType? = nil

    var embedInStack = true

    private var filteredSources: [MangaParserSource] {
        let ordered = sourcePrefs.orderedSources(from: model.sources)
            .filter { sourcePrefs.isEnabled($0.name) }
        
        var list = ordered
        if let loc = selectedLocale {
            list = list.filter { $0.locale == loc || ($0.locale == nil && loc == "multi") }
        }
        if let type = selectedType {
            list = list.filter { $0.contentType == type }
        }
        
        let query = sourceFilter.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return list }
        return list.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }

    private var availableLocales: [String] {
        let locales = Set(model.sources.compactMap { $0.locale ?? "multi" })
        return Array(locales).sorted()
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
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                // Header / Stats
                headerSection

                // Search Entry
                searchEntry

                // Quick Filters
                filterBar

                // Pinned Sources Rail
                let pinned = filteredSources.filter { sourcePrefs.isPinned($0.name) }
                if !pinned.isEmpty {
                    pinnedRail(pinned)
                }

                // All Sources List
                let all = filteredSources.filter { !sourcePrefs.isPinned($0.name) }
                sourcesSection(pinned.isEmpty ? "Sources" : "All", sources: all)
            }
            .padding(.vertical)
        }
        .navigationTitle("Explore")
        .searchable(text: $sourceFilter, placement: .navigationBarDrawer(displayMode: .always), prompt: "Filter sources")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingSearch = true } label: { Image(systemName: "magnifyingglass") }
            }
        }
        .sheet(isPresented: $showingSearch) {
            GlobalSearchView().environmentObject(model)
        }
    }

    private var headerSection: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(model.sources.count) sources available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
    }

    private var searchEntry: some View {
        Button {
            showingSearch = true
        } label: {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                Text("Search all sources...")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
            .background(DS.Color.secondaryBackground, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.sm) {
                Menu {
                    Button("All Languages") { selectedLocale = nil }
                    ForEach(availableLocales, id: \.self) { loc in
                        Button(loc.uppercased()) { selectedLocale = loc }
                    }
                } label: {
                    Pill(text: selectedLocale?.uppercased() ?? "Language", isSelected: selectedLocale != nil)
                }
                
                Menu {
                    Button("All Types") { selectedType = nil }
                    ForEach([ContentType.manga, .hentai], id: \.self) { type in
                        Button(type.rawValue.capitalized) { selectedType = type }
                    }
                } label: {
                    Pill(text: selectedType?.rawValue.capitalized ?? "Content Type", isSelected: selectedType != nil)
                }
            }
            .padding(.horizontal)
        }
    }

    private func pinnedRail(_ sources: [MangaParserSource]) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("Pinned")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(sources, id: \.name) { source in
                        NavigationLink {
                            SourceBrowseView(source: source)
                        } label: {
                            VStack(spacing: 8) {
                                sourceIcon(source, size: 64)
                                Text(source.title)
                                    .font(.caption2.weight(.medium))
                                    .lineLimit(1)
                                    .frame(width: 80)
                            }
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button { sourcePrefs.togglePin(source.name) } label: {
                                Label("Unpin", systemImage: "pin.slash.fill")
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func sourcesSection(_ title: String, sources: [MangaParserSource]) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            LazyVStack(spacing: 0) {
                ForEach(sources, id: \.name) { source in
                    NavigationLink {
                        SourceBrowseView(source: source)
                    } label: {
                        sourceRow(source)
                    }
                    .buttonStyle(.plain)
                    
                    if source.name != sources.last?.name {
                        Divider().padding(.leading, 64 + DS.Spacing.md + 16)
                    }
                }
            }
            .background(DS.Color.secondaryBackground, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }

    private func sourceRow(_ source: MangaParserSource) -> some View {
        HStack(spacing: DS.Spacing.md) {
            sourceIcon(source, size: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(source.title).font(.body.weight(.medium))
                HStack(spacing: 4) {
                    Text((source.locale ?? "multi").uppercased())
                    Text("·")
                    Text(source.contentType.rawValue.capitalized)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                sourcePrefs.togglePin(source.name)
            } label: {
                Image(systemName: sourcePrefs.isPinned(source.name) ? "pin.fill" : "pin")
                    .foregroundStyle(sourcePrefs.isPinned(source.name) ? DS.Color.accent : .secondary)
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .contentShape(Rectangle())
    }

    private func sourceIcon(_ source: MangaParserSource, size: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: size * 0.2, style: .continuous)
            .fill(DS.Color.tertiaryFill)
            .frame(width: size, height: size)
            .overlay {
                Text(String(source.title.prefix(1)))
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundStyle(DS.Color.secondaryLabel)
            }
    }
}

struct SourceRow: View {
    let source: MangaParserSource

    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                .fill(DS.Color.tertiaryFill)
                .frame(width: DS.CoverSize.rowSmall.width, height: DS.CoverSize.rowSmall.height)
                .overlay {
                    Text(String(source.title.prefix(1)))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(DS.Color.secondaryLabel)
                }
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(source.title).font(.body.weight(.medium))
                HStack(spacing: DS.Spacing.sm) {
                    Text((source.locale ?? "multi").uppercased())
                    Text("·")
                    Text(source.contentType.rawValue.capitalized)
                }
                .font(.caption)
                .foregroundStyle(DS.Color.secondaryLabel)
            }
        }
        .padding(.vertical, DS.Spacing.xs)
    }
}
