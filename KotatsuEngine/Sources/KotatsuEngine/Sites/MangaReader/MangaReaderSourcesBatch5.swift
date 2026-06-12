import Foundation

/// MangaJp — Ported automatically.
public final class MangaJp: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGAJP", title: "MangaJp", locale: "ja")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangajp.top",
            pageSize: 54,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// MangaMate — Ported automatically.
public final class MangaMate: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGAMATE", title: "MangaMate", locale: "ja")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "manga-mate.org",
            pageSize: 10,
            searchPageSize: 10
        )
    }
    public override var datePattern: String { "M月 d, yyyy" }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// PointZero Toons — Ported automatically.
public final class PointZeroToons: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "POINTZEROTOONS", title: "PointZero Toons", locale: "pt")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "pointzerotoons.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// MangaFlame — Ported automatically.
public final class MangaFlame: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGAFLAME", title: "MangaFlame", locale: "ar")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangaflame.org",
            pageSize: 20,
            searchPageSize: 10
        )
    }
}

/// AreaScans — Ported automatically.
public final class AreaScans: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "AREASCANS", title: "AreaScans", locale: "ar")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "ar.kenmanga.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// Fl-Ares — Ported automatically.
public final class FlAres: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "FLARES", title: "Fl-Ares", locale: "ar")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "fl-ares.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var listUrl: String { "/series" }
    public override var encodedSrc: Bool { true }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// Hijalacom — Ported automatically.
public final class Hijalacom: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "HIJALACOM", title: "Hijalacom", locale: "ar")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "hijala.com",
            pageSize: 30,
            searchPageSize: 10
        )
    }
}

/// MangaAtrend — Ported automatically.
public final class MangaAtrend: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGAATREND", title: "MangaAtrend", locale: "ar")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangaatrend.net",
            pageSize: 30,
            searchPageSize: 10
        )
    }
}

/// ArAreaScans — Ported automatically.
public final class ArAreaScans: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "ARAREASCANS", title: "ArAreaScans", locale: "ar")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "ar.kenmanga.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// Manjanoon — Ported automatically.
public final class Manjanoon: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANJANOON", title: "Manjanoon", locale: "ar")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "vrnoin.site",
            pageSize: 21,
            searchPageSize: 10
        )
    }
}

/// Sasangeyou — Ported automatically.
public final class Sasangeyou: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "SASANGEYOU", title: "Sasangeyou", locale: "id")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "sasangeyou.net",
            pageSize: 25,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// IzanamiScans — Ported automatically.
public final class IzanamiScans: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "IZANAMISCANS", title: "IzanamiScans", locale: "id")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "izanamiscans.my.id",
            pageSize: 20,
            searchPageSize: 10
        )
    }
}

/// Apkomik — Ported automatically.
public final class Apkomik: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "APKOMIK", title: "Apkomik", locale: "id")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "01.apkomik.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
}

/// BacaKomik — Ported automatically.
public final class BacaKomik: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "BACAKOMIK", title: "BacaKomik", locale: "id")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "bacakomik.my",
            pageSize: 30,
            searchPageSize: 30
        )
    }
    public override var listUrl: String { "/daftar-komik" }
    public override var selectMangaList: String { "div.animepost" }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// CosmicScans.id — Ported automatically.
public final class CosmicScans: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "COSMIC_SCANS", title: "CosmicScans.id", locale: "id")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "lc1.cosmicscans.to",
            pageSize: 30,
            searchPageSize: 30
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// SoulScans — Ported automatically.
public final class SoulScans: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "SOULSCANS", title: "SoulScans", locale: "id")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "soulscans.my.id",
            pageSize: 30,
            searchPageSize: 30
        )
    }
    public override var datePattern: String { "MMM d, yyyy" }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// MangaKita — Ported automatically.
public final class MangakKita: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGAKITA", title: "MangaKita", locale: "id")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangakita.id",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// SekaiKomik — Ported automatically.
public final class SekaikomikParser: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "SEKAIKOMIK", title: "SekaiKomik", locale: "id")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "sekaikomik.mom",
            pageSize: 20,
            searchPageSize: 100
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// Ngomik — Ported automatically.
public final class Ngomik: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "NGOMIK", title: "Ngomik", locale: "id")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "id.ngomik.cloud",
            pageSize: 20,
            searchPageSize: 5
        )
    }
}

