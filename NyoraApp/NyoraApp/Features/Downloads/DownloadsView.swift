import SwiftUI
import NyoraEngine

/// Offline downloads browser: a list of downloaded manga, each expandable to its downloaded
/// chapters with progress bars and swipe-to-delete. Mirrors nyora-android's downloads area.
struct DownloadsView: View {
    @EnvironmentObject var model: AppModel
    @StateObject private var downloads = DownloadManager.shared
    @State private var editMode: EditMode = .inactive
    @State private var confirmClear = false
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
        List {
            if downloads.manga.isEmpty {
                ContentUnavailableView(
                    "No downloads",
                    systemImage: "arrow.down.circle",
                    description: Text("Downloaded chapters are saved here for offline reading.")
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else {
                Section {
                    LabeledContent("Storage used", value: downloads.totalSizeBytes().formattedFileSize)
                }
                ForEach(downloads.manga) { item in
                    DownloadedMangaRow(item: item)
                }
            }
        }
        .navigationTitle("Downloads")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !downloads.manga.isEmpty {
                    EditButton()
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                if !downloads.manga.isEmpty {
                    Button("Clear all", role: .destructive) { confirmClear = true }
                        .tint(.red)
                }
            }
        }
        .confirmationDialog("Delete all downloads?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Delete all", role: .destructive) { downloads.clearAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes every downloaded chapter and frees \(downloads.totalSizeBytes().formattedFileSize).")
        }
        // Ensure the manager can reach the live engine model for any re-downloads triggered here.
        .onAppear { AppModelBridge.shared.appModel = model }
    }
}

/// One manga grouping: a disclosure row whose children are its downloaded chapters.
private struct DownloadedMangaRow: View {
    let item: DownloadedManga
    @EnvironmentObject var model: AppModel
    @StateObject private var downloads = DownloadManager.shared
    @State private var expanded = false

    private var headers: [String: String] {
        model._jsEngine.parser(for: item.manga.sourceName)?.requestHeaders() ?? [:]
    }

    private var chapters: [DownloadedChapter] {
        downloads.chapters(for: item.id)
    }

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            ForEach(chapters) { chapter in
                if let manga = model.manga(from: item.manga) {
                    let ch = chapter.originalChapter ?? MangaChapter(id: chapter.chapterId, title: chapter.chapterTitle, number: 0, volume: 0, url: "", scanlator: nil, uploadDate: 0, branch: nil, source: manga.source)
                    
                    Group {
                        if chapter.state == .done {
                            NavigationLink {
                                ReaderView(manga: manga, 
                                           chapters: [ch],
                                           startChapter: ch,
                                           startPage: 0)
                            } label: {
                                ChapterDownloadRow(chapter: chapter)
                            }
                        } else {
                            HStack {
                                ChapterDownloadRow(chapter: chapter)
                                Spacer()
                                if chapter.state == .failed {
                                    Button {
                                        downloads.download(manga: manga, chapter: ch)
                                    } label: {
                                        Image(systemName: "arrow.clockwise.circle.fill")
                                            .foregroundStyle(DS.Color.accent)
                                    }
                                    .padding(.trailing, 8)
                                }
                            }
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button("Delete", role: .destructive) {
                            downloads.delete(chapterId: chapter.chapterId)
                        }
                    }
                }
            }
            .onDelete { offsets in
                for i in offsets { downloads.delete(chapterId: chapters[i].chapterId) }
            }
        } label: {
            HStack(spacing: 12) {
                RemoteImage(
                    url: item.manga.coverUrl.flatMap(URL.init(string:)),
                    headers: headers
                )
                .aspectRatio(2.0 / 3.0, contentMode: .fill)
                .frame(width: 44, height: 66)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.manga.title).font(.subheadline.weight(.semibold)).lineLimit(2)
                    Text("\(chapters.count) chapter\(chapters.count == 1 ? "" : "s") · \(downloads.sizeBytes(mangaId: item.id).formattedFileSize)")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .swipeActions(edge: .trailing) {
            Button("Delete", role: .destructive) { downloads.delete(mangaId: item.id) }
        }
    }
}

/// A single downloaded chapter row with a progress bar and state glyph.
private struct ChapterDownloadRow: View {
    let chapter: DownloadedChapter

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(chapter.chapterTitle).font(.subheadline).lineLimit(1)
                Spacer()
                stateGlyph
            }
            if chapter.state == .downloading || chapter.state == .queued {
                ProgressView(value: chapter.progress)
                    .tint(.blue)
                Text("\(chapter.savedCount)/\(max(chapter.pageCount, chapter.savedCount)) pages")
                    .font(.caption2).foregroundStyle(.secondary)
            } else if chapter.state == .done {
                Text("\(chapter.pageCount) pages").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder private var stateGlyph: some View {
        switch chapter.state {
        case .done:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .downloading:
            ProgressView().controlSize(.small)
        case .queued:
            Image(systemName: "clock").foregroundStyle(.secondary)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
        }
    }
}
