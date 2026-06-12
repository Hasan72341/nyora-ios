import SwiftUI

/// SCREEN 3 — Reader settings. Mirrors pref_reader.xml (single flat list).
/// Reuses existing reader @AppStorage keys where they overlap (readerKeepScreenOn,
/// readerBackground via the new reader_background key for the full Android option set).
struct ReaderSettingsScreen: View {
    @AppStorage("reader_mode") private var readerMode: ReaderModeOption = .standard
    @AppStorage("reader_mode_detect") private var detectMode = true
    @AppStorage("zoom_mode") private var zoomMode: ZoomModeOption = .fitCenter
    @AppStorage("reader_zoom_buttons") private var zoomButtons = false
    @AppStorage("webtoon_zoom") private var webtoonZoom = true
    @AppStorage("webtoon_zoom_out") private var webtoonZoomOut: Double = 0
    @AppStorage("webtoon_gaps") private var webtoonGaps = false
    @AppStorage("reader_controls") private var controls = "prevChapter,nextChapter,pageSlider,chaptersPages"
    @AppStorage("reader_taps_ltr") private var tapsLtr = false
    @AppStorage("reader_navigation_inverted") private var navInverted = false
    @AppStorage("reader_animation2") private var animation: PageAnimationOption = .standard
    @AppStorage("webtoon_pull_gesture") private var pullGesture = false
    @AppStorage("enhanced_colors") private var enhancedColors = false
    @AppStorage("reader_optimize") private var optimize = false
    @AppStorage("reader_crop") private var crop = ""
    @AppStorage("reader_fullscreen") private var fullscreen = true
    @AppStorage("reader_orientation") private var orientation: OrientationOption = .default
    @AppStorage("readerKeepScreenOn") private var keepScreenOn = true
    @AppStorage("reader_multitask") private var multitask = false
    @AppStorage("reader_bar") private var infoBar = true
    @AppStorage("reader_bar_transparent") private var infoBarTransparent = true
    @AppStorage("reader_chapter_toast") private var chapterToast = true
    @AppStorage("reader_background") private var background: ReaderBackgroundOption = .default
    @AppStorage("pages_numbers") private var pageNumbers = false
    @AppStorage("pages_preload") private var preload: PreloadOption = .never

    // Legacy reader keys that actually drive ReaderView / ReaderConfigSheet at runtime.
    // This screen is the high-level settings UI; to make its Android-style options take effect
    // we mirror them into these keys (the single source of truth the reader reads).
    @AppStorage("readerMode") private var legacyMode: ReaderMode = .paged
    @AppStorage("readerDirection") private var legacyDirection: ReadingDirection = .ltr
    @AppStorage("readerPageFit") private var legacyPageFit: PageFit = .fit
    @AppStorage("readerVerticalPaging") private var legacyVerticalPaging = false
    @AppStorage("readerBackground") private var legacyBackground: ReaderBackground = .black

    /// Map the Android `reader_mode` option onto the reader's mode + direction (+ vertical hint).
    private func syncMode(_ opt: ReaderModeOption) {
        switch opt {
        case .standard: legacyMode = .paged;   legacyDirection = .ltr; legacyVerticalPaging = false
        case .rtl:      legacyMode = .paged;   legacyDirection = .rtl; legacyVerticalPaging = false
        case .vertical: legacyMode = .webtoon; legacyVerticalPaging = true
        case .webtoon:  legacyMode = .webtoon; legacyVerticalPaging = false
        }
    }

    /// Map the Android `zoom_mode` option onto the reader's page fit.
    private func syncZoom(_ opt: ZoomModeOption) {
        switch opt {
        case .fitWidth, .keepStart: legacyPageFit = .fillWidth
        case .fitCenter, .fitHeight: legacyPageFit = .fit
        }
    }

    /// Map the Android `reader_background` option onto the reader's background.
    private func syncBackground(_ opt: ReaderBackgroundOption) {
        switch opt {
        case .white: legacyBackground = .white
        case .light: legacyBackground = .sepia        // closest existing light tone
        case .dark, .black, .default: legacyBackground = .black
        }
    }

