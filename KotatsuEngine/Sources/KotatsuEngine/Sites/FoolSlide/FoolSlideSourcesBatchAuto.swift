import Foundation

/// RamaReader — Ported automatically.
public final class Ramareader: FoolSlideParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "RAMAREADER", title: "RamaReader", locale: "it")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "www.ramareader.it"
        )
    }
    public override var listUrl: String { "read/directory/" }
}

/// DeathTollScans — Ported automatically.
public final class Deathtollscans: FoolSlideParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "DEATHTOLLSCANS", title: "DeathTollScans", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "reader.deathtollscans.net"
        )
    }
}

/// Seinagi — Ported automatically.
public final class Seinagi: FoolSlideParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "SEINAGI", title: "Seinagi", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "reader.seinagi.org.es"
        )
    }
}

