import SwiftUI

// MARK: - ReaderConfigSheet
//
// Android-style reader configuration popup, mirroring nyora-android's `ReaderConfigSheet`
// (BaseAdaptiveSheet, layout `SheetReaderConfigBinding`). Presented from the reader's top bar
// settings button / long-press. Drop-in alternative to the simpler `ReaderSettingsSheet`:
// it accepts the SAME bindings the existing sheet uses, plus `savePage` / `addBookmark`
// closures and a bookmark-state flag.
//
// Section order mirrors Android, top to bottom:
//   1. ACTIONS  — Save page, Add/Remove bookmark
//   2. READ MODE — 4-way segmented (Standard / Right-to-left / Vertical / Webtoon)
//   3. LAYOUT   — two-pages-on-landscape toggle + revealed double-page sensitivity slider
//   4. TOOLS    — Auto-scroll (sub-screen), Color correction (sub-screen), Translate-this-page
//   5. TRANSLATION — existing translateOn / targetLang / useAppleIntelligence
//   6. APPEARANCE — background swatches, keep-screen-on
//   7. MORE     — All reader settings link
//
// Flat design with LinearGradient accents (no purple), reusing DesignSystem tokens.

// MARK: - 4-way read mode (Android MaterialButtonToggleGroup)

/// The unified 4-way read-mode choice from Android, derived from the existing
/// `ReaderMode` + `ReadingDirection` bindings.
/// - Standard      -> mode = .paged,   direction = .ltr
/// - Right-to-left -> mode = .paged,   direction = .rtl
/// - Vertical      -> mode = .webtoon  (vertical paging / continuous; treated as scroll)
/// - Webtoon       -> mode = .webtoon
///
/// Note: the current iOS `ReaderMode` only has `{paged, webtoon}`, so Vertical and Webtoon
/// both map to `.webtoon` (continuous vertical scroll). A dedicated `verticalPaging` flag is
/// stored so the distinction survives round-trips and the reader can opt into paged-vertical
/// later. Disabled-state logic (two-pages layout) keys off whether the choice is paged.
enum ReaderModeChoice: String, CaseIterable, Identifiable {
    case standard
    case rightToLeft
    case vertical
    case webtoon

    var id: String { rawValue }

    var label: String {
        switch self {
        case .standard:    return "Standard"
        case .rightToLeft: return "Right-to-left"
        case .vertical:    return "Vertical"
        case .webtoon:     return "Webtoon"
        }
    }

    var systemImage: String {
        switch self {
        case .standard:    return "book"
        case .rightToLeft: return "book.closed"
        case .vertical:    return "arrow.up.and.down"
        case .webtoon:     return "rectangle.portrait.arrowtriangle.2.outward"
        }
    }

    /// Whether the paged (horizontal) layout is active — controls two-pages availability.
    var isPaged: Bool { self == .standard || self == .rightToLeft }

    /// Whether this choice scrolls continuously (no discrete page-switch interval).
    var isWebtoon: Bool { self == .webtoon }

    /// Derive from the existing mode + direction (+ a vertical-paging hint).
    static func from(mode: ReaderMode, direction: ReadingDirection, verticalPaging: Bool) -> ReaderModeChoice {
        switch mode {
        case .paged:
            return direction == .rtl ? .rightToLeft : .standard
        case .webtoon:
            return verticalPaging ? .vertical : .webtoon
        }
    }

    /// Apply this choice back onto the existing bindings.
    func apply(mode: inout ReaderMode, direction: inout ReadingDirection, verticalPaging: inout Bool) {
        switch self {
        case .standard:
            mode = .paged; direction = .ltr; verticalPaging = false
        case .rightToLeft:
            mode = .paged; direction = .rtl; verticalPaging = false
        case .vertical:
            mode = .webtoon; verticalPaging = true
        case .webtoon:
            mode = .webtoon; verticalPaging = false
        }
    }
}

// MARK: - Sheet

struct ReaderConfigSheet: View {
    // Existing bindings (identical to ReaderSettingsSheet).
    @Binding var mode: ReaderMode
    @Binding var direction: ReadingDirection
    @Binding var pageFit: PageFit
    @Binding var background: ReaderBackground
    @Binding var keepScreenOn: Bool
    @Binding var translateOn: Bool
    @Binding var targetLang: String
    @Binding var useAppleIntelligence: Bool

    // Bookmark state + actions (provided by the reader).
    var isBookmarkAdded: Bool = false
    var savePage: () -> Void = {}
    var addBookmark: () -> Void = {}
    var translateThisPage: () -> Void = {}

