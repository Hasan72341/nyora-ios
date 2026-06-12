import Foundation

/// Deterministic 64-bit id from source-relative identifiers, matching the role of
/// Nyora's `MangaParser.generateUid`.
public func generateUid(_ url: String) -> Int64 {
    var hash: UInt64 = 1125899906842597
    for byte in url.utf8 {
        hash = 31 &* hash &+ UInt64(byte)
    }
    return Int64(bitPattern: hash)
}

public func generateUid(_ id: Int64) -> Int64 { id }

public extension String {
    func toAbsoluteUrl(domain: String) -> String {
        if hasPrefix("http://") || hasPrefix("https://") { return self }
        if hasPrefix("//") { return "https:" + self }
        let base = domain.hasPrefix("http") ? domain : "https://\(domain)"
        if hasPrefix("/") { return base + self }
        return base + "/" + self
    }

    func toRelativeUrl(domain: String) -> String {
        let clean = trimmingCharacters(in: .whitespacesAndNewlines)
        guard let comps = URLComponents(string: clean), let host = comps.host else { return clean }
        let bareDomain = domain.replacingOccurrences(of: "www.", with: "")
        guard host == domain || host == "www.\(bareDomain)" || host == bareDomain else { return clean }
        var rel = comps.path
        if let q = comps.query { rel += "?\(q)" }
        return rel.isEmpty ? "/" : rel
    }

    var nullIfEmpty: String? { isEmpty ? nil : self }
}
