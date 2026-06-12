import Foundation

/// MangaHona — Ported automatically.
public final class MangaHona: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGAHONA", title: "MangaHona", locale: "pl")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangahona.pl"
        )
    }
    public override var datePattern: String { "yyyy-MM-dd" }
}

/// Truyện Tranh Đam Mỹ — Ported automatically.
public final class TruyenTranhDamMyy: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "TRUYENTRANHDAMMYY", title: "Truyện Tranh Đam Mỹ", locale: "vi")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "truyentranhdammyy.site"
        )
    }
}

/// MangaMammy — Ported automatically.
public final class MangaMammy: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGAMAMMY", title: "MangaMammy", locale: "ru")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangamammy.ru"
        )
    }
    public override var datePattern: String { "dd.MM.yyyy" }
}

/// FayScans — Ported automatically.
public final class FayScans: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "FAYSCANS", title: "FayScans", locale: "pt")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "fayscans.net"
        )
    }
}

/// MugiwarasOficial — Ported automatically.
public final class MugiwarasOficial: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MUGIWARASOFICIAL", title: "MugiwarasOficial", locale: "pt")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mugiwarasoficial.com"
        )
    }
}

/// ArthurScan — Ported automatically.
public final class ArthurScan: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "ARTHUR_SCAN", title: "ArthurScan", locale: "pt")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "arthurscan.xyz"
        )
    }
}

/// Manga Livre — Ported automatically.
public final class MangaLivre: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGALIVRE", title: "Manga Livre", locale: "pt")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangalivre.tv"
        )
    }
    public override var datePattern: String { "MMMM dd, yyyy" }
}

/// NinjaComics — Ported automatically.
public final class NinjaScan: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "NINJASCAN", title: "NinjaComics", locale: "pt")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "ninjacomics.xyz"
        )
    }
}

/// CrystalComics — Ported automatically.
public final class CrystalScan: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "CRYSTALSCAN", title: "CrystalComics", locale: "pt")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "crystalcomics.com"
        )
    }
}

/// YanpFansub — Ported automatically.
public final class YanpFansub: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "YANPFANSUB", title: "YanpFansub", locale: "pt")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "trisalyanp.com"
        )
    }
    public override var datePattern: String { "d 'de' MMMM 'de' yyyy" }
}

/// SsReading — Ported automatically.
public final class SsReading: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "SSREADING", title: "SsReading", locale: "pt")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "ssreading.com.br"
        )
    }
}

/// PassamaoScan — Ported automatically.
public final class PassamaoScan: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "PASSAMAOSCAN", title: "PassamaoScan", locale: "pt")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "passamaoscan.com"
        )
    }
}

/// XsScan — Ported automatically.
public final class XsScan: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "XSSCAN", title: "XsScan", locale: "pt")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "xsscan.xyz"
        )
    }
}

/// MiniTwoScan — Ported automatically.
public final class MiniTwoScan: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MINITWOSCAN", title: "MiniTwoScan", locale: "pt")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "minitwoscan.com"
        )
    }
}

/// NirvanaScan — Ported automatically.
public final class NirvanaScan: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "NIRVANASCAN", title: "NirvanaScan", locale: "pt")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "nirvanascan.com"
        )
    }
}

/// Kalango — Ported automatically.
public final class Kalango: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "KALANGO", title: "Kalango", locale: "pt")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "kalango.org"
        )
    }
}

/// WonderlandScan — Ported automatically.
public final class WonderlandScan: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "WONDERLANDSCAN", title: "WonderlandScan", locale: "pt")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "wonderlandscan.com"
        )
    }
}

/// ArcticScan — Ported automatically.
public final class ArcticScan: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "ARCTICSCAN", title: "ArcticScan", locale: "pt")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "arcticscan.top"
        )
    }
}

/// LimboScan — Ported automatically.
public final class LimboScan: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "LIMBOSCAN", title: "LimboScan", locale: "pt")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "limboscan.com.br"
        )
    }
}

/// SweetScan — Ported automatically.
public final class SweetScan: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "SWEETSCAN", title: "SweetScan", locale: "pt")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "sweetscan.net"
        )
    }
}

/// PlumaComics — Ported automatically.
public final class PlumaComics: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "PLUMACOMICS", title: "PlumaComics", locale: "pt")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "plumacomics.cloud"
        )
    }
}

/// Atemporal — Ported automatically.
public final class Atemporal: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "ATEMPORAL", title: "Atemporal", locale: "pt")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "atemporal.cloud"
        )
    }
}

/// DreamScan — Ported automatically.
public final class DreamScan: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "DREAMSCAN", title: "DreamScan", locale: "pt")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "fairydream.com.br"
        )
    }
}