/// Manhwaku — Ported automatically.
public final class Manhwaku: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANHWAKU", title: "Manhwaku", locale: "id")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "manhwaku.id",
            pageSize: 20,
            searchPageSize: 10
        )
    }
}

/// Shirakami — Ported automatically.
public final class Shirakami: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "SHIRAKAMI", title: "Shirakami", locale: "id")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "shirakami.xyz",
            pageSize: 10,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// KomikMama — Ported automatically.
public final class KomikMama: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "KOMIKMAMA", title: "KomikMama", locale: "id")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "komikmama.online",
            pageSize: 30,
            searchPageSize: 10
        )
    }
    public override var listUrl: String { "/komik" }
}

/// Noromax — Ported automatically.
public final class Noromax: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "NOROMAX", title: "Noromax", locale: "id")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "noromax02.my.id",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// KomikStation — Ported automatically.
public final class Komikstation: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "KOMIKSTATION", title: "KomikStation", locale: "id")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "komikstation.org",
            pageSize: 30,
            searchPageSize: 30
        )
    }
    public override var datePattern: String { "MMM d, yyyy" }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// ManhwaIndo — Ported automatically.
public final class ManhwaIndoParser: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANHWAINDO", title: "ManhwaIndo", locale: "id")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "www.manhwaindo.my",
            pageSize: 30,
            searchPageSize: 20
        )
    }
    public override var listUrl: String { "/series" }
    public override var selectMangaList: String { "div.bs" }
}

/// RimuScans — Ported automatically.
public final class RimuScans: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "RIMUSCANS", title: "RimuScans", locale: "fr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "rimuscans.com",
            pageSize: 30,
            searchPageSize: 10
        )
    }
}

/// LelManga — Ported automatically.
public final class LelManga: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "LELMANGA", title: "LelManga", locale: "fr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "www.lelmanga.com",
            pageSize: 21,
            searchPageSize: 20
        )
    }
}

/// SushiScan.Net — Ported automatically.
public final class SushiScan: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "SUSHISCAN", title: "SushiScan.Net", locale: "fr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "sushiscan.net",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var listUrl: String { "/catalogue" }
    public override var datePattern: String { "MMM d, yyyy" }
}

/// MangasScans — Ported automatically.
public final class MangasScans: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGASSCANS", title: "MangasScans", locale: "fr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangas-scans.com",
            pageSize: 30,
            searchPageSize: 10
        )
    }
}

/// MangaTv — Ported automatically.
public final class MangaTv: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGATV", title: "MangaTv", locale: "es")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "www.mangatv.net",
            pageSize: 25,
            searchPageSize: 25
        )
    }
    public override var listUrl: String { "/lista" }
    public override var datePattern: String { "yyyy-MM-dd" }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// MangaMukai.com — Ported automatically.
public final class MangaShiina: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGASHIINA", title: "MangaMukai.com", locale: "es")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangamukai.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
}

/// DtupScan — Ported automatically.
public final class DtupScan: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "DTUPSCAN", title: "DtupScan", locale: "es")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "dtupscan.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
}

/// AsiaLotuss — Ported automatically.
public final class AsiaLotuss: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "ASIALOTUSS", title: "AsiaLotuss", locale: "es")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "asialotuss.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
}

/// LectorMiau — Ported automatically.
public final class MiauScan: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MIAUSCAN", title: "LectorMiau", locale: "es")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "leemiau.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
}

/// EnryuManga — Ported automatically.
public final class EnryuManga: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "ENRYUMANGA", title: "EnryuManga", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "enryumanga.net",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// ErosScans — Ported automatically.
public final class ErosScans: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "EROSSCANS", title: "ErosScans", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "erosxscans.xyz",
            pageSize: 20,
            searchPageSize: 10
        )
    }
}

