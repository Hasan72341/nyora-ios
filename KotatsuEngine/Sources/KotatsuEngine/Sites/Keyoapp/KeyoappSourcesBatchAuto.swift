import Foundation

/// EdScanlation — Ported automatically.
public final class EdScanlation: KeyoappParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "EDSCANLATION", title: "EdScanlation", locale: "fr")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "edscanlation.fr"
        )
    }
}

/// KenScans — Ported automatically.
public final class RaiScans: KeyoappParser, @unchecked Sendable {
    public static let descriptor = MangaParserSource(name: "RAISCANS", title: "KenScans", locale: "en")
    public init(context: MangaLoaderContext) {
        super.init(
            context: context,
            source: Self.descriptor,
            defaultDomain: "kenscans.com"
        )
    }
}