/// HikariScan — Ported automatically.
public final class HikariScan: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "HIKARISCAN", title: "HikariScan", locale: "pt")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "hikariscan.org"
        )
    }
}

/// LekMangaCom — Ported automatically.
public final class LekMangaCom: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "LEKMANGACOM", title: "LekMangaCom", locale: "ar")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "lekmanga.com"
        )
    }
}

/// 3Asq — Ported automatically.
public final class Asq: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "ASQORG", title: "3Asq", locale: "ar")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "3asq.org"
        )
    }
    public override var datePattern: String { "d MMMM، yyyy" }
}

/// RocksManga — Ported automatically.
public final class RocksManga: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "ROCKSMANGA", title: "RocksManga", locale: "ar")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "rocksmanga.com"
        )
    }
    public override var datePattern: String { "d MMMM yyyy" }
}

/// Gmanga — Ported automatically.
public final class Gmanga: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "GMANGA", title: "Gmanga", locale: "ar")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "gmanga.site"
        )
    }
}

/// Olaoe — Ported automatically.
public final class Olaoe: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "OLAOE", title: "Olaoe", locale: "ar")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "olaoe.cyou"
        )
    }
    public override var datePattern: String { "dd-MM-yyyy" }
}

/// PojokManga — Ported automatically.
public final class PojokManga: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "POJOKMANGA", title: "PojokManga", locale: "id")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "pojokmanga.info"
        )
    }
    public override var datePattern: String { "MMM d, yyyy" }
}

/// Holotoon — Ported automatically.
public final class Holotoon: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "HOTOON", title: "Holotoon", locale: "id")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "01.holotoon.site"
        )
    }
}

/// Roseveil — Ported automatically.
public final class Roseveil: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "ROSEVEIL", title: "Roseveil", locale: "id")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "roseveil.org"
        )
    }
    public override var datePattern: String { "MMMM dd, yyyy" }
}

/// LumosKomik — Ported automatically.
public final class LumosKomik: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "LUMOSKOMIK", title: "LumosKomik", locale: "id")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "02.lumosgg.com"
        )
    }
    public override var datePattern: String { "dd MMMM yyyy" }
}

/// Hwago — Ported automatically.
public final class Hwago: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "HWAGO", title: "Hwago", locale: "id")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "01.hwago.xyz"
        )
    }
    public override var datePattern: String { "d MMMM yyyy" }
}

/// HarmonyScan — Ported automatically.
public final class HarmonyScan: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "HARMONYSCAN", title: "HarmonyScan", locale: "fr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "harmony-scan.fr"
        )
    }
}

/// PantheonScan.com — Ported automatically.
public final class PantheonScan: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "PANTHEONSCAN", title: "PantheonScan.com", locale: "fr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "pantheon-scan.com"
        )
    }
    public override var datePattern: String { "d MMMM yyyy" }
}

/// MangasOrigines.fr — Ported automatically.
public final class MangasOrigines: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGASORIGINES", title: "MangasOrigines.fr", locale: "fr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangas-origines.fr"
        )
    }
    public override var datePattern: String { "dd/MM/yyyy" }
}

/// MangaScantrad.io — Ported automatically.
public final class MangaScantrad: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGA_SCANTRAD", title: "MangaScantrad.io", locale: "fr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "manga-scantrad.io"
        )
    }
    public override var datePattern: String { "d MMMM yyyy" }
}

/// MhScans — Ported automatically.
public final class MhScans: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MHSCANS", title: "MhScans", locale: "es")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mhscans.mundoalterno.org"
        )
    }
    public override var datePattern: String { "d 'de' MMMMM 'de' yyyy" }
}

/// TerritorioLeal — Ported automatically.
public final class TerritorioLeal: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "TERRITORIOLEAL", title: "TerritorioLeal", locale: "es")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "territorioleal.com"
        )
    }
    public override var datePattern: String { "d 'de' MMMM 'de' yyyy" }
}

/// Lector KNS — Ported automatically.
public final class KnightnoScanlation: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "KNIGHTNOSCANLATION", title: "Lector KNS", locale: "es")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "lectorknight.com"
        )
    }
}

/// HerenScan — Ported automatically.
public final class HerenScan: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "HERENSCAN", title: "HerenScan", locale: "es")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "herenscan.com"
        )
    }
    public override var datePattern: String { "dd/MM/yyyy" }
}

/// MangaCrab — Ported automatically.
public final class MangaCrab: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGA_CRAB", title: "MangaCrab", locale: "es")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangacrab.org"
        )
    }
    public override var datePattern: String { "dd/MM/yyyy" }
}

