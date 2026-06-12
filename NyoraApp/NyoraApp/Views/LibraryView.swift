import SwiftUI
import NyoraEngine

/// real library hub with segmented sections for Favourites, Read Later, and Downloads.
struct LibraryView: View {
    @EnvironmentObject var model: AppModel
    @State private var selectedTab: LibraryTab = .favourites
    
    // Favourites specific state
    @State private var selectedCategory: String?   // nil = All
    @State private var showingNewCategory = false
    @State private var newCategoryName = ""
    @State private var assigning: MangaRef?
    @State private var sortOrder: SortOrder = .recent

    var embedInStack = true

    enum LibraryTab: String, CaseIterable, Identifiable {
        case favourites = "Favourites"
        case readLater = "Read Later"
        case downloads = "Downloads"
        var id: String { rawValue }
    }

    fileprivate enum SortOrder: String, CaseIterable, Identifiable {
        case recent = "Recently Added"
        case title = "Title"
        var id: String { rawValue }
    }

    private var shownFavourites: [MangaRef] {
        let base = model.favourites(inCategory: selectedCategory)
        switch sortOrder {
        case .recent: return base
        case .title: return base.sorted {
            let a = model.manga(from: $0)?.title ?? ""
            let b = model.manga(from: $1)?.title ?? ""
            return a.localizedCaseInsensitiveCompare(b) == .orderedAscending
        }}
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
        VStack(spacing: 0) {
            Picker("Library Tab", selection: $selectedTab) {
                ForEach(LibraryTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .background(DS.Color.background)

            switch selectedTab {
            case .favourites: favouritesContent
            case .readLater: readLaterContent
            case .downloads: downloadsContent
            }
        }
        .navigationTitle("Library")
        .toolbar {
            if selectedTab == .favourites {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort", selection: $sortOrder) {
                            ForEach(SortOrder.allCases) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                    } label: { Image(systemName: "arrow.up.arrow.down") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNewCategory = true } label: { Image(systemName: "folder.badge.plus") }
                }
            }
        }
        .alert("New Category", isPresented: $showingNewCategory) {
            TextField("Name", text: $newCategoryName)
            Button("Add") {
                let n = newCategoryName.trimmingCharacters(in: .whitespaces)
                if !n.isEmpty { model.addCategory(n) }
                newCategoryName = ""
            }
            Button("Cancel", role: .cancel) { newCategoryName = "" }
        }
        .sheet(item: $assigning) { ref in
            CategoryAssignSheet(mangaId: ref.id).environmentObject(model)
        }
    }

    @ViewBuilder
    private var favouritesContent: some View {
        if model.favourites.isEmpty {
            EmptyStateView("No favourites", systemImage: "heart", message: "Add manga from Explore.")
        } else {
            VStack(spacing: 0) {
                categoryBar
                mangaGrid(sources: shownFavourites)
            }
        }
    }

    @ViewBuilder
    private var readLaterContent: some View {
        if model.readLater.isEmpty {
            EmptyStateView("Empty Read Later", systemImage: "clock", message: "Manga you want to read later will appear here.")
        } else {
            mangaGrid(sources: model.readLater)
        }
    }

    @ViewBuilder
    private var downloadsContent: some View {
        DownloadsView(embedInStack: false)
    }

    private func mangaGrid(sources: [MangaRef]) -> some View {
        ScrollView {
            LazyVGrid(columns: DS.posterColumns, spacing: DS.Spacing.lg) {
                ForEach(sources) { ref in
                    if let manga = model.manga(from: ref) {
                        NavigationLink { MangaDetailView(manga: manga) } label: {
                            MangaCard(manga: manga, headers: headers(ref))
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            if selectedTab == .favourites {
                                Button { assigning = ref } label: { Label("Categories…", systemImage: "folder") }
                            }
                            
                            Button(role: .destructive) {
                                if let m = model.manga(from: ref) {
                                    if selectedTab == .favourites { model.toggleFavourite(m) }
                                    else { model.toggleReadLater(m) }
                                }
                            } label: { 
                                Label("Remove", systemImage: selectedTab == .favourites ? "heart.slash" : "clock.badge.xmark") 
                            }
                        }
                    }
                }
            }
            .padding(DS.Spacing.lg)
        }
        .refreshable {
            // No async favourites loader exposed on the model; re-read by nudging
            // the current selection so the computed lists refresh.
            let current = selectedCategory
            selectedCategory = current
        }
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.sm) {
                Button { selectedCategory = nil } label: {
                    Pill(text: "All", isSelected: selectedCategory == nil)
                }
                .buttonStyle(.plain)
                ForEach(model.categories) { cat in
                    Button { selectedCategory = cat.id } label: {
                        Pill(text: cat.name, isSelected: selectedCategory == cat.id)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.vertical, DS.Spacing.sm)
        }
    }

    private func headers(_ ref: MangaRef) -> [String: String] {
        model._jsEngine.parser(for: ref.sourceName)?.requestHeaders() ?? [:]
    }
}

/// Toggle which categories a manga belongs to.
struct CategoryAssignSheet: View {
    let mangaId: Int64
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<String> = []

    var body: some View {
        NavigationStack {
            List {
                if model.categories.isEmpty {
                    ContentUnavailableView("No categories", systemImage: "folder",
                                           description: Text("Create one with the folder＋ button in Library."))
                } else {
                    ForEach(model.categories) { cat in
                        Button {
                            if selected.contains(cat.id) { selected.remove(cat.id) } else { selected.insert(cat.id) }
                        } label: {
                            HStack {
                                Text(cat.name).foregroundStyle(.primary)
                                Spacer()
                                if selected.contains(cat.id) {
                                    Image(systemName: "checkmark").foregroundStyle(.tint)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { model.setCategories(Array(selected), for: mangaId); dismiss() }
                }
            }
            .onAppear { selected = Set(model.categories(for: mangaId)) }
        }
        .presentationDetents([.medium])
    }
}
