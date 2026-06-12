import Foundation

/// Onma — Ported automatically.
public final class Onma: MmrcmsParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "ONMA", title: "Onma", locale: "ar")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "onma.me"
        )
    }
}

/// ScanVf — Ported automatically.
public final class ScanVf: MmrcmsParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "SCANVF", title: "ScanVf", locale: "fr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "www.scan-vf.net"
        )
    }
}

/// MangaDenizi — Ported automatically.
public final class MangaDenizi: MmrcmsParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGA_DENIZI", title: "MangaDenizi", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "www.mangadenizi.net"
        )
    }
    public override var datePattern: String { "dd.MM.yyyy" }
}

