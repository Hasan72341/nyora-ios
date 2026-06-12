import SwiftUI
import Photos
import NyoraEngine

enum ReaderMode: String, CaseIterable { case paged = "Paged", webtoon = "Webtoon" }

/// The reader. Loads a chapter's pages and presents them either as a horizontal pager
/// (manga) or a continuous vertical scroll (webtoon). Tap toggles chrome; progress and
/// bookmarks persist via `AppModel`. Supports moving to the next/previous chapter.
struct ReaderView: View {
    let manga: Manga
    let chapters: [MangaChapter]
    @State var currentChapterIndex: Int
    let startPage: Int

    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var pages: [MangaPage] = []
    @State private var pageIndex = 0
    @State private var loading = true
    @State private var error: String?
    @State private var chromeVisible = true
    @State private var showSettings = ProcessInfo.processInfo.environment["UITEST_SETTINGS"] == "1"
    @State private var showChapters = false
    @AppStorage("readerMode") private var mode: ReaderMode = .paged
    @AppStorage("readerDirection") private var direction: ReadingDirection = .ltr
    @AppStorage("readerPageFit") private var pageFit: PageFit = .fit
    @AppStorage("readerBackground") private var readerBackground: ReaderBackground = .black
    @AppStorage("readerKeepScreenOn") private var keepScreenOn = false

    // Layout / appearance keys also written by the Settings reader screen.
    @AppStorage("webtoon_gaps") private var webtoonGaps = false
    @AppStorage("pages_numbers") private var showPageNumbers = false
    @AppStorage("reader_fullscreen") private var fullscreen = true

    // Auto-scroll (webtoon) — driven by the in-reader popup.
    @AppStorage("readerAutoScrollOn") private var autoScrollOn = false
    @AppStorage("readerAutoScrollSpeed") private var autoScrollSpeed = 0.5

    // Color correction (per-manga override else global). Read live so popup edits apply.
    @State private var colorFilter = ReaderColorFilter()
    @State private var autoScrollTimer: Timer?
    @State private var saveMessage: String?

    // Translation (Vision OCR → Google MT → Apple Intelligence refine)
    @AppStorage("translateTarget") private var targetLang = "English"
    @AppStorage("translateUseAI") private var useAppleIntelligence = true
    @State private var translateOn = ProcessInfo.processInfo.environment["UITEST_TRANSLATE"] == "1"
    @State private var blocksByPage: [Int: [TranslatedBlock]] = [:]
    @State private var sizeByPage: [Int: CGSize] = [:]
    @State private var translator = MangaTranslator()
    @State private var prefetchTask: Task<Void, Never>?
    @State private var webtoonTopID: Int?   // id of the page at the top of the webtoon scroll
    @State private var didApplyStartPage = false   // startPage only applies to the launch chapter

    init(manga: Manga, chapters: [MangaChapter], startChapter: MangaChapter, startPage: Int) {
        self.manga = manga
        self.chapters = chapters
        self._currentChapterIndex = State(initialValue: chapters.firstIndex(where: { $0.id == startChapter.id }) ?? 0)
        self.startPage = startPage
    }

    private var chapter: MangaChapter? {
        chapters.indices.contains(currentChapterIndex) ? chapters[currentChapterIndex] : nil
    }