    private func syncAll() {
        syncMode(readerMode)
        syncZoom(zoomMode)
        syncBackground(background)
    }

    var body: some View {
        List {
            Section { SettingsHeader("Reader settings", systemImage: "book.fill") }

            Section {
                SingleSelectRow(title: "Default mode", selection: $readerMode)
                ToggleRow(title: "Detect reader mode", isOn: $detectMode)
                SingleSelectRow(title: "Scale mode", selection: $zoomMode)
                ToggleRow(title: "Reader zoom buttons", isOn: $zoomButtons)
                ToggleRow(title: "Webtoon zoom", isOn: $webtoonZoom)
                SliderRow(title: "Default webtoon zoom out", range: 0...50, step: 10, unit: "%", value: $webtoonZoomOut)
                    .disabled(!webtoonZoom)
                ToggleRow(title: "Webtoon gaps", isOn: $webtoonGaps)
            }

            Section {
                MultiSelectRow<ReaderControlOption>(title: "Reader controls in bottom bar", rawSelection: $controls)
                NavigationLink { ReaderTapZonesView() } label: {
                    rowLabel(title: "Reader actions", systemImage: "hand.tap", value: nil)
                }
                ToggleRow(title: "Reader controls LTR", isOn: $tapsLtr)
                ToggleRow(title: "Invert reader navigation", isOn: $navInverted)
                SingleSelectRow(title: "Pages animation", selection: $animation)
                ToggleRow(title: "Enable pull gesture", isOn: $pullGesture)
            }

            Section {
                ToggleRow(title: "Enhanced colors", isOn: $enhancedColors)
                ToggleRow(title: "Optimize for performance", isOn: $optimize)
                MultiSelectRow<CropOption>(title: "Crop pages", rawSelection: $crop)
                ToggleRow(title: "Fullscreen mode", isOn: $fullscreen)
                SingleSelectRow(title: "Screen orientation", selection: $orientation)
                ToggleRow(title: "Keep screen on", isOn: $keepScreenOn)
                ToggleRow(title: "Reader multitask", isOn: $multitask)
            }

            Section {
                ToggleRow(title: "Reader info bar", isOn: $infoBar)
                ToggleRow(title: "Transparent info bar", isOn: $infoBarTransparent)
                    .disabled(!infoBar)
                ToggleRow(title: "Chapter toast", isOn: $chapterToast)
                SingleSelectRow(title: "Background", selection: $background)
                ToggleRow(title: "Show page numbers", isOn: $pageNumbers)
                SingleSelectRow(title: "Preload pages", selection: $preload)
            }
        }
        .navigationTitle("Reader settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { syncAll() }
        .onChange(of: readerMode) { _, new in syncMode(new) }
        .onChange(of: zoomMode) { _, new in syncZoom(new) }
        .onChange(of: background) { _, new in syncBackground(new) }
    }
}

/// Tap-zone config placeholder (reader_tap_actions). Visual scheme picker.
struct ReaderTapZonesView: View {
    @AppStorage("reader_tap_scheme") private var scheme = "classic"
    private let schemes = ["classic", "lShaped", "edge", "kindleish", "disabled"]
    private func label(_ s: String) -> String {
        switch s {
        case "classic": "Classic (left/right)"
        case "lShaped": "L-shaped"
        case "edge": "Edge"
        case "kindleish": "Kindle-ish"
        default: "Disabled"
        }
    }
    var body: some View {
        List {
            Section(footer: Text("Choose how tapping regions of the screen navigates pages.")) {
                ForEach(schemes, id: \.self) { s in
                    Button { scheme = s } label: {
                        HStack {
                            Text(label(s)).foregroundStyle(DS.Color.label)
                            Spacer()
                            if scheme == s { Image(systemName: "checkmark").foregroundStyle(DS.Color.accent) }
                        }
                    }
                }
            }
        }
        .navigationTitle("Reader actions")
        .navigationBarTitleDisplayMode(.inline)
    }
}
