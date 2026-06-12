import SwiftUI
import NyoraEngine

/// Manga detail: hero cover, metadata, description, tags, favourite toggle, and the chapter
/// list with a "Continue / Start reading" CTA. Mirrors nyora-android's details screen.
struct MangaDetailView: View {
    let manga: Manga
    @EnvironmentObject var model: AppModel

    @State private var loaded: Manga?
    @State private var loading = true
    @State private var error: String?
    @State private var descExpanded = false
    @StateObject private var downloads = DownloadManager.shared
    @StateObject private var readState = ReadState.shared
    @State private var showLinkSheet = false

    private var current: Manga { loaded ?? manga }
    private var chapters: [MangaChapter] { current.chapters ?? [] }
    private var headers: [String: String] {
        model._jsEngine.parser(for: manga.source.name)?.requestHeaders() ?? [:]
    }

    var body: some View {
        ScrollView {
            // LazyVStack (not VStack) so a multi-thousand-chapter list renders rows on
            // demand instead of building them all up front and stalling the screen.
            // Chapter rows must be DIRECT children of the lazy stack to stay lazy.
            LazyVStack(alignment: .leading, spacing: DS.Spacing.lg) {
                header
                actionBar
                if let desc = current.description?.htmlStripped, !desc.isEmpty {
                    descriptionSection(desc)
                }
                if !current.tags.isEmpty { tagsSection }

                chaptersHeader

                if let error, chapters.isEmpty, !loading {
                    ContentUnavailableView("Couldn’t load chapters", systemImage: "wifi.exclamationmark", description: Text(error))
                }

                if loading && chapters.isEmpty {
                    ForEach(0..<6, id: \.self) { _ in
                        chapterRowPlaceholder
                            .redacted(reason: .placeholder)
                        Divider()
                            .background(DS.Color.separator)
                            .padding(.leading, DS.Spacing.lg)
                    }
                }

                ForEach(chaptersDescending, id: \.id) { chapter in
                    HStack(spacing: 0) {
                        NavigationLink {
                            readerDestination(startChapter: chapter, startPage: 0)
                        } label: {
                            chapterRow(chapter)
                        }
                        .buttonStyle(.plain)
                        chapterDownloadButton(chapter)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        if readState.isRead(chapter.id, mangaId: current.id) {
                            Button {
                                readState.markUnread([chapter.id], mangaId: current.id)
                            } label: { Label("Unread", systemImage: "circle") }
                            .tint(DS.Color.secondaryLabel)
                        } else {
                            Button {
                                readState.markRead([chapter.id], mangaId: current.id)
                            } label: { Label("Read", systemImage: "checkmark.circle") }
                            .tint(DS.Color.success)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            DownloadManager.shared.download(manga: current, chapter: chapter)
                        } label: { Label("Download", systemImage: "arrow.down.circle") }
                        .tint(DS.Color.accent)
                    }
                    .contextMenu {
                        if readState.isRead(chapter.id, mangaId: current.id) {
                            Button { readState.markUnread([chapter.id], mangaId: current.id) } label: {
                                Label("Mark as unread", systemImage: "circle")
                            }
                        } else {
                            Button { readState.markRead([chapter.id], mangaId: current.id) } label: {
                                Label("Mark as read", systemImage: "checkmark.circle")
                            }
                        }
                        Button { readState.markAllPreviousRead(in: chapters, upTo: chapter, mangaId: current.id) } label: {
                            Label("Mark previous as read", systemImage: "checkmark.circle.fill")
                        }
                    }
                    Divider()
                        .background(DS.Color.separator)
                        .padding(.leading, DS.Spacing.lg)
                }
            }
            .padding(.vertical)
        }
        .background(DS.Color.background)
        .navigationTitle(current.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await load() }
    }

