import SwiftUI
import NyoraEngine

/// Text reader for `ContentType.novel` sources, where a chapter's "pages" are HTML/text pages
/// rather than images. Drop-in replacement for `ReaderView` at the call site — same init
/// signature — so routing is a single branch on `manga.source.contentType`.
///
/// Reuses the shared reader appearance settings: `ReaderBackground` (black/white/sepia) for the
/// page background + legible foreground, plus its own font-size and line-spacing controls
/// persisted via `@AppStorage`. Progress is recorded through `AppModel.recordProgress` exactly
/// like the image reader, so history/continue-reading keep working for novels.
struct NovelReaderView: View {
    let manga: Manga
    let chapters: [MangaChapter]
    @State private var currentChapterIndex: Int
    let startPage: Int

    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var sections: [NovelTextExtractor.Section] = []
    @State private var loading = true
    @State private var error: String?
    @State private var chromeVisible = true
    @State private var showSettings = false
    @State private var loadTask: Task<Void, Never>?
    @State private var didApplyStartPage = false

    // Shared background/foreground tokens with the image reader.
    @AppStorage("readerBackground") private var readerBackground: ReaderBackground = .black
    @AppStorage("readerKeepScreenOn") private var keepScreenOn = false

    // Novel-specific typography, persisted across sessions.
    @AppStorage("novelFontSize") private var fontSize: Double = 18
    @AppStorage("novelLineSpacing") private var lineSpacing: Double = 8
    @AppStorage("novelFontDesignSerif") private var serif = true

    init(manga: Manga, chapters: [MangaChapter], startChapter: MangaChapter, startPage: Int) {
        self.manga = manga
        self.chapters = chapters
        self._currentChapterIndex = State(initialValue: chapters.firstIndex(where: { $0.id == startChapter.id }) ?? 0)
        self.startPage = startPage
    }

    private var chapter: MangaChapter? {
        chapters.indices.contains(currentChapterIndex) ? chapters[currentChapterIndex] : nil
    }

    private var fontDesign: Font.Design { serif ? .serif : .default }

