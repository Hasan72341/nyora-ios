import Foundation

/// NetTruyenHE — Ported automatically.
public final class NetTruyenHE: WpComicsParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "NETTRUYENHE", title: "NetTruyenHE", locale: "vi")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "nettruyenhe.com"
        )
    }
    public override var listUrl: String { "/tim-kiem-nang-cao" }
}

/// NetTruyenVie — Ported automatically.
public final class NetTruyenVie: WpComicsParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "NETTRUYENVIE", title: "NetTruyenVie", locale: "vi")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "nettruyenvia.com"
        )
    }
}

/// NewTruyen — Ported automatically.
public final class NewTruyen: WpComicsParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "NEWTRUYEN", title: "NewTruyen", locale: "vi")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "newtruyentranh4.com"
        )
    }
}

/// DocTruyen3Q — Ported automatically.
public final class DocTruyen3Q: WpComicsParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "DOCTRUYEN3Q", title: "DocTruyen3Q", locale: "vi")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "doctruyen3qui15.pro"
        )
    }
    public override var datePattern: String { "dd/MM/yyyy" }
}

/// NhatTruyenVN — Ported automatically.
public final class NhatTruyenVN: WpComicsParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "NHATTRUYENVN", title: "NhatTruyenVN", locale: "vi")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "nhattruyenqq.com"
        )
    }
}

/// MangaRaw — Ported automatically.
public final class MangaRaw: WpComicsParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGARAW", title: "MangaRaw", locale: "ja")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangaraw.best"
        )
    }
    public override var listUrl: String { "/search/manga" }
}