/// WitchScans — Ported automatically.
public final class WitchScans: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "WITCHSCANS", title: "WitchScans", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "altayscans.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// AstraScans — Ported automatically.
public final class AstraScans: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "ASTRASCANS", title: "AstraScans", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "astrascans.org",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var listUrl: String { "/series" }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// Lagoon Scans — Ported automatically.
public final class LagoonScans: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "LAGOONSCANS", title: "Lagoon Scans", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "lagoonscans.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
}

/// NightScans — Ported automatically.
public final class Nightscans: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "NIGHTSCANS", title: "NightScans", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "nightsup.net",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var listUrl: String { "/series" }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// VarnaScan — Ported automatically.
public final class VarnaScan: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "VARNASCAN", title: "VarnaScan", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "varnascan.xyz",
            pageSize: 20,
            searchPageSize: 10
        )
    }
}

/// Greed Scans — Ported automatically.
public final class GreedScans: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "GREEDSCANS", title: "Greed Scans", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "greedscans.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
}

/// Madara Scans — Ported automatically.
public final class MadaraScans: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MADARASCANS", title: "Madara Scans", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "madarascans.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var listUrl: String { "/series" }
    public override var datePattern: String { "yyyy/MM/dd" }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// ReadKomik — Ported automatically.
public final class Readkomik: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "READKOMIK", title: "ReadKomik", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "novelstreams.com",
            pageSize: 20,
            searchPageSize: 20
        )
    }
    public override var datePattern: String { "MMM d, yyyy" }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// KingOfScans — Ported automatically.
public final class FuryManga: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "FURYMANGA", title: "KingOfScans", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "myshojo.com",
            pageSize: 30,
            searchPageSize: 10
        )
    }
    public override var listUrl: String { "/comics" }
}

/// RavenScans — Ported automatically.
public final class RavenScans: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "RAVENSCANS", title: "RavenScans", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "ravenscans.org",
            pageSize: 10,
            searchPageSize: 10
        )
    }
    public override var datePattern: String { "MMM d, yyyy" }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// XCalibrScans — Ported automatically.
public final class XCalibrScans: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "XCALIBRSCANS", title: "XCalibrScans", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "xcalibrscans.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// TecnoScans — Ported automatically.
public final class TecnoScans: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "TECNOSCANS", title: "TecnoScans", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "olyteconscans.xyz",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// MyShojo — Ported automatically.
public final class MyShojo: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MYSHOJO", title: "MyShojo", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "myshojo.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// CypherScans — Ported automatically.
public final class CypherScans: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "CYPHERSCANS", title: "CypherScans", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "cypheroscans.xyz",
            pageSize: 20,
            searchPageSize: 10
        )
    }
}

/// Arenascans — Ported automatically.
public final class ArenaScans: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "ARENASCANS", title: "Arenascans", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "arenascan.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
}

/// ManhwaFreake — Ported automatically.
public final class ManhwaFreake: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANHWAFREAKE", title: "ManhwaFreake", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "manhwafreake.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var listUrl: String { "/series" }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// Snow Machine Translation — Ported automatically.
public final class SnowMachineTranslation: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "SNOWMACHINETRANSLATION", title: "Snow Machine Translation", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "snowmachinetranslation.com",
            pageSize: 24,
            searchPageSize: 10
        )
    }
    public override var listUrl: String { "/manga" }
}

/// Elftoon — Ported automatically.
public final class Elftoon: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "ELFTOON", title: "Elftoon", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "elftoon.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
}

/// ToonHunter — Ported automatically.
public final class ToonHunterParser: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "TOONHUNTER", title: "ToonHunter", locale: "th")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "toonhunter.com",
            pageSize: 30,
            searchPageSize: 10
        )
    }
    public override var datePattern: String { "MMM d, yyyy" }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// PopsManga — Ported automatically.
public final class PopsManga: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "POPSMANGA", title: "PopsManga", locale: "th")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "popsmanga.com",
            pageSize: 20,
            searchPageSize: 14
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// ReaperTrans — Ported automatically.
public final class ReaperTrans: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "REAPERTRANS", title: "ReaperTrans", locale: "th")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "reapertrans.com",
            pageSize: 30,
            searchPageSize: 14
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// Makimaaaaa — Ported automatically.
public final class Makimaaaaa: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MAKIMAAAAA", title: "Makimaaaaa", locale: "th")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "makimaaaaa.com",
            pageSize: 30,
            searchPageSize: 30
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// Manga689 — Ported automatically.
public final class Manga689: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGA689", title: "Manga689", locale: "th")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "manga689.com",
            pageSize: 45,
            searchPageSize: 21
        )
    }
    public override var listUrl: String { "/read" }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// MafiaManga — Ported automatically.