/// MantrazScan — Ported automatically.
public final class MantrazScan: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANTRAZSCAN", title: "MantrazScan", locale: "es")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mantrazscan.org"
        )
    }
    public override var datePattern: String { "dd/MM/yyyy" }
}

/// RichtoScan — Ported automatically.
public final class RichtoScan: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "RICHTOSCAN", title: "RichtoScan", locale: "es")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "r1.richtoon.top"
        )
    }
}

/// InmortalScan — Ported automatically.
public final class MangaMundoDrama: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGAMUNDODRAMA", title: "InmortalScan", locale: "es")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "scaninmortal.com"
        )
    }
}

/// ManhwaOnline — Ported automatically.
public final class ManhwaOnline: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANHWAONLINE", title: "ManhwaOnline", locale: "es")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "manhwa-online.com"
        )
    }
    public override var datePattern: String { "MMMM dd, yyyy" }
}

/// EmperorScan — Ported automatically.
public final class EmperorScan: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "EMPERORSCAN", title: "EmperorScan", locale: "es")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "imperiomanhua.com"
        )
    }
    public override var datePattern: String { "MMMM dd, yyyy" }
}

/// SapphireScan — Ported automatically.
public final class SapphireScan: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "SAPPHIRESCAN", title: "SapphireScan", locale: "es")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "sapphirescan.com"
        )
    }
}

/// MangasNoSekai — Ported automatically.
public final class MangasNoSekai: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGASNOSEKAI", title: "MangasNoSekai", locale: "es")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangasnosekai.com"
        )
    }
}

/// LectorManga — Ported automatically.
public final class LectorManga: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "LECTORMANGA", title: "LectorManga", locale: "es")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "lectormangaa.com"
        )
    }
}

/// BegaTranslation — Ported automatically.
public final class BegaTranslation: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "BEGATRANSLATION", title: "BegaTranslation", locale: "es")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "begatranslation.com"
        )
    }
    public override var datePattern: String { "dd/MM/yyyy" }
}

/// BarManga — Ported automatically.
public final class BarManga: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "BARMANGA", title: "BarManga", locale: "es")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "barmanga.com"
        )
    }
    public override var datePattern: String { "MM/dd/yyyy" }
}

/// Bokugents — Ported automatically.
public final class Bokugents: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "BOKUGENTS", title: "Bokugents", locale: "es")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "bokugents.com"
        )
    }
}

/// NoblesseTranslations — Ported automatically.
public final class NoblesseTranslations: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "NOBLESSETRANSLATIONS", title: "NoblesseTranslations", locale: "es")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "nobledicion.yoveo.xyz"
        )
    }
}

/// RagnarokScanlation — Ported automatically.
public final class RagnarokScanlation: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "RAGNAROKSCANLATION", title: "RagnarokScanlation", locale: "es")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "ragnarokscanlation.org"
        )
    }
}

/// TaurusManga — Ported automatically.
public final class TaurusManga: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "TAURUSMANGA", title: "TaurusManga", locale: "es")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "taurus.topmanhuas.org"
        )
    }
    public override var datePattern: String { "dd/MM/yyyy" }
}

/// MangaRock.team — Ported automatically.
public final class MangaRockTeam: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGAROCKTEAM", title: "MangaRock.team", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangarockteam.com"
        )
    }
}

/// ManhuaTop — Ported automatically.
public final class TopManhua: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "TOPMANHUA", title: "ManhuaTop", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "manhuatop.org"
        )
    }
    public override var datePattern: String { "MM/dd/yyyy" }
}

/// GourmetScans — Ported automatically.
public final class GourmetScans: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "GOURMETSCANS", title: "GourmetScans", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "gourmetsupremacy.com"
        )
    }
}

/// MangaTyrant — Ported automatically.
public final class MangaTyrant: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGATYRANT", title: "MangaTyrant", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangatyrant.com"
        )
    }
}

/// FactManga — Ported automatically.
public final class FactManga: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "FACTMANGA", title: "FactManga", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "factmanga.com"
        )
    }
}

/// ManhuaManhwa — Ported automatically.
public final class ManhuaManhwa: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANHUAMANHWA", title: "ManhuaManhwa", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "manhuamanhwa.com"
        )
    }
    public override var datePattern: String { "MM/dd/yyyy" }
}

/// ManhwaFull — Ported automatically.
public final class ManhwaFull: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANHWAFULL", title: "ManhwaFull", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "manhwafull.com"
        )
    }
    public override var datePattern: String { "MM/dd/yyyy" }
}

