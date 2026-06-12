import SwiftUI

/// Advanced reader settings, mirroring nyora-android's reader configuration.
///
/// Each multi-choice setting is a `String`-backed `RawRepresentable` enum so it can be stored
/// directly via `@AppStorage`. Boolean settings use plain `@AppStorage(... ) Bool`. The reader
/// (`Views/ReaderView.swift`) reads these same keys to honor the user's choices — see
/// `ReaderSettingsView`'s footers and the integration notes for exactly how each maps.

// MARK: - Setting enums

/// Page turn / scroll direction for the paged reader.
enum ReadingDirection: String, CaseIterable, Identifiable {
    case ltr   // left → right (default for western comics)
    case rtl   // right → left (traditional manga)

    var id: String { rawValue }

    var label: String {
        switch self {
        case .ltr: return "Left to right"
        case .rtl: return "Right to left (manga)"
        }
    }
}

/// How each page image is scaled to fit the screen.
enum PageFit: String, CaseIterable, Identifiable {
    case fit        // whole page visible (aspect fit)
    case fillWidth  // fill the screen width (aspect fill, may crop top/bottom)

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fit: return "Fit page"
        case .fillWidth: return "Fill width"
        }
    }

    /// Convenience for the reader: maps to a SwiftUI content mode.
    var contentMode: ContentMode {
        switch self {
        case .fit: return .fit
        case .fillWidth: return .fill
        }
    }
}

/// Background color shown behind page images.
enum ReaderBackground: String, CaseIterable, Identifiable {
    case black
    case white
    case sepia

    var id: String { rawValue }

    var label: String {
        switch self {
        case .black: return "Black"
        case .white: return "White"
        case .sepia: return "Sepia"
        }
    }

    /// The color to render behind the pages.
    var color: Color {
        switch self {
        case .black: return .black
        case .white: return .white
        case .sepia: return Color(red: 0.96, green: 0.91, blue: 0.78)
        }
    }

    /// Tint for chrome/spinners so they stay legible on the chosen background.
    var foreground: Color {
        switch self {
        case .black: return .white
        case .white, .sepia: return .black
        }
    }
}

// MARK: - Settings view

/// A `Form` of pickers and toggles bound to the reader's `@AppStorage` keys. The reader reads
/// the same keys, so changes here take effect the next time a page is shown.
struct ReaderSettingsView: View {
    @AppStorage("readerDirection") private var direction: ReadingDirection = .ltr
    @AppStorage("readerPageFit") private var pageFit: PageFit = .fit
    @AppStorage("readerBackground") private var background: ReaderBackground = .black
    @AppStorage("readerKeepScreenOn") private var keepScreenOn = false
    @AppStorage("readerTapToTurn") private var tapToTurn = true

    var body: some View {
        Form {
            Section {
                Picker("Reading direction", selection: $direction) {
                    ForEach(ReadingDirection.allCases) { Text($0.label).tag($0) }
                }
            } footer: {
                Text("Choose left-to-right for western comics, or right-to-left for traditional manga. Affects which way pages turn in paged mode.")
            }

            Section {
                Picker("Page fit", selection: $pageFit) {
                    ForEach(PageFit.allCases) { Text($0.label).tag($0) }
                }
            } footer: {
                Text("Fit page shows the whole page on screen. Fill width zooms each page to the screen width, which may crop the top and bottom.")
            }

            Section {
                Picker("Background", selection: $background) {
                    ForEach(ReaderBackground.allCases) { Text($0.label).tag($0) }
                }
            } footer: {
                Text("The color shown behind page images and in letterboxed areas.")
            }

            Section {
                Toggle("Tap to turn page", isOn: $tapToTurn)
            } footer: {
                Text("When on, tapping the left or right edge of the screen turns the page. When off, only swiping turns pages and a single tap toggles the controls.")
            }

            Section {
                Toggle("Keep screen on", isOn: $keepScreenOn)
            } footer: {
                Text("Prevents the screen from dimming or locking while the reader is open.")
            }
        }
        .navigationTitle("Reader settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { ReaderSettingsView() }
}