public final class MafiaManga: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MAFIAMANGA", title: "MafiaManga", locale: "th")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mafia-manga.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// ThaiManga — Ported automatically.
public final class ThaiManga: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "THAIMANGA", title: "ThaiManga", locale: "th")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "www.thaimanga.net",
            pageSize: 40,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// LamiManga — Ported automatically.
public final class LamiManga: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "LAMIMANGA", title: "LamiManga", locale: "th")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangalami.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// InuManga — Ported automatically.
public final class InuManga: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "INUMANGA", title: "InuManga", locale: "th")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "www.inu-manga.com",
            pageSize: 40,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// MangaKimi — Ported automatically.
public final class MangaKimi: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGAKIMI", title: "MangaKimi", locale: "th")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "www.mangakimi.com",
            pageSize: 40,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// SereinScan — Ported automatically.
public final class SereinScan: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "SEREINSCAN", title: "SereinScan", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "sereinscan.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
}

/// GolgeBahcesi — Ported automatically.
public final class Golgebahcesi: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "GOLGEBAHCESI", title: "GolgeBahcesi", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "golgebahcesi.com",
            pageSize: 14,
            searchPageSize: 9
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// SummerToon — Ported automatically.
public final class SummerToon: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "SUMMERTOON", title: "SummerToon", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "summertoon.co",
            pageSize: 10,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// MangaOkuTr — Ported automatically.
public final class Mangaokutr: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGAOKUTR", title: "MangaOkuTr", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangaokutr.net",
            pageSize: 25,
            searchPageSize: 20
        )
    }
}

/// TarotScans — Ported automatically.
public final class TarotScans: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "TAROTSCANS", title: "TarotScans", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "www.tarotscans.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// ShijieScans — Ported automatically.
public final class ShijieScans: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "SHIJIESCANS", title: "ShijieScans", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "shijiescans.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var listUrl: String { "/seri" }
}

/// AduManga — Ported automatically.
public final class AduManga: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "ADUMANGA", title: "AduManga", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "adumanga.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// TempestScans — Ported automatically.
public final class TempestScans: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "TEMPESTSCANS", title: "TempestScans", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "adumanga.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// PatiManga — Ported automatically.
public final class PatiManga: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "PATIMANGA", title: "PatiManga", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "www.patimanga.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// ZenithScans — Ported automatically.
public final class ZenithScans: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "ZENITHSCANS", title: "ZenithScans", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "zenithscans.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// MangaKoleji — Ported automatically.
public final class MangaKoleji: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGAKOLEJI", title: "MangaKoleji", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangakoleji.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// MangaKings — Ported automatically.
public final class MangaKings: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGAKINGS", title: "MangaKings", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangakings.com.tr",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// Gafeland — Ported automatically.
public final class Gafeland: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "GAFELAND", title: "Gafeland", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "www.gafeland.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// GaiaToon — Ported automatically.
public final class GaiaToon: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "GAIATOON", title: "GaiaToon", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "gaiatoon.com",
            pageSize: 50,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// AthenaManga — Ported automatically.
public final class AthenaManga: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "ATHENAMANGA", title: "AthenaManga", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "athenamanga.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// AyaToon — Ported automatically.
public final class Ayatoon: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "AYATOON", title: "AyaToon", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "ayatoon.com",
            pageSize: 20,
            searchPageSize: 20
        )
    }
    public override var filterCapabilities: MangaListFilterCapabilities {
        MangaListFilterCapabilities(
            isMultipleTagsSupported: true,
            isTagsExclusionSupported: false,
            isSearchSupported: true
        )
    }
}

/// AsemiFansub — Ported automatically.
public final class AsemiFansub: MangaReaderParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "ASEMIFANSUB", title: "AsemiFansub", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "asemifansub.com",
            pageSize: 20,
            searchPageSize: 10
        )
    }
}

