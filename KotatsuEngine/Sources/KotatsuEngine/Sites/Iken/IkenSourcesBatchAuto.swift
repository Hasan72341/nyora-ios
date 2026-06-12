import Foundation

/// Nyx Scans — Ported automatically.
public final class NyxScans: IkenParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "NYXSCANS", title: "Nyx Scans", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "nyxscans.com"
        )
    }
}

