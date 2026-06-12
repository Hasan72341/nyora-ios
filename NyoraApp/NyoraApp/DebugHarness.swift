import SwiftUI
import NyoraEngine

/// Verification-only entry point. When the app is launched with the environment variable
/// `UITEST_DETAIL=<SOURCE_NAME>`, it fetches that source's first popular manga and pushes
/// straight into `MangaDetailView`, so the detail + chapter-list UI can be screenshotted
/// without UI tapping (stock `simctl` can't tap). Normal launches ignore this.
struct DebugDetailLoader: View {
    let sourceName: String
    @EnvironmentObject var model: AppModel
    @State private var manga: Manga?
    @State private var status = "Loading…"

    var body: some View {
        NavigationStack {
            Group {
                if let manga {
                    MangaDetailView(manga: manga)
                } else {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text(status).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .task {
            do {
                let list = try await model.browse(sourceName: sourceName, page: 1, order: .popularity, query: nil)
                guard let first = list.first else { status = "empty list"; return }
                manga = first
            } catch {
                status = error.localizedDescription
            }
        }
    }

    static var requestedSource: String? {
        ProcessInfo.processInfo.environment["UITEST_DETAIL"]
    }
}

/// Verification-only: `UITEST_READER=<SOURCE_NAME>` browses the source, finds the first
/// title/chapter that actually has hosted pages (skipping licensed/0-page entries), and
/// opens `ReaderView` straight on it so the page renderer can be screenshotted.
struct DebugReaderLoader: View {
    let sourceName: String
    @EnvironmentObject var model: AppModel
    @State private var payload: (Manga, [MangaChapter], MangaChapter)?
    @State private var status = "Finding a readable chapter…"

    var body: some View {
        Group {
            if let (manga, chapters, chapter) = payload {
                // Embed in a TabView like the real app so the tab-bar-hiding behaviour is
                // exercised (a bare NavigationStack would have no tab bar to hide).
                TabView {
                    NavigationStack {
                        ReaderView(manga: manga, chapters: chapters, startChapter: chapter, startPage: 0)
                    }
                    .tabItem { Label("Explore", systemImage: "safari") }
                }
            } else {
                VStack(spacing: 8) { ProgressView(); Text(status).font(.footnote).foregroundStyle(.secondary) }
            }
        }
        .task {
            do {
                let list = try await model.browse(sourceName: sourceName, page: 1, order: .popularity, query: nil)
                for m in list.prefix(8) {
                    let d = try await model.details(m)
                    guard let chapters = d.chapters, !chapters.isEmpty else { continue }
                    for ch in chapters.prefix(3) {
                        let pages = try await model.pages(for: ch, mangaId: 0, sourceName: sourceName)
                        if !pages.isEmpty { payload = (d, chapters, ch); return }
                    }
                }
                status = "no readable chapter found in sample"
            } catch {
                status = error.localizedDescription
            }
        }
    }

    static var requestedSource: String? {
        ProcessInfo.processInfo.environment["UITEST_READER"]
    }
}