    private var header: some View {
        ZStack(alignment: .bottom) {
            // Blurred backdrop derived from the cover, fading into the page background.
            RemoteImage(url: current.coverUrl.flatMap(URL.init(string:)), headers: headers)
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 260)
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

            HStack(alignment: .bottom, spacing: DS.Spacing.lg) {
                RemoteImage(url: current.coverUrl.flatMap(URL.init(string:)), headers: headers)
                    .aspectRatio(2.0/3.0, contentMode: .fill)
                    .frame(width: DS.CoverSize.hero.width, height: DS.CoverSize.hero.height)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
                    .shadow(radius: 8, y: 4)

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text(current.title).font(.title3.bold()).lineLimit(3)
                        .foregroundStyle(DS.Color.label)
                    if let author = current.author {
                        Label(author, systemImage: "person").font(.subheadline)
                            .foregroundStyle(DS.Color.secondaryLabel)
                    }
                    if let state = current.state {
                        Label(state.rawValue.capitalized, systemImage: "circle.fill")
                            .font(.caption).foregroundStyle(stateColor(state))
                    }
                    if current.hasRating {
                        Text(String(format: "%.1f", current.rating * 5))
                            .font(.caption).foregroundStyle(DS.Color.warning)
                    }
                    Text(manga.source.title).font(.caption)
                        .foregroundStyle(DS.Color.secondaryLabel)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, DS.Spacing.lg)
        }
    }

    private var actionBar: some View {
        HStack(spacing: DS.Spacing.md) {
            NavigationLink {
                readerForStart()
            } label: {
                Label(ctaTitle, systemImage: "book")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.dsPrimary)
            .disabled(chapters.isEmpty)

            Button {
                model.toggleFavourite(current)
            } label: {
                Image(systemName: model.isFavourite(current.id) ? "heart.fill" : "heart")
                    .frame(width: 44, height: 40)
                    .foregroundStyle(model.isFavourite(current.id) ? DS.Color.danger : DS.Color.accent)
            }
            .buttonStyle(.dsSecondary)

            Button {
                model.toggleReadLater(current)
            } label: {
                Image(systemName: model.isReadLater(current.id) ? "clock.fill" : "clock")
                    .frame(width: 44, height: 40)
                    .foregroundStyle(model.isReadLater(current.id) ? DS.Color.accent : .secondary)
            }
            .buttonStyle(.bordered)
            .tint(DS.Color.accent)

            Button {
                showLinkSheet = true
            } label: {
                Image(systemName: TrackingService.shared.isLinked(current.id) ? "link.circle.fill" : "link")
                    .frame(width: 44, height: 40)
            }
            .buttonStyle(.bordered)
            .tint(DS.Color.accent)
        }
        .padding(.horizontal, DS.Spacing.lg)
        .sheet(isPresented: $showLinkSheet) {
            LinkSheet(manga: current)
        }
    }

    private var chapterRowPlaceholder: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text("Chapter placeholder name").font(.subheadline)
            Text("Jan 1, 2026").font(.caption2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.vertical, DS.Spacing.sm)
    }

    private var ctaTitle: String {
        if let h = model.continueReading(for: current.id),
           chapters.contains(where: { $0.id == h.chapterId }) {
            return "Continue"
        }
        return "Start reading"
    }

    private func descriptionSection(_ desc: String) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("Description").font(.dsSectionTitle)
            Text(desc)
                .font(.subheadline)
                .foregroundStyle(DS.Color.label)
                .lineLimit(descExpanded ? nil : 4)
            Button(descExpanded ? "Show less" : "Show more") { descExpanded.toggle() }
                .font(.caption.weight(.semibold))
                .foregroundStyle(DS.Color.accent)
        }
        .padding(.horizontal, DS.Spacing.lg)
    }

    private var tagsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.sm) {
                ForEach(Array(current.tags), id: \.key) { tag in
                    Pill(text: tag.title, isSelected: false)
                }
            }
            .padding(.horizontal, DS.Spacing.lg)
        }
    }

    /// Newest-first display order (chapters are stored oldest-first), de-duplicated by id
    /// so SwiftUI's `ForEach` never sees colliding identifiers.
    private var chaptersDescending: [MangaChapter] {
        var seen = Set<Int64>()
        return chapters.reversed().filter { seen.insert($0.id).inserted }
    }

    private var chaptersHeader: some View {
        SectionHeader("Chapters", subtitle: "\(chapters.count) chapters") {
            if loading { ProgressView().controlSize(.small) }
        }
        .padding(.horizontal, DS.Spacing.lg)
    }

    private func chapterRow(_ chapter: MangaChapter) -> some View {
        let read = model.continueReading(for: current.id)?.chapterId == chapter.id
            || ReadState.shared.isRead(chapter.id, mangaId: current.id)
        return HStack {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(chapter.name).font(.subheadline)
                    .foregroundStyle(read ? DS.Color.secondaryLabel : DS.Color.label)
                if chapter.uploadDate > 0 {
                    Text(Date(timeIntervalSince1970: Double(chapter.uploadDate)/1000), style: .date)
                        .font(.caption2).foregroundStyle(DS.Color.secondaryLabel)
                }
            }
            Spacer()
            if read { Image(systemName: "checkmark.circle.fill").foregroundStyle(DS.Color.success).font(.caption) }
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(DS.Color.tertiaryLabel)
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.vertical, DS.Spacing.sm)
        .contentShape(Rectangle())
    }

    @ViewBuilder private func readerForStart() -> some View {
        if let h = model.continueReading(for: current.id),
           let ch = chapters.first(where: { $0.id == h.chapterId }) {
            readerDestination(startChapter: ch, startPage: h.page)
        } else if let first = chapters.first {
            readerDestination(startChapter: first, startPage: 0)
        } else {
            EmptyView()
        }
    }

    /// Route NOVEL-type sources to the text reader; everything else to the image reader.
    @ViewBuilder private func readerDestination(startChapter: MangaChapter, startPage: Int) -> some View {
        if current.source.contentType == .novel {
            NovelReaderView(manga: current, chapters: chapters, startChapter: startChapter, startPage: startPage)
        } else {
            ReaderView(manga: current, chapters: chapters, startChapter: startChapter, startPage: startPage)
        }
    }

    private func stateColor(_ state: MangaState) -> Color {
        switch state {
        case .ongoing: return DS.Color.success
        case .finished: return DS.Color.info
        case .abandoned: return DS.Color.danger
        case .paused: return DS.Color.warning
        default: return DS.Color.secondaryLabel
        }
    }

    @ViewBuilder private func chapterDownloadButton(_ chapter: MangaChapter) -> some View {
        let state = downloads.state(for: chapter.id)
        Button {
            DownloadManager.shared.download(manga: current, chapter: chapter)
        } label: {
            switch state {
            case .done: Image(systemName: "checkmark.circle.fill").foregroundStyle(DS.Color.success)
            case .downloading, .queued: ProgressView().controlSize(.small)
            case .failed: Image(systemName: "exclamationmark.arrow.circlepath").foregroundStyle(DS.Color.warning)
            case nil: Image(systemName: "arrow.down.circle").foregroundStyle(DS.Color.accent)
            }
        }
        .buttonStyle(.plain)
        .padding(.trailing)
        .disabled(state == .done || state == .downloading || state == .queued)
    }

    @MainActor private func load() async {
        loading = true; error = nil
        AppModelBridge.shared.appModel = model   // route downloads through the live model
        do {
            loaded = try await model.details(manga)
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}

extension String {
    /// Strip HTML tags/entities for plain-text display (descriptions arrive as HTML).
    ///
    /// IMPORTANT: this is a pure-Swift stripper, NOT `NSAttributedString(documentType:.html)`.
    /// The latter spins up a WebKit parser that must run on the main run loop, so calling it
    /// synchronously from a SwiftUI `body` hangs the main thread (froze the details screen).
    var htmlStripped: String {
        var s = replacingOccurrences(of: "<br>", with: "\n", options: .caseInsensitive)
        s = s.replacingOccurrences(of: "<br/>", with: "\n", options: .caseInsensitive)
        s = s.replacingOccurrences(of: "<br />", with: "\n", options: .caseInsensitive)
        s = s.replacingOccurrences(of: "</p>", with: "\n\n", options: .caseInsensitive)
        s = s.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        let entities = ["&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"",
                        "&#39;": "'", "&apos;": "'", "&nbsp;": " ", "&hellip;": "…",
                        "&mdash;": "—", "&ndash;": "–", "&rsquo;": "’", "&lsquo;": "‘",
                        "&ldquo;": "“", "&rdquo;": "”"]
        for (k, v) in entities { s = s.replacingOccurrences(of: k, with: v) }
        // Collapse the runs of blank lines the substitutions can leave behind.
        s = s.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