    // Per-manga key suffix so per-manga overrides don't collide across titles.
    // Pass `manga.id` from the reader; falls back to a shared key.
    var mangaKey: String = "global"

    @Environment(\.dismiss) private var dismiss

    // Layout settings (new keys).
    @AppStorage("readerDoublePageLandscape") private var twoPageLandscape = false
    @AppStorage("readerDoublePagesSensitivity") private var doublePageSensitivity = 0.5
    @AppStorage("readerVerticalPaging") private var verticalPaging = false

    // Auto-scroll (new keys).
    @AppStorage("readerAutoScrollOn") private var autoScrollOn = false
    @AppStorage("readerAutoScrollSpeed") private var autoScrollSpeed = 0.5

    /// Local derived 4-way choice, kept in sync with mode/direction/verticalPaging.
    @State private var modeChoice: ReaderModeChoice = .standard

    var body: some View {
        NavigationStack {
            Form {
                actionsSection
                readModeSection
                if modeChoice.isPaged { layoutSection }
                toolsSection
                translationSection
                appearanceSection
                moreSection
            }
            .navigationTitle("Reader")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            modeChoice = .from(mode: mode, direction: direction, verticalPaging: verticalPaging)
        }
    }

    // MARK: 1. Actions

    private var actionsSection: some View {
        Section {
            Button {
                savePage()
                dismiss()
            } label: {
                Label("Save page", systemImage: "square.and.arrow.down")
            }

            Button {
                addBookmark()   // does NOT dismiss
            } label: {
                Label(isBookmarkAdded ? "Remove bookmark" : "Add bookmark",
                      systemImage: isBookmarkAdded ? "bookmark.fill" : "bookmark")
            }
        } header: {
            Text("Actions").font(.dsSectionTitle)
        }
    }

    // MARK: 2. Read mode

    private var readModeSection: some View {
        Section {
            Picker("Read mode", selection: $modeChoice) {
                ForEach(ReaderModeChoice.allCases) { choice in
                    Text(choice.label).tag(choice)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: modeChoice) { _, new in
                new.apply(mode: &mode, direction: &direction, verticalPaging: &verticalPaging)
            }
        } header: {
            Text("Read mode").font(.dsSectionTitle)
        } footer: {
            Text("Remembered for this manga.")
        }
    }

    // MARK: 3. Layout (paged only)

    private var layoutSection: some View {
        Section {
            Toggle("Use two pages on landscape", isOn: $twoPageLandscape)
                .tint(DS.Color.accent)

            if twoPageLandscape {
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    HStack {
                        Text("Double-page detection sensitivity")
                        Spacer()
                        Text("\(Int(doublePageSensitivity * 100))%")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $doublePageSensitivity, in: 0...1)
                        .tint(DS.Color.accent)
                }
            }
        } header: {
            Text("Layout").font(.dsSectionTitle)
        }
    }

    // MARK: 4. Tools

    private var toolsSection: some View {
        Section {
            NavigationLink {
                AutoScrollConfigView(active: $autoScrollOn,
                                     speed: $autoScrollSpeed,
                                     isWebtoon: modeChoice.isWebtoon)
            } label: {
                Label("Automatic scroll", systemImage: "arrow.down.circle")
            }

            NavigationLink {
                ColorCorrectionConfigView(mangaKey: mangaKey)
            } label: {
                Label("Color correction", systemImage: "slider.horizontal.3")
            }

            Button {
                translateThisPage()
                dismiss()
            } label: {
                Label("Translate this page", systemImage: "character.bubble")
            }
        } header: {
            Text("Tools").font(.dsSectionTitle)
        }
    }

    // MARK: 5. Translation (existing)

    private var translationSection: some View {
        Section {
            Toggle("Auto-translate this manga", isOn: $translateOn)
                .tint(DS.Color.accent)

            Picker("Translate to", selection: $targetLang) {
                ForEach(TranslationConfig.supportedLanguages.filter { $0 != "AUTO" }, id: \.self) {
                    Text($0).tag($0)
                }
            }
            .pickerStyle(.menu)
            .disabled(!translateOn)

            Toggle("Apple Intelligence refine", isOn: $useAppleIntelligence)
                .tint(DS.Color.accent)
                .disabled(!translateOn)
        } header: {
            Text("Translation").font(.dsSectionTitle)
        } footer: {
            Text("Refines machine-translated text on-device using Apple Intelligence. Requires a supported device.")
        }
    }

