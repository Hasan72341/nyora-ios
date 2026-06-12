import SwiftUI
import NyoraEngine

/// Cover-forward grid cell used across Explore / Library / Search — the standard Nyora
/// catalogue tile (poster + title overlay).
struct MangaCard: View {
    let manga: Manga
    var headers: [String: String] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .bottom) {
                RemoteImage(
                    url: manga.coverUrl.flatMap(URL.init(string:)),
                    headers: headers
                )
                .aspectRatio(2.0 / 3.0, contentMode: .fill)

                LinearGradient(
                    colors: [.black.opacity(0.0), .black.opacity(0.75)],
                    startPoint: .center, endPoint: .bottom
                )
                .frame(height: 60)
                .frame(maxHeight: .infinity, alignment: .bottom)

                Text(manga.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.quaternary, lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        }
        .contentShape(Rectangle())
    }
}

/// Reusable adaptive poster grid.
struct MangaGrid<Content: View>: View {
    let manga: [Manga]
    var headers: [String: String] = [:]
    @ViewBuilder var destination: (Manga) -> Content

    private let columns = [GridItem(.adaptive(minimum: 110, maximum: 160), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(manga, id: \.id) { item in
                NavigationLink {
                    destination(item)
                } label: {
                    MangaCard(manga: item, headers: headers)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }
}