    var body: some View {
        ZStack {
            readerBackground.color.ignoresSafeArea()

            if loading {
                ProgressView().tint(readerBackground.foreground)
            } else if let error {
                ContentUnavailableView("Couldn’t load pages", systemImage: "exclamationmark.triangle", description: Text(error))
                    .foregroundStyle(readerBackground.foreground)
            } else if pages.isEmpty {
                ContentUnavailableView("No pages", systemImage: "doc", description: Text("This chapter has no readable pages."))
                    .foregroundStyle(readerBackground.foreground)
            } else {
                content
            }

            // Translation overlay for the current page (paged mode; aspect-fit aligned).
            if translateOn, mode == .paged, !pages.isEmpty,
               let blocks = blocksByPage[pageIndex], let size = sizeByPage[pageIndex] {
                GeometryReader { geo in
                    TranslationOverlayView(blocks: blocks, imageSize: size, containerSize: geo.size)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            // Persistent page-number badge (independent of chrome) when enabled in Settings.
            if showPageNumbers, !pages.isEmpty, !chromeVisible {
                VStack {
                    Spacer()
                    Text("\(min(pageIndex + 1, pages.count)) / \(pages.count)")
                        .font(.dsCaption.monospacedDigit())
                        .padding(.horizontal, DS.Spacing.sm)
                        .padding(.vertical, 2)
                        .background(.black.opacity(0.5), in: Capsule())
                        .foregroundStyle(.white)
                        .padding(.bottom, DS.Spacing.md)
                }
                .allowsHitTesting(false)
            }

            // Brief confirmation after saving a page to Photos.
            if let saveMessage {
                VStack {
                    Spacer()
                    Text(saveMessage)
                        .font(.dsCaption)
                        .padding(.horizontal, DS.Spacing.md)
                        .padding(.vertical, DS.Spacing.sm)
                        .background(.black.opacity(0.75), in: Capsule())
                        .foregroundStyle(.white)
                        .padding(.bottom, 60)
                }
                .allowsHitTesting(false)
                .transition(.opacity)
            }

            if chromeVisible { chrome }
        }
        .statusBarHidden(fullscreen ? !chromeVisible : false)
        .persistentSystemOverlays(fullscreen && !chromeVisible ? .hidden : .automatic)
        .sheet(isPresented: $showSettings, onDismiss: { colorFilter = .effective(mangaKey: String(manga.id)) }) {
            ReaderConfigSheet(
                mode: $mode,
                direction: $direction,
                pageFit: $pageFit,
                background: $readerBackground,
                keepScreenOn: $keepScreenOn,
                translateOn: $translateOn,
                targetLang: $targetLang,
                useAppleIntelligence: $useAppleIntelligence,
                isBookmarkAdded: false,
                savePage: { Task { await saveCurrentPage() } },
                addBookmark: {
                    if let chapter { model.addBookmark(manga: manga, chapter: chapter, page: pageIndex) }
                },
                translateThisPage: { translateOn = true },
                mangaKey: String(manga.id)
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showChapters) {
            ReaderChapterListSheet(
                chapters: chapters,
                currentIndex: currentChapterIndex,
                onSelect: { idx in currentChapterIndex = idx; showChapters = false }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .task(id: currentChapterIndex) { await loadChapter() }
        .task(id: "\(translateOn)-\(pageIndex)-\(currentChapterIndex)") { await translateCurrentPage() }
        .onChange(of: translateOn) { _, on in
            if on { startChapterPrefetch() } else { prefetchTask?.cancel() }
        }
        .onChange(of: targetLang) { _, _ in
            blocksByPage.removeAll(); startChapterPrefetch()
        }
        .onChange(of: webtoonTopID) { _, new in
            if let new, new != pageIndex { pageIndex = new; recordProgress(page: new) }
        }
        .onChange(of: keepScreenOn) { _, on in UIApplication.shared.isIdleTimerDisabled = on }
        .onDisappear {
            prefetchTask?.cancel()
            stopAutoScroll()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = keepScreenOn
            applyInitialMode()
            colorFilter = .effective(mangaKey: String(manga.id))
        }
        .onChange(of: mode) { _, new in
            // Remember the chosen mode per source so long-strip sources stay in webtoon.
            UserDefaults.standard.set(new.rawValue, forKey: sourceModeKey)
        }
    }

    private var sourceModeKey: String { "readerMode.\(manga.source.name)" }

    /// Pick the initial reading mode: explicit per-source choice → source content type
    /// (manhwa/manhua are long-strip → webtoon) → global default. UITEST override wins.
    private func applyInitialMode() {
        if ProcessInfo.processInfo.environment["UITEST_MODE"] == "webtoon" { mode = .webtoon; return }
        if let saved = UserDefaults.standard.string(forKey: sourceModeKey),
           let m = ReaderMode(rawValue: saved) { mode = m; return }
        switch manga.source.contentType {
        case .manhwa, .manhua: mode = .webtoon
        default: break
        }
    }

    @ViewBuilder private var content: some View {
        switch mode {
        case .paged:
            TabView(selection: $pageIndex) {
                ForEach(Array(pages.enumerated()), id: \.offset) { idx, page in
                    pageImage(page, index: idx)
                        .tag(idx)
                        // Tap handling lives inside ZoomableImage.onTap (chrome toggle);
                        // pinch-zoom/pan are handled by its UIScrollView. Swipe turns pages.
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .environment(\.layoutDirection, direction == .rtl ? .rightToLeft : .leftToRight)
            .onChange(of: pageIndex) { _, new in recordProgress(page: new) }

        case .webtoon:
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: webtoonGaps ? DS.Spacing.md : 0) {
                        ForEach(Array(pages.enumerated()), id: \.offset) { idx, page in
                            webtoonImage(page, index: idx)
                                .overlay {
                                    if translateOn, let blocks = blocksByPage[idx], let size = sizeByPage[idx] {
                                        GeometryReader { geo in
                                            TranslationOverlayView(blocks: blocks, imageSize: size, containerSize: geo.size)
                                        }
                                    }
                                }
                                .id(idx)
                                // Translate pages as they scroll into view (prefetch fills the rest).
                                .onAppear { if translateOn { Task { await translatePage(idx) } } }
                        }
                    }
                    .scrollTargetLayout()
                }
                // Tracks the page at the top of the viewport so the counter / progress reflect
                // the actual reading position instead of the max-appeared page.
                .scrollPosition(id: $webtoonTopID, anchor: .top)
                // Tap toggles chrome AND pauses auto-scroll (Android behavior).
                .onTapGesture {
                    if autoScrollTimer != nil { stopAutoScroll() }
                    withAnimation { chromeVisible.toggle() }
                }
                .onChange(of: autoScrollOn) { _, on in
                    if on, mode == .webtoon { startAutoScroll(proxy: proxy) } else { stopAutoScroll() }
                }
                .onAppear {
                    if autoScrollOn, mode == .webtoon { startAutoScroll(proxy: proxy) }
                }
                .onDisappear { stopAutoScroll() }
            }
        }
    }

    /// Paged mode: a full-screen pinch/pan-zoomable page.
    private func pageImage(_ page: MangaPage, index: Int) -> some View {
        let req = model.imageRequest(for: page, sourceName: manga.source.name)
        return ZoomableImage(
            url: req?.url,
            headers: req?.headers ?? [:],
            contentMode: pageFit.contentMode,
            onTap: { withAnimation { chromeVisible.toggle() } }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .readerColorFilter(colorFilter)
    }

    /// Webtoon mode: each page sizes itself to the viewport width.
    private func webtoonImage(_ page: MangaPage, index: Int) -> some View {
        let req = model.imageRequest(for: page, sourceName: manga.source.name)
        return RemoteImage(url: req?.url, 
                          headers: req?.headers ?? [:], 
                          contentMode: .fit)
            .frame(maxWidth: .infinity, minHeight: 120)
            .readerColorFilter(colorFilter)
    }

    // MARK: Chrome (top bar + bottom controls)

    private var chrome: some View {
        VStack {
            topBar

            Spacer()

            bottomBar
        }
        .foregroundStyle(.primary)
        .transition(.opacity)
    }

    private var topBar: some View {
        HStack(spacing: DS.Spacing.md) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(DS.Color.label)
                    .frame(width: 32, height: 32)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(manga.title).font(.dsCardTitle).lineLimit(1)
                Text(chapter?.name ?? "").font(.dsCaption).foregroundStyle(.secondary).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: DS.Spacing.md) {
                Button {
                    withAnimation { translateOn.toggle() }
                } label: {
                    Image(systemName: translateOn ? "character.bubble.fill" : "character.bubble")
                        .foregroundStyle(translateOn ? DS.Color.accent : DS.Color.label)
                        .frame(width: 32, height: 32)
                }
                Button {
                    if let chapter { model.addBookmark(manga: manga, chapter: chapter, page: pageIndex) }
                } label: {
                    Image(systemName: "bookmark")
                        .foregroundStyle(DS.Color.label)
                        .frame(width: 32, height: 32)
                }
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "textformat")
                        .foregroundStyle(DS.Color.label)
                        .frame(width: 32, height: 32)
                }
            }
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.vertical, DS.Spacing.sm)
        .padding(.top, DS.Spacing.xs)
        .background(.ultraThinMaterial)
    }

    private var bottomBar: some View {
        VStack(spacing: DS.Spacing.md) {
            HStack(spacing: DS.Spacing.lg) {
                Button { go(-1) } label: {
                    Image(systemName: "chevron.left.2")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 40, height: 40)
                        .background(DS.Color.fill, in: Circle())
                        .overlay(Circle().stroke(DS.Color.separator, lineWidth: 0.5))
                        .foregroundStyle(DS.Color.label)
                }
                .disabled(currentChapterIndex <= 0)
                .opacity(currentChapterIndex <= 0 ? 0.4 : 1)

                Spacer()

                Text("\(min(pageIndex + 1, pages.count)) / \(pages.count)")
                    .font(.dsCaption.monospacedDigit())
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(DS.Color.fill, in: Capsule())
                    .foregroundStyle(DS.Color.label)

                Spacer()

                Button { go(1) } label: {
                    Image(systemName: "chevron.right.2")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 40, height: 40)
                        .background(DS.Color.fill, in: Circle())
                        .overlay(Circle().stroke(DS.Color.separator, lineWidth: 0.5))
                        .foregroundStyle(DS.Color.label)
                }
                .disabled(currentChapterIndex >= chapters.count - 1)
                .opacity(currentChapterIndex >= chapters.count - 1 ? 0.4 : 1)
            }

            if mode == .paged, pages.count > 1 {
                Slider(
                    value: Binding(
                        get: { Double(pageIndex) },
                        set: { pageIndex = Int($0.rounded()) }
                    ),
                    in: 0...Double(max(pages.count - 1, 1)), step: 1
                )
                .tint(DS.Color.accent)
            }

            // Chapter list (☰) + translate (Aあ) + more (⋮)
            HStack {
                Button { showChapters = true } label: {
                    Label("Chapters", systemImage: "list.bullet")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .frame(width: 40, height: 36)
                }
                Spacer()
                Button { translateOn.toggle() } label: {
                    Label("Translate", systemImage: "character.bubble")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .frame(width: 40, height: 36)
                        .foregroundStyle(translateOn ? DS.Color.accent : DS.Color.label)
                }
                Spacer()
                Text(chapter?.name ?? "")
                    .font(.dsCaption).foregroundStyle(.secondary).lineLimit(1)
                Spacer()
                Button { showSettings = true } label: {
                    Label("More", systemImage: "ellipsis")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .frame(width: 40, height: 36)
                }
            }
            .foregroundStyle(DS.Color.label)
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.top, DS.Spacing.md)
        .padding(.bottom, DS.Spacing.sm)
        .background(.ultraThinMaterial)
    }

    private func go(_ delta: Int) {
        let next = currentChapterIndex + delta
        guard chapters.indices.contains(next) else { return }
        currentChapterIndex = next
    }

    private func recordProgress(page: Int) {
        guard let chapter else { return }
        model.recordProgress(manga: manga, chapter: chapter, page: page, total: pages.count)
        // Auto-scrobble: when the chapter is finished, push progress to the linked tracker.
        if pages.count > 0, page >= pages.count - 1 {
            let num = Int(chapter.number.rounded())
            if num > 0 {
                Task { await TrackingService.shared.syncProgress(mangaId: manga.id, chapterNumber: num) }
            }
        }
    }

    @MainActor private func translateCurrentPage() async {
        guard translateOn else { return }
        await translatePage(pageIndex)
    }

    /// Run the OCR→MT→Apple-Intelligence-refine pipeline for one page and stream overlays
    /// in as each stage completes. No-ops if already translated.
    @MainActor private func translatePage(_ idx: Int) async {
        guard translateOn, pages.indices.contains(idx), blocksByPage[idx] == nil else { return }
        guard let req = model.imageRequest(for: pages[idx], sourceName: manga.source.name),
              let ui = try? await ImageLoader.shared.load(req.url, headers: req.headers),
              let cg = ui.cgImage else { return }
        let size = CGSize(width: cg.width, height: cg.height)
        sizeByPage[idx] = size
        let target = ProcessInfo.processInfo.environment["UITEST_TRANSLATE_TO"] ?? targetLang
        let stream = translator.translatePageStream(
            cgImage: cg, imageSize: size,
            sourceLang: "AUTO", targetLang: target,
            useAppleIntelligence: useAppleIntelligence
        )
        for await blocks in stream {
            if Task.isCancelled { return }
            blocksByPage[idx] = blocks
        }
    }

    /// Translate the whole chapter ahead of the reader, current page first, then outward,
    /// so scrolling (especially webtoon) shows overlays without waiting. Sequential to keep
    /// memory/network sane on long chapters.
    @MainActor private func startChapterPrefetch() {
        prefetchTask?.cancel()
        guard translateOn, !pages.isEmpty else { return }
        let order = prefetchOrder()
        prefetchTask = Task {
            for idx in order {
                if Task.isCancelled { return }
                await translatePage(idx)
            }
        }
    }

    private func prefetchOrder() -> [Int] {
        // Webtoon reads top→bottom, so translate in page order (the visible top first).
        // Paged: start at the current page and fan outward.
        if mode == .webtoon { return Array(pages.indices) }
        let start = min(max(pageIndex, 0), max(pages.count - 1, 0))
        let after = Array(start..<pages.count)
        let before = Array(0..<start)
        return after + before.reversed()
    }

    // MARK: Auto-scroll (webtoon)

    /// Timer-driven page advance approximating Android's `ScrollTimer`. `speed` is 0...1;
    /// faster speed -> shorter interval between page steps. Animated with a matching duration
    /// so motion reads as a near-continuous smooth scroll rather than discrete jumps.
    private func startAutoScroll(proxy: ScrollViewProxy) {
        stopAutoScroll()
        guard mode == .webtoon, !pages.isEmpty else { return }
        // speedFactor: 1 (slow) at speed 0 .. ~0 (fast) at speed 1. Clamp so it never stalls.
        let speedFactor = max(0.05, 1 - autoScrollSpeed)
        let interval = 0.4 + speedFactor * 3.6   // 0.4s (fast) .. 4.0s (slow) per page
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task { @MainActor in
                let current = webtoonTopID ?? pageIndex
                let next = current + 1
                guard pages.indices.contains(next) else {
                    stopAutoScroll(); return
                }
                withAnimation(.linear(duration: interval)) {
                    proxy.scrollTo(next, anchor: .top)
                }
                webtoonTopID = next
            }
        }
    }

    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    // MARK: Save page to Photos

    /// Download the current page's full image and add it to the Photos library.
    /// Requires NSPhotoLibraryAddUsageDescription in Info.plist (add-only access).
    @MainActor private func saveCurrentPage() async {
        guard pages.indices.contains(pageIndex),
              let req = model.imageRequest(for: pages[pageIndex], sourceName: manga.source.name) else {
            showSaveMessage("Couldn’t save page"); return
        }
        let image: UIImage?
        if let cached = ImageLoader.shared.cached(req.url) {
            image = cached
        } else {
            image = try? await ImageLoader.shared.load(req.url, headers: req.headers)
        }
        guard let ui = image else { showSaveMessage("Couldn’t save page"); return }

        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            showSaveMessage("Photos access denied"); return
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: ui)
            }
            showSaveMessage("Page saved to Photos")
        } catch {
            showSaveMessage("Couldn’t save page")
        }
    }

    private func showSaveMessage(_ text: String) {
        withAnimation { saveMessage = text }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation { saveMessage = nil }
        }
    }

    @MainActor private func loadChapter() async {
        guard let chapter else { return }
        loading = true; error = nil; pages = []
        // Reset translation state for the new chapter.
        prefetchTask?.cancel()
        blocksByPage.removeAll(); sizeByPage.removeAll()
        do {
            pages = try await model.pages(for: chapter, mangaId: manga.id, sourceName: manga.source.name)
            // startPage is only for the chapter the reader launched on; later chapters start at 0.
            pageIndex = didApplyStartPage ? 0 : min(startPage, max(pages.count - 1, 0))
            didApplyStartPage = true
            // Position the webtoon scroll at the start/continue page.
            webtoonTopID = pageIndex
            recordProgress(page: pageIndex)
            if translateOn { startChapterPrefetch() }
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}

/// In-reader chapter list — jump to any chapter (mirrors the Android reader's ☰ list).
struct ReaderChapterListSheet: View {
    let chapters: [MangaChapter]
    let currentIndex: Int
    let onSelect: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(chapters.enumerated()), id: \.offset) { idx, ch in
                    Button { onSelect(idx) } label: {
                        HStack(spacing: DS.Spacing.md) {
                            Image(systemName: idx == currentIndex ? "book.fill" : "book")
                                .foregroundStyle(idx == currentIndex ? DS.Color.accent : .secondary)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(ch.name.isEmpty ? "Chapter \(ch.number == ch.number.rounded() ? String(Int(ch.number)) : String(ch.number))" : ch.name)
                                    .font(.dsCardTitle)
                                    .foregroundStyle(idx == currentIndex ? DS.Color.accent : DS.Color.label)
                                    .lineLimit(2)
                                if let s = ch.scanlator, !s.isEmpty {
                                    Text(s).font(.dsCaption).foregroundStyle(.secondary).lineLimit(1)
                                }
                            }
                            Spacer()
                            if idx == currentIndex { Image(systemName: "checkmark").foregroundStyle(DS.Color.accent) }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Chapters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}