/// Manga1st — Ported automatically.
public final class Manga1st: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGA1ST", title: "Manga1st", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "manga1st.online"
        )
    }
    public override var datePattern: String { "d MMMM، yyyy" }
}

/// MangaRolls — Ported automatically.
public final class MangaRolls: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGAROLLS", title: "MangaRolls", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangarolls.net"
        )
    }
}

/// TopReadManhwa — Ported automatically.
public final class TopReadManhwa: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "TOPREADMANHWA", title: "TopReadManhwa", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "topreadmanhwa.com"
        )
    }
    public override var datePattern: String { "MM/dd/yyyy" }
}

/// ParagonScans — Ported automatically.
public final class IsekaiScanEuParser: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "ISEKAISCAN_EU", title: "ParagonScans", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "paragonscans.com"
        )
    }
    public override var datePattern: String { "MM/dd/yyyy" }
}

/// Manhuauss — Ported automatically.
public final class Manhuauss: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANHUAUSS", title: "Manhuauss", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "manhuauss.com"
        )
    }
}


/// SectScans — Ported automatically.
public final class SectScans: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "SECTSCANS", title: "SectScans", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "sectscans.com"
        )
    }
}

/// WebDexScans — Ported automatically.
public final class WebDexScans: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "WEBDEXSCANS", title: "WebDexScans", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "webdexscans.com"
        )
    }
}

/// FreeMangaTop — Ported automatically.
public final class FreeMangaTop: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "FREEMANGATOP", title: "FreeMangaTop", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "freemangatop.com"
        )
    }
    public override var datePattern: String { "MM/dd/yyyy" }
}

/// UToon — Ported automatically.
public final class UToon: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "UTOON", title: "UToon", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "utoon.net"
        )
    }
    public override var datePattern: String { "dd MMM" }
}

/// MangaFast.net — Ported automatically.
public final class MangaFastNet: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGAFASTNET", title: "MangaFast.net", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "manhuafast.net"
        )
    }
}

/// ManhuaZone — Ported automatically.
public final class ManhuaZone: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANHUAZONE", title: "ManhuaZone", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "manhuazone.org"
        )
    }
}

/// Philia Scans — Ported automatically.
public final class PhiliaScans: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "PHILIASCANS", title: "Philia Scans", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "philiascans.org"
        )
    }
}

/// Shooting Star Scans — Ported automatically.
public final class ShootingStarScans: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "SHOOTINGSTARSCANS", title: "Shooting Star Scans", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "shootingstarscans.com"
        )
    }
}

/// ManhwaSco — Ported automatically.
public final class Manhwasco: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANHWASCO", title: "ManhwaSco", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "manhwasco.net"
        )
    }
}

/// ManhuaZonghe — Ported automatically.
public final class ManhuaZonghe: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANHUAZONGHE", title: "ManhuaZonghe", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "www.manhuazonghe.com"
        )
    }
}

/// AsuraScansGg — Ported automatically.
public final class AsuraScansGg: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "ASURASCANSGG", title: "AsuraScansGg", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "asurascans.us"
        )
    }
}

/// SiteManga — Ported automatically.
public final class SiteManga: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "SITEMANGA", title: "SiteManga", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "sitemanga.com"
        )
    }
    public override var datePattern: String { "MM/dd/yyyy" }
}

/// ZinManga.net — Ported automatically.
public final class Zinmanga: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "ZINMANGA", title: "ZinManga.net", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "zinmanga.net"
        )
    }
    public override var datePattern: String { "MM/dd/yyyy" }
}

/// S2Manga.io — Ported automatically.
public final class JiManga: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "JIMANGA", title: "S2Manga.io", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "s2manga.io"
        )
    }
}

/// AryaScans — Ported automatically.
public final class AryaScans: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "ARYASCANS", title: "AryaScans", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "aryascans.com"
        )
    }
}

/// ManhuaUs — Ported automatically.
public final class Manhuaus: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANHUAUS", title: "ManhuaUs", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "manhuaus.com"
        )
    }
}

/// MangaRock — Ported automatically.
public final class MangaRock: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGAROCK", title: "MangaRock", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangarockteam.com"
        )
    }
    public override var datePattern: String { "MMMM dd, yyyy" }
}

/// ManhwaManhua — Ported automatically.
public final class ManhwaManhua: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANHWAMANHUA", title: "ManhwaManhua", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "manhwamanhua.com"
        )
    }
}

/// YakshaComics — Ported automatically.
public final class YakshaComics: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "YAKSHACOMICS", title: "YakshaComics", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "yakshacomics.com"
        )
    }
}

/// MangaGg — Ported automatically.
public final class Mangagg: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGAGG", title: "MangaGg", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangagg.com"
        )
    }
    public override var datePattern: String { "MM/dd/yyyy" }
}