    // MARK: 6. Appearance (existing)

    private var appearanceSection: some View {
        Section {
            HStack {
                Text("Background")
                Spacer()
                HStack(spacing: DS.Spacing.md) {
                    ForEach(ReaderBackground.allCases) { bg in
                        Circle()
                            .fill(bg.color)
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(DS.Color.separator, lineWidth: 0.5))
                            .overlay(Circle().stroke(DS.Color.accent, lineWidth: background == bg ? 2.5 : 0))
                            .onTapGesture { background = bg }
                            .accessibilityLabel(bg.label)
                    }
                }
            }
            Toggle("Keep screen on", isOn: $keepScreenOn)
                .tint(DS.Color.accent)
        } header: {
            Text("Appearance").font(.dsSectionTitle)
        }
    }

    // MARK: 7. More

    private var moreSection: some View {
        Section {
            NavigationLink {
                ReaderSettingsView()
            } label: {
                Label("All reader settings", systemImage: "gearshape")
            }
        }
    }
}

// MARK: - SUB-SCREEN A: Auto-scroll

/// Mirrors Android `ScrollTimerControlView` + `ScrollTimer`.
/// `speed` is stored 0...1. Android mapping: speedFactor = 1 - speed,
/// delayMs = round(32 * speedFactor), pageSwitchDelay = round(10000 * speedFactor) ms.
struct AutoScrollConfigView: View {
    @Binding var active: Bool
    @Binding var speed: Double
    var isWebtoon: Bool

    private static let maxDelayMs: Double = 32
    private static let maxSwitchDelayMs: Double = 10_000

    private var speedFactor: Double { 1 - speed }
    private var pageSwitchSeconds: Double {
        guard speed > 0 else { return 0 }
        return (Self.maxSwitchDelayMs * speedFactor).rounded() / 1000
    }

    var body: some View {
        Form {
            Section {
                Toggle("Automatic scroll", isOn: $active)
                    .tint(DS.Color.accent)
            }

            Section {
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    HStack {
                        Text("Speed")
                        Spacer()
                        // Cosmetic Android "speed value": 0.1 + percent*10 wording -> show a 0.1x..N value.
                        Text(String(format: "%.1f", 0.1 + speed * 10))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $speed, in: 0...1)
                        .tint(DS.Color.accent)
                        .disabled(!active)
                }
            } footer: {
                // Hidden when paused/disabled or in webtoon (continuous scroll, no page switch).
                if active, speed > 0, !isWebtoon {
                    Text(String(format: "Page switch every %.0fs", pageSwitchSeconds))
                }
            }
        }
        .navigationTitle("Automatic scroll")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Color filter model (ports ReaderColorFilter)

/// Live, AppStorage-backed color-correction filter, ported from Android `ReaderColorFilter`.
/// Apply order (matching Android): multitone OR grayscale -> invert -> brightness -> contrast -> book.
struct ReaderColorFilter: Equatable {
    var brightness: Double = 0   // -1...1
    var contrast: Double = 0     // -1...1
    var invert: Bool = false
    var grayscale: Bool = false
    var bookEffect: Bool = false
    var preset: String = "None"  // multitone preset id, "None" = off

    var isEmpty: Bool {
        brightness == 0 && contrast == 0 && !invert && !grayscale && !bookEffect && preset == "None"
    }

    /// 7 named groups of 5 presets each (35 total), mirroring `ReaderColorFilter.Preset`.
    static let presetGroups: [(group: String, presets: [String])] = [
        ("Duotone",    ["Sepia", "Slate", "Cyberpunk", "Emerald", "Terracotta"]),
        ("Tritone",    ["Vintage", "Copper", "Sunset", "Biolum", "Sage"]),
        ("Quadratone", ["Arcade", "Candy", "Lavender", "Autumn", "Aurora"]),
        ("Pentatone",  ["Synthwave", "Rainbow", "Canopy", "Cybercity", "Pastel"]),
        ("Hexatone",   ["Abyss", "Thermal", "Sunset ", "Meadow", "Vaporwave"]),
        ("Heptatone",  ["Nebula", "Glitch", "Vintage ", "Jungle", "Twilight"]),
        ("Octatone",   ["Acid", "Prism", "Emerald ", "Sakura", "Arctic"]),
    ]
}

// MARK: - SUB-SCREEN B: Color correction

/// Mirrors Android `ColorFilterConfigActivity`. Persists per-manga and globally.
/// Effective precedence: per-manga override (if non-empty) else global default.
struct ColorCorrectionConfigView: View {
    var mangaKey: String

