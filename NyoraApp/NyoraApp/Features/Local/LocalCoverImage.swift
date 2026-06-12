import SwiftUI
import UIKit

/// Cover thumbnail for a local manga. `RemoteImage` can't load file:// URLs with the
/// security-scoped dance, so this small helper reads the first image off disk through
/// `LocalLibraryStore` and renders it with `Image(uiImage:)`.
struct LocalCoverImage: View {
    let item: LocalManga
    var contentMode: ContentMode = .fill

    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                Rectangle()
                    .fill(.quaternary)
                    .overlay {
                        if failed {
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        } else {
                            ProgressView()
                        }
                    }
            }
        }
        .clipped()
        .task(id: item.id) { await load() }
    }

    private func load() async {
        image = nil; failed = false
        guard let cover = LocalLibraryStore.shared.coverURL(for: item),
              let img = await LocalLibraryStore.shared.loadImage(for: item, at: cover) else {
            failed = true
            return
        }
        if !Task.isCancelled { image = img }
    }
}