/// Zin-Manga.com — Ported automatically.
public final class ZinMangaCom: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "ZIN_MANGA_COM", title: "Zin-Manga.com", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "zin-manga.com"
        )
    }
}

/// MangaFoxFull — Ported automatically.
public final class MangaFoxFull: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGAFOXFULL", title: "MangaFoxFull", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangafoxfull.com"
        )
    }
}

/// FreeManga — Ported automatically.
public final class FreeManga: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "FREEMANGA", title: "FreeManga", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "freemanga.me"
        )
    }
    public override var datePattern: String { "MMMM dd, yyyy" }
}

/// Retsu — Ported automatically.
public final class KumaScans: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "KUMASCANS", title: "Retsu", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "retsu.org"
        )
    }
}

/// ManhuaEs — Ported automatically.
public final class Manhuaes: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANHUAES", title: "ManhuaEs", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "manhuaes.com"
        )
    }
}

/// MangaEclipse — Ported automatically.
public final class MangaEclipse: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGAECLIPSE", title: "MangaEclipse", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangaeclipse.com"
        )
    }
}

/// Babelwuxia — Ported automatically.
public final class Babelwuxia: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "BABELWUXIA", title: "Babelwuxia", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "babelwuxia.com"
        )
    }
}

/// MangaRead — Ported automatically.
public final class MangaRead: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGAREAD", title: "MangaRead", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "www.mangaread.org"
        )
    }
    public override var datePattern: String { "dd.MM.yyyy" }
}

/// AsuraScans.us — Ported automatically.
public final class AsuraScansUs: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "ASURASCANS_US", title: "AsuraScans.us", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "asurascans.us"
        )
    }
}

/// MangaEmpress — Ported automatically.
public final class MangaTxUnofficial: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGATXUNOFFICIAL", title: "MangaEmpress", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangaempress.com"
        )
    }
}

/// MangaTx.gg — Ported automatically.
public final class MangaTxGg: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGATX_GG", title: "MangaTx.gg", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangatx.gg"
        )
    }
}

/// ManhuaGa — Ported automatically.
public final class Manhuaga: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANHUAGA", title: "ManhuaGa", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "manhuaga.com"
        )
    }
}

/// ManhwaBreakup — Ported automatically.
public final class ManhwaBreakup: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANHWABREAKUP", title: "ManhwaBreakup", locale: "th")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "www.manhwabreakup.com"
        )
    }
    public override var datePattern: String { "MMMM dd, yyyy" }
}

/// TrMangaOku — Ported automatically.
public final class TrMangaOku: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "TRMANGAOKU", title: "TrMangaOku", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "trmangaoku.com"
        )
    }
}

/// MangaTr — Ported automatically.
public final class MangaTr: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGATR", title: "MangaTr", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangatr.app"
        )
    }
}

/// MangaWt.net — Ported automatically.
public final class MangaWtNet: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGAWT_NET", title: "MangaWt.net", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangawt.com"
        )
    }
}

/// GuncelManga — Ported automatically.
public final class GuncelManga: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "GUNCEL_MANGA", title: "GuncelManga", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "guncelmanga.net"
        )
    }
    public override var datePattern: String { "d MMMM yyyy" }
}

/// TitanManga — Ported automatically.
public final class TitanManga: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "TITANMANGA", title: "TitanManga", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "titanmanga.com"
        )
    }
}

/// KabusManga — Ported automatically.
public final class KabusManga: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "KABUSMANGA", title: "KabusManga", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "kabusmanga.com"
        )
    }
    public override var datePattern: String { "dd/MM/yyyy" }
}

/// TortugaCeviri — Ported automatically.
public final class TortugaCeviri: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "TORTUGACEVIRI", title: "TortugaCeviri", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "tortugaceviri.com"
        )
    }
}

/// MangaWt.com — Ported automatically.
public final class Mangawt: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "MANGAWT", title: "MangaWt.com", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "mangawt.com"
        )
    }
}

/// TimeNaight — Ported automatically.
public final class Timenaight: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "TIMENAIGHT", title: "TimeNaight", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "timenaight.org"
        )
    }
    public override var datePattern: String { "dd/MM/yyyy" }
}

/// ArmoniScans — Ported automatically.
public final class ArmoniScans: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "ARMONISCANS", title: "ArmoniScans", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "armoniscans.net"
        )
    }
}

/// AsuraScansTR — Ported automatically.
public final class AsuraScansTR: MadaraParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "ASURASCANSTR", title: "AsuraScansTR", locale: "tr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "asurascans.com.tr"
        )
    }
}

