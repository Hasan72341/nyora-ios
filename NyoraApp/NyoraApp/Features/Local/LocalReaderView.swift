import SwiftUI
import UIKit

/// A minimal reader for imported local manga. Renders a chapter's image files straight off
/// disk (loaded async via `LocalLibraryStore`) either as a horizontal pager or a continuous
/// vertical scroll. Tap toggles a minimal top bar with a close button.
struct LocalReaderView: View {
    let item: LocalManga
    @State var currentChapterIndex: Int

    @Environment(\.dismiss) private var dismiss
    @AppStorage("readerMode") private var mode: ReaderMode = .paged

    @State private var pageURLs: [URL] = []
    @State private var images: [URL: UIImage] = [:]
    @State private var pageIndex = 0
    @State private var chromeVisible = true

    private var chapter: LocalChapter? {
        item.chapters.indices.contains(currentChapterIndex) ? item.chapters[currentChapterIndex] : nil
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if pageURLs.isEmpty {
                ContentUnavailableView("No pages", systemImage: "doc",
                                       description: Text("This chapter has no readable images."))
                    .foregroundStyle(.white)
            } else {
                content
            }

            if chromeVisible { chrome }
        }
        .statusBarHidden(!chromeVisible)
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .task(id: currentChapterIndex) { loadChapter() }
    }

    @ViewBuilder private var content: some View {
        switch mode {
        case .paged:
            TabView(selection: $pageIndex) {
                ForEach(Array(pageURLs.enumerated()), id: \.offset) { idx, url in
                    pageImage(url)
                        .tag(idx)
                        .onTapGesture { withAnimation { chromeVisible.toggle() } }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

        case .webtoon:
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(pageURLs.enumerated()), id: \.offset) { _, url in
                        pageImage(url)
                    }
                }
            }
            .onTapGesture { withAnimation { chromeVisible.toggle() } }
        }
    }

    private func pageImage(_ url: URL) -> some View {
        Group {
            if let img = images[url] {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Color.black
                    .overlay { ProgressView().tint(.white) }
            }
        }
        .frame(maxWidth: .infinity)
        .task(id: url) { await loadPage(url) }
    }

    private var chrome: some View {
        VStack {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.headline)
                }
                VStack(alignment: .leading) {
                    Text(item.title).font(.subheadline.weight(.semibold)).lineLimit(1)
                    Text(chapter?.name ?? "").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer()
                Menu {
                    Picker("Mode", selection: $mode) {
                        ForEach(ReaderMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                } label: { Image(systemName: "textformat.size") }
            }
            .padding()
            .background(.ultraThinMaterial)

            Spacer()

            if item.chapters.count > 1 || pageURLs.count > 1 {
                VStack(spacing: 8) {
                    HStack {
                        Button { go(-1) } label: { Image(systemName: "chevron.left.2") }
                            .disabled(currentChapterIndex <= 0)
                        Spacer()
                        Text("\(min(pageIndex + 1, pageURLs.count)) / \(pageURLs.count)")
                            .font(.caption.monospacedDigit())
                        Spacer()
                        Button { go(1) } label: { Image(systemName: "chevron.right.2") }
                            .disabled(currentChapterIndex >= item.chapters.count - 1)
                    }
                    if mode == .paged, pageURLs.count > 1 {
                        Slider(
                            value: Binding(
                                get: { Double(pageIndex) },
                                set: { pageIndex = Int($0.rounded()) }
                            ),
                            in: 0...Double(max(pageURLs.count - 1, 1)), step: 1
                        )
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
        .foregroundStyle(.primary)
        .transition(.opacity)
    }

    private func go(_ delta: Int) {
        let next = currentChapterIndex + delta
        guard item.chapters.indices.contains(next) else { return }
        currentChapterIndex = next
    }

    private func loadChapter() {
        guard let chapter else { pageURLs = []; return }
        images.removeAll()
        pageURLs = LocalLibraryStore.shared.pageURLs(for: item, chapter: chapter)
        pageIndex = 0
    }

    @MainActor private func loadPage(_ url: URL) async {
        guard images[url] == nil else { return }
        if let img = await LocalLibraryStore.shared.loadImage(for: item, at: url) {
            if !Task.isCancelled { images[url] = img }
        }
    }
}
