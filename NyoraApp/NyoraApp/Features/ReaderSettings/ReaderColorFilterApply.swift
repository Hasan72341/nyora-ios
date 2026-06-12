import SwiftUI

// MARK: - Reader color-correction application
//
// Reads the same compact-encoded keys that `ColorCorrectionConfigView` writes
// ("readerColorFilter.<mangaKey>" for per-manga, "readerColorFilterGlobal" for global)
// and turns the effective `ReaderColorFilter` into SwiftUI view modifiers that visibly
// recolor the page images in BOTH paged (ZoomableImage) and webtoon (RemoteImage) modes.
//
// SwiftUI's brightness/contrast/saturation/colorInvert/colorMultiply modifiers composite
// the rendered child content (including UIViewRepresentable-backed images), so they apply
// uniformly to the actual page pixels — no need to touch ZoomableImage/RemoteImage.
//
// Apply order mirrors Android `ReaderColorFilter`: tone (multitone/grayscale) -> invert ->
// brightness -> contrast -> book effect.

extension ReaderColorFilter {
    /// Decode the effective filter for a manga: per-manga override (if non-empty) else global.
    static func effective(mangaKey: String) -> ReaderColorFilter {
        let defaults = UserDefaults.standard
        if let raw = defaults.string(forKey: "readerColorFilter.\(mangaKey)"),
           let f = ColorCorrectionConfigView.decode(raw), !f.isEmpty {
            return f
        }
        if let raw = defaults.string(forKey: "readerColorFilterGlobal"),
           let f = ColorCorrectionConfigView.decode(raw) {
            return f
        }
        return ReaderColorFilter()
    }

    /// A multiply tint approximating a multitone preset's dominant hue, or nil for "None".
    /// Full multitone gradients aren't expressible as a single SwiftUI modifier, so we map
    /// each preset to a representative tint so pages still visibly shift toward the preset.
    var presetTint: Color? {
        switch preset.trimmingCharacters(in: .whitespaces) {
        case "None", "": return nil
        case "Sepia", "Vintage", "Copper", "Autumn", "Terracotta": return Color(red: 0.90, green: 0.78, blue: 0.58)
        case "Slate", "Arctic", "Abyss": return Color(red: 0.72, green: 0.80, blue: 0.90)
        case "Cyberpunk", "Synthwave", "Vaporwave", "Glitch": return Color(red: 0.95, green: 0.65, blue: 0.95)
        case "Emerald", "Sage", "Meadow", "Canopy", "Jungle": return Color(red: 0.65, green: 0.90, blue: 0.70)
        case "Sunset", "Sakura", "Candy", "Pastel": return Color(red: 0.98, green: 0.72, blue: 0.78)
        case "Biolum", "Aurora", "Thermal", "Acid", "Prism": return Color(red: 0.70, green: 0.95, blue: 0.85)
        default: return Color(red: 0.85, green: 0.82, blue: 0.92)
        }
    }
}

/// Applies the reader color filter to whatever it wraps. No-op when the filter is empty.
struct ReaderColorFilterModifier: ViewModifier {
    let filter: ReaderColorFilter

    func body(content: Content) -> some View {
        content
            // Tone: grayscale, then optional preset tint via multiply.
            .saturation(filter.grayscale ? 0 : 1)
            .modifier(OptionalMultiply(color: filter.preset == "None" ? nil : filter.presetTint))
            // Invert.
            .modifier(OptionalInvert(on: filter.invert))
            // Brightness (-1...1 maps directly to SwiftUI .brightness).
            .brightness(filter.brightness)
            // Contrast (-1...1 -> 0...2, 0 == unchanged).
            .contrast(1 + filter.contrast)
            // Book effect: warm, slightly dimmed paper look.
            .modifier(OptionalMultiply(color: filter.bookEffect ? Color(red: 0.96, green: 0.93, blue: 0.84) : nil))
    }
}

private struct OptionalMultiply: ViewModifier {
    let color: Color?
    func body(content: Content) -> some View {
        if let color { content.colorMultiply(color) } else { content }
    }
}

private struct OptionalInvert: ViewModifier {
    let on: Bool
    func body(content: Content) -> some View {
        if on { content.colorInvert() } else { content }
    }
}

extension View {
    /// Apply the effective reader color filter for the given manga key.
    func readerColorFilter(_ filter: ReaderColorFilter) -> some View {
        modifier(ReaderColorFilterModifier(filter: filter))
    }
}
