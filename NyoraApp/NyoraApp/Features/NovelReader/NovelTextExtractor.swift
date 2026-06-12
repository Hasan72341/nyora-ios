import Foundation
import NyoraEngine

/// Fetches and extracts readable text for a NOVEL chapter.
///
/// For `ContentType.novel` sources, `getPages` returns `MangaPage`s whose `url` (after
/// `getPageUrl` resolution for sources that defer it) points at an HTML page that contains the
/// chapter prose rather than an image. We fetch that HTML with the source's request headers
/// (Referer matters for the same hotlink-protection reasons as images) and reduce it to plain
/// paragraphs for the text reader.
///
/// This is a pure-Swift extractor — it deliberately avoids `NSAttributedString(documentType:.html)`
/// (which spins up WebKit on the main run loop and can hang SwiftUI), matching the rationale of
/// the existing `String.htmlStripped` helper.
enum NovelTextExtractor {

    struct Section: Identifiable, Hashable {
        let id: Int
        /// The resolved (absolute) page URL this text came from.
        let sourceURL: String
        /// Paragraph-separated readable text.
        let text: String
    }

    /// Fetch every page of a novel chapter and return its extracted text sections in order.
    ///
    /// - parameter pages: the `MangaPage`s from `AppModel.pages(for:)`.
    /// - parameter model: used to resolve page URLs + per-source request headers.
    /// - parameter sourceName: the manga's `source.name`.
    static func sections(
        for pages: [MangaPage],
        model: AppModel,
        sourceName: String
    ) async throws -> [Section] {
        guard let parser = await MainActor.run(body: { model._jsEngine.parser(for: sourceName) }) else { return [] }
        var headers = parser.requestHeaders()
        headers["Referer"] = "https://\(parser.domain)/"

        var result: [Section] = []
        result.reserveCapacity(pages.count)

        for (index, page) in pages.enumerated() {
            try Task.checkCancellation()
            // Sources that defer the final URL resolve it here; most novel pages are direct.
            let resolved = (try? await parser.getPageUrl(page)) ?? page.url
            let absolute = resolved.toAbsoluteUrl(domain: parser.domain)
            guard let url = URL(string: absolute) else { continue }

            let text: String
            do {
                let html = try await fetchHTML(url: url, headers: headers)
                text = readableText(fromHTML: html)
            } catch {
                // A single failed page shouldn't abort the whole chapter; surface a marker.
                text = ""
            }
            result.append(Section(id: index, sourceURL: absolute, text: text))
        }
        return result
    }

    // MARK: - Networking

    private static func fetchHTML(url: URL, headers: [String: String]) async throws -> String {
        var request = URLRequest(url: url)
        for (k, v) in headers { request.setValue(v, forHTTPHeaderField: k) }
        request.timeoutInterval = 30
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        // Honour the declared charset where possible, default to UTF-8 then Latin-1.
        if let s = String(data: data, encoding: .utf8) { return s }
        if let s = String(data: data, encoding: .isoLatin1) { return s }
        return String(decoding: data, as: UTF8.self)
    }

    // MARK: - Extraction

    /// Reduce a full HTML document to readable paragraph text.
    ///
    /// Strategy: drop the obvious non-content elements (script/style/nav/header/footer), then
    /// fall back to the plain-tag stripper. We keep paragraph and line breaks so the reader can
    /// render natural spacing.
    static func readableText(fromHTML html: String) -> String {
        var s = html

        // Remove whole non-content blocks (including their content) before stripping tags.
        for tag in ["script", "style", "noscript", "svg", "head", "nav", "header", "footer", "aside", "form"] {
            s = s.replacingOccurrences(
                of: "<\(tag)\\b[^>]*>[\\s\\S]*?</\(tag)>",
                with: " ",
                options: [.regularExpression, .caseInsensitive]
            )
        }

        // HTML comments.
        s = s.replacingOccurrences(of: "<!--[\\s\\S]*?-->", with: " ", options: .regularExpression)

        // Preserve structural breaks as newlines before generic tag stripping.
        s = s.replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: [.regularExpression, .caseInsensitive])
        for blockClose in ["</p>", "</div>", "</h1>", "</h2>", "</h3>", "</h4>", "</li>", "</blockquote>"] {
            s = s.replacingOccurrences(of: blockClose, with: "\n\n", options: .caseInsensitive)
        }

        // Strip all remaining tags.
        s = s.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        // Decode entities (superset of the description stripper's table).
        s = decodeEntities(s)

        // Normalise whitespace: collapse intra-line runs, trim each line, collapse blank runs.
        let lines = s
            .replacingOccurrences(of: "\r", with: "")
            .components(separatedBy: "\n")
            .map { line -> String in
                line.replacingOccurrences(of: "[\\t \\u{00A0}]{2,}", with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
            }

        var out: [String] = []
        var blanks = 0
        for line in lines {
            if line.isEmpty {
                blanks += 1
                if blanks <= 1 { out.append("") }
            } else {
                blanks = 0
                out.append(line)
            }
        }
        return out.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func decodeEntities(_ input: String) -> String {
        var s = input
        let entities: [String: String] = [
            "&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"",
            "&#39;": "'", "&apos;": "'", "&nbsp;": " ", "&hellip;": "…",
            "&mdash;": "—", "&ndash;": "–", "&rsquo;": "’", "&lsquo;": "‘",
            "&ldquo;": "“", "&rdquo;": "”", "&copy;": "©", "&reg;": "®",
            "&deg;": "°", "&middot;": "·", "&bull;": "•", "&trade;": "™"
        ]
        for (k, v) in entities { s = s.replacingOccurrences(of: k, with: v) }
        // Numeric entities: &#1234; and &#x1F600;
        s = replaceNumericEntities(in: s)
        return s
    }

    private static func replaceNumericEntities(in input: String) -> String {
        guard input.contains("&#") else { return input }
        var result = ""
        result.reserveCapacity(input.count)
        var iterator = input.startIndex
        while iterator < input.endIndex {
            if input[iterator] == "&",
               let semicolon = input[iterator...].firstIndex(of: ";"),
               input.index(after: iterator) < input.endIndex,
               input[input.index(after: iterator)] == "#" {
                let entity = input[iterator...semicolon]
                let body = entity.dropFirst(2).dropLast() // strip "&#" and ";"
                var scalarValue: UInt32?
                if body.first == "x" || body.first == "X" {
                    scalarValue = UInt32(body.dropFirst(), radix: 16)
                } else {
                    scalarValue = UInt32(body, radix: 10)
                }
                if let value = scalarValue, let scalar = Unicode.Scalar(value) {
                    result.append(Character(scalar))
                    iterator = input.index(after: semicolon)
                    continue
                }
            }
            result.append(input[iterator])
            iterator = input.index(after: iterator)
        }
        return result
    }
}