    @Environment(\.dismiss) private var dismiss

    // Persisted as compact strings so the reader can read the same keys.
    @AppStorage private var perMangaRaw: String
    @AppStorage("readerColorFilterGlobal") private var globalRaw: String = ""

    @State private var filter = ReaderColorFilter()
    @State private var showApplyDialog = false

    init(mangaKey: String) {
        self.mangaKey = mangaKey
        _perMangaRaw = AppStorage(wrappedValue: "", "readerColorFilter.\(mangaKey)")
    }

    var body: some View {
        Form {
            Section {
                ColorAdjustSlider(title: "Brightness", value: $filter.brightness)
                ColorAdjustSlider(title: "Contrast", value: $filter.contrast)
                Toggle("Invert", isOn: $filter.invert).tint(DS.Color.accent)
                Toggle("Grayscale", isOn: $filter.grayscale).tint(DS.Color.accent)
                Toggle("Book effect", isOn: $filter.bookEffect).tint(DS.Color.accent)
            } header: {
                Text("Adjustments").font(.dsSectionTitle)
            }

            Section {
                presetGrid
            } header: {
                Text("Multitone presets").font(.dsSectionTitle)
            }

            Section {
                Button(role: .destructive) {
                    filter = ReaderColorFilter()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .navigationTitle("Color correction")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Apply") { showApplyDialog = true }
            }
        }
        .confirmationDialog("Apply color correction to…",
                            isPresented: $showApplyDialog,
                            titleVisibility: .visible) {
            Button("This manga") { saveThisManga() }
            Button("Globally")   { saveGlobally() }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear { loadEffective() }
    }

    private var presetGrid: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            chip("None")
            ForEach(ReaderColorFilter.presetGroups, id: \.group) { group in
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Text(group.group)
                        .font(.dsCaption)
                        .foregroundStyle(.secondary)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: DS.Spacing.sm)],
                              alignment: .leading, spacing: DS.Spacing.sm) {
                        ForEach(group.presets, id: \.self) { chip($0) }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func chip(_ name: String) -> some View {
        let selected = filter.preset == name
        Button {
            filter.preset = name
            if name != "None" { filter.grayscale = false } // preset overrides grayscale
        } label: {
            Text(name.trimmingCharacters(in: .whitespaces))
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.sm - 2)
                .frame(maxWidth: .infinity)
                .background {
                    if selected {
                        LinearGradient(colors: [DS.Color.accent, DS.Color.accent.opacity(0.7)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    } else {
                        DS.Color.fill
                    }
                }
                .foregroundStyle(selected ? DS.Color.onAccent : DS.Color.label)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Persistence

    private func loadEffective() {
        let perManga = Self.decode(perMangaRaw)
        if let f = perManga, !f.isEmpty {
            filter = f
        } else if let g = Self.decode(globalRaw) {
            filter = g
        }
    }

    private func saveThisManga() {
        perMangaRaw = filter.isEmpty ? "" : Self.encode(filter)
        dismiss()
    }

    private func saveGlobally() {
        globalRaw = filter.isEmpty ? "" : Self.encode(filter)
        // Reset all per-manga overrides like Android `saveGlobally()`.
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("readerColorFilter.") {
            defaults.removeObject(forKey: key)
        }
        dismiss()
    }

    // Compact "b;c;invert;gray;book;preset" encoding the reader can also parse.
    static func encode(_ f: ReaderColorFilter) -> String {
        "\(f.brightness);\(f.contrast);\(f.invert ? 1 : 0);\(f.grayscale ? 1 : 0);\(f.bookEffect ? 1 : 0);\(f.preset)"
    }

    static func decode(_ s: String) -> ReaderColorFilter? {
        guard !s.isEmpty else { return nil }
        let parts = s.components(separatedBy: ";")
        guard parts.count >= 6 else { return nil }
        var f = ReaderColorFilter()
        f.brightness = Double(parts[0]) ?? 0
        f.contrast = Double(parts[1]) ?? 0
        f.invert = parts[2] == "1"
        f.grayscale = parts[3] == "1"
        f.bookEffect = parts[4] == "1"
        f.preset = parts[5...].joined(separator: ";")
        return f
    }
}

/// Brightness/Contrast slider with Android-style % label (value -1...1 -> -100%..+100%).
private struct ColorAdjustSlider: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value * 100))%")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: $value, in: -1...1)
                .tint(DS.Color.accent)
        }
    }
}
