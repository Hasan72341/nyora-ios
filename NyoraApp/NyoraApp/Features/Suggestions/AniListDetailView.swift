import SwiftUI

struct AniListDetailView: View {
    let media: AniListDiscoverMedia
    @EnvironmentObject var model: AppModel
    @State private var descExpanded = false

    private var cleanedDescription: String? {
        guard let desc = media.description, !desc.isEmpty else { return nil }
        return desc.htmlStripped
    }

    private var anilistURL: URL? {
        URL(string: "https://anilist.co/manga/\(media.id)")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                heroSection
                metadataSection
                actionButtons
                if let desc = cleanedDescription {
                    descriptionSection(desc)
                }
                if let genres = media.genres, !genres.isEmpty {
                    genresSection(genres)
                }
            }
            .padding(.bottom, 40)
        }
        .background(DS.Color.background)
        .navigationTitle(media.title.preferred)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            if let url = URL(string: media.coverImage.preferred) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    DS.Color.secondaryBackground
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .clipped()
                .overlay(.ultraThinMaterial)
                .overlay(
                    LinearGradient(
                        colors: [DS.Color.background.opacity(0), DS.Color.background],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipped()
            }

            HStack(alignment: .bottom, spacing: DS.Spacing.lg) {
                if let url = URL(string: media.coverImage.preferred) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        DS.Color.secondaryBackground
                    }
                    .frame(width: DS.CoverSize.hero.width, height: DS.CoverSize.hero.height)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
                    .shadow(radius: 8, y: 4)
                }

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text(media.title.preferred)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .lineLimit(3)
                        .foregroundStyle(DS.Color.label)

                    if let native = media.title.native, native != media.title.preferred {
                        Text(native)
                            .font(.subheadline)
                            .foregroundStyle(DS.Color.secondaryLabel)
                            .lineLimit(1)
                    }

                    if let score = media.averageScore {
                        HStack(spacing: 4) {
                            Text("\(score)%")
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(DS.Color.warning)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, DS.Spacing.lg)
        }
    }

    private var metadataSection: some View {
        HStack(spacing: DS.Spacing.lg) {
            if let score = media.averageScore {
                VStack(spacing: 2) {
                    Text("\(score)%")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(DS.Color.accent)
                    Text("Score")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if let genres = media.genres, !genres.isEmpty {
                Divider().frame(height: 30)
                VStack(spacing: 2) {
                    Text("\(genres.count)")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(DS.Color.accent)
                    Text("Genres")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, DS.Spacing.lg)
    }

    private var actionButtons: some View {
        HStack(spacing: DS.Spacing.md) {
            NavigationLink {
                GlobalSearchView(initialQuery: media.title.preferred)
                    .environmentObject(model)
            } label: {
                Label("Search in Sources", systemImage: "magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.dsPrimary)

            if let url = anilistURL {
                Link(destination: url) {
                    Image(systemName: "safari")
                        .frame(width: 44, height: 40)
                        .foregroundStyle(DS.Color.accent)
                }
                .buttonStyle(.dsSecondary)
            }
        }
        .padding(.horizontal, DS.Spacing.lg)
    }

    private func descriptionSection(_ desc: String) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("About")
                .font(.dsSectionTitle)
            Text(desc)
                .font(.subheadline)
                .foregroundStyle(DS.Color.label)
                .lineLimit(descExpanded ? nil : 4)

            if desc.count > 200 {
                Button(descExpanded ? "Show less" : "Read more") {
                    withAnimation(.easeInOut(duration: 0.2)) { descExpanded.toggle() }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(DS.Color.accent)
            }
        }
        .padding(.horizontal, DS.Spacing.lg)
    }

    private func genresSection(_ genres: [String]) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("Genres")
                .font(.dsSectionTitle)
            FlowLayout(spacing: DS.Spacing.sm) {
                ForEach(genres, id: \.self) { genre in
                    Text(genre)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, DS.Spacing.md)
                        .padding(.vertical, DS.Spacing.xs)
                        .background(DS.Color.accent.opacity(0.12),
                                    in: Capsule())
                        .foregroundStyle(DS.Color.accent)
                }
            }
        }
        .padding(.horizontal, DS.Spacing.lg)
    }
}

