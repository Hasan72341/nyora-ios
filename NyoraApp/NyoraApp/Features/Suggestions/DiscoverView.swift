import SwiftUI
import NyoraEngine

struct DiscoverView: View {
    @EnvironmentObject var model: AppModel
    @StateObject private var engine = DiscoverEngine.shared
    @StateObject private var sourcePrefs = SourcePrefs.shared
    
    var embedInStack = true

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
                if engine.loading && engine.hero == nil && engine.rails.isEmpty {
                    skeletonLoading
                } else if let error = engine.errorText, engine.rails.isEmpty && engine.hero == nil {
                    ContentUnavailableView(
                        "Couldn't load Discover",
                        systemImage: "wifi.exclamationmark",
                        description: Text(error)
                    )
                } else {
                    if let hero = engine.hero {
                        heroSection(hero)
                    }

                    let pinned = model.sources.filter { sourcePrefs.isEnabled($0.name) && sourcePrefs.isPinned($0.name) }
                    if !pinned.isEmpty {
                        pinnedSourcesSection(pinned)
                    }

                    ForEach(engine.rails) { rail in
                        railSection(rail)
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("Discover")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await engine.refresh(using: model, force: true) }
                } label: {
                    if engine.loading {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task { await engine.refresh(using: model) }
    }

    // MARK: - Skeleton Loading

    private var skeletonLoading: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xl) {
            RoundedRectangle(cornerRadius: 12)
                .fill(DS.Color.secondaryBackground)
                .frame(height: 280)
                .padding(.horizontal)
                .redacted(reason: .placeholder)

            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 10) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DS.Color.secondaryBackground)
                        .frame(width: 140, height: 18)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<5, id: \.self) { _ in
                                VStack(spacing: 6) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(DS.Color.secondaryBackground)
                                        .frame(width: 120, height: 180)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(DS.Color.secondaryBackground)
                                        .frame(width: 100, height: 12)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }

    // MARK: - Hero

    private func heroSection(_ media: AniListDiscoverMedia) -> some View {
        NavigationLink {
            AniListDetailView(media: media)
                .environmentObject(model)
        } label: {
            ZStack(alignment: .bottomLeading) {
                if let url = URL(string: media.coverImage.preferred) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color(UIColor.secondarySystemFill)
                    }
                    .frame(height: 280)
                    .clipped()
                }
                
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("TRENDING NOW")
                        .font(.caption.bold())
                        .foregroundStyle(DS.Color.accent)
                    
                    Text(media.title.preferred)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    
                    if let genres = media.genres {
                        Text(genres.prefix(3).joined(separator: " \u{00B7} "))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding()
            }
            .background(DS.Color.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Pinned Sources

    private func pinnedSourcesSection(_ sources: [MangaParserSource]) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("Pinned Sources")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(sources, id: \.name) { source in
                        NavigationLink {
                            SourceBrowseView(source: source)
                        } label: {
                            VStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(DS.Color.accent.opacity(0.1))
                                    .frame(width: 64, height: 64)
                                    .overlay {
                                        Text(String(source.title.prefix(1)))
                                            .font(.title3.weight(.bold))
                                            .foregroundStyle(DS.Color.accent)
                                    }
                                Text(source.title)
                                    .font(.caption2.weight(.medium))
                                    .lineLimit(1)
                                    .frame(width: 80)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Rails

    private func railSection(_ rail: DiscoverRail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(rail.title)
                    .font(.headline)
                Spacer()
                if case .anilist = rail.items.first {
                    Image("anilist-logo").resizable().frame(width: 16, height: 16)
                        .opacity(0.5)
                }
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(rail.items) { item in
                        discoverItemView(item)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func discoverItemView(_ item: DiscoverItem) -> some View {
        switch item {
        case .manga(let ref):
            if let manga = model.manga(from: ref) {
                NavigationLink {
                    MangaDetailView(manga: manga)
                } label: {
                    MangaCard(manga: manga, headers: headers(for: ref.sourceName))
                        .frame(width: 120)
                }
                .buttonStyle(.plain)
            }
        case .anilist(let media):
            NavigationLink {
                AniListDetailView(media: media)
                    .environmentObject(model)
            } label: {
                AniListCard(media: media)
                    .frame(width: 120)
            }
            .buttonStyle(.plain)
        }
    }

    private func headers(for sourceName: String) -> [String: String] {
        model._jsEngine.parser(for: sourceName)?.requestHeaders() ?? [:]
    }
}

struct AniListCard: View {
    let media: AniListDiscoverMedia
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let url = URL(string: media.coverImage.preferred) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color(UIColor.secondarySystemFill)
                }
                .frame(width: 120, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            Text(media.title.preferred)
                .font(.caption.weight(.medium))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            if let score = media.averageScore {
                HStack(spacing: 2) {
                    Text("\(score)%")
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.orange)
            }
        }
    }
}