    var body: some View {
        ZStack {
            readerBackground.color.ignoresSafeArea()

            if loading {
                ProgressView().tint(readerBackground.foreground)
            } else if let error {
                ContentUnavailableView(
                    "Couldn’t load chapter",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else {
                content
            }

            if chromeVisible { chrome }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .statusBarHidden(!chromeVisible)
        .task(id: currentChapterIndex) { await load() }
        .onAppear { UIApplication.shared.isIdleTimerDisabled = keepScreenOn }
        .onDisappear {
            loadTask?.cancel()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: keepScreenOn) { _, on in UIApplication.shared.isIdleTimerDisabled = on }
        .sheet(isPresented: $showSettings) { settingsSheet }
    }

    // MARK: - Content

    private var joinedText: String {
        sections.map(\.text).filter { !$0.isEmpty }.joined(separator: "\n\n* * *\n\n")
    }

    private var paragraphs: [(id: Int, text: String)] {
        joinedText
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .enumerated()
            .map { (id: $0.offset, text: $0.element) }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: lineSpacing + 8) {
                if let name = chapter?.name {
                    Text(name)
                        .font(.system(size: fontSize + 6, weight: .bold, design: fontDesign))
                        .foregroundStyle(readerBackground.foreground)
                        .padding(.bottom, 8)
                }

                if paragraphs.isEmpty {
                    Text("No readable text was found on this page.")
                        .font(.system(size: fontSize, design: fontDesign))
                        .foregroundStyle(readerBackground.foreground.opacity(0.7))
                } else {
                    ForEach(paragraphs, id: \.id) { para in
                        if para.text == "* * *" {
                            Text("* * *")
                                .font(.system(size: fontSize, design: fontDesign))
                                .foregroundStyle(readerBackground.foreground.opacity(0.5))
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Text(para.text)
                                .font(.system(size: fontSize, design: fontDesign))
                                .lineSpacing(lineSpacing)
                                .foregroundStyle(readerBackground.foreground)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                    }
                }

                chapterNav
                    .padding(.top, 24)
            }
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.top, 64)
            .padding(.bottom, 48)
        }
        .scrollIndicators(.hidden)
        .contentShape(Rectangle())
        .onTapGesture { withAnimation(.easeInOut(duration: 0.18)) { chromeVisible.toggle() } }
    }

    private var chapterNav: some View {
        HStack {
            Button {
                goToChapter(currentChapterIndex + 1)
            } label: {
                Label("Previous", systemImage: "chevron.left")
            }
            .disabled(currentChapterIndex >= chapters.count - 1)
            .opacity(currentChapterIndex >= chapters.count - 1 ? 0.4 : 1)

            Spacer()

            Button {
                goToChapter(currentChapterIndex - 1)
            } label: {
                Label("Next", systemImage: "chevron.right")
            }
            .disabled(currentChapterIndex <= 0)
            .opacity(currentChapterIndex <= 0 ? 0.4 : 1)
        }
        .font(.body.weight(.semibold))
        .tint(readerBackground.foreground)
    }

    // MARK: - Chrome

    private var chrome: some View {
        VStack {
            HStack(spacing: DS.Spacing.md) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 17, weight: .semibold))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(manga.title).font(.body.weight(.semibold)).lineLimit(1)
                    Text(chapter?.name ?? "").font(.dsCaption).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer()
                Button { showSettings = true } label: {
                    Image(systemName: "textformat.size")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .foregroundStyle(readerBackground.foreground)
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.vertical, DS.Spacing.md)
            .background(.ultraThinMaterial)

            Spacer()
        }
        .transition(.opacity)
    }

    // MARK: - Settings sheet

    private var settingsSheet: some View {
        NavigationStack {
            Form {
                Section("Text size") {
                    HStack {
                        Image(systemName: "textformat.size.smaller")
                        Slider(value: $fontSize, in: 12...32, step: 1)
                        Image(systemName: "textformat.size.larger")
                    }
                    Text("Sample paragraph")
                        .font(.system(size: fontSize, design: fontDesign))
                        .lineSpacing(lineSpacing)
                }
                Section("Line spacing") {
                    Slider(value: $lineSpacing, in: 0...20, step: 1)
                }
                Section("Typeface") {
                    Picker("Typeface", selection: $serif) {
                        Text("Serif").tag(true)
                        Text("Sans-serif").tag(false)
                    }
                    .pickerStyle(.segmented)
                }
                Section("Background") {
                    Picker("Background", selection: $readerBackground) {
                        ForEach(ReaderBackground.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    Toggle("Keep screen on", isOn: $keepScreenOn)
                }
            }
            .navigationTitle("Reading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showSettings = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Loading / progress

    private func goToChapter(_ index: Int) {
        guard chapters.indices.contains(index) else { return }
        sections = []
        loading = true
        error = nil
        currentChapterIndex = index   // .task(id:) reloads
    }

    @MainActor private func load() async {
        loadTask?.cancel()
        guard let chapter else { loading = false; return }
        loading = true
        error = nil
        let task = Task { @MainActor in
            do {
                let pages = try await model.pages(for: chapter, mangaId: manga.id, sourceName: manga.source.name)
                let extracted = try await NovelTextExtractor.sections(
                    for: pages, model: model, sourceName: manga.source.name
                )
                if Task.isCancelled { return }
                sections = extracted
                loading = false
                recordProgress()
            } catch is CancellationError {
                // ignore
            } catch {
                if Task.isCancelled { return }
                self.error = error.localizedDescription
                loading = false
            }
        }
        loadTask = task
        await task.value
    }

    private func recordProgress() {
        guard let chapter else { return }
        // Novels read as one flowing chapter; record page 0 of the chapter's pages so the
        // "continue reading" entry points at this chapter (matches image-reader semantics
        // when a chapter is opened).
        let page = didApplyStartPage ? 0 : max(0, startPage)
        didApplyStartPage = true
        model.recordProgress(manga: manga, chapter: chapter, page: page, total: max(sections.count, 1))
    }
}
