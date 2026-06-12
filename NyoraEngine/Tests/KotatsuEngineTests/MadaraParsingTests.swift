import XCTest
import SwiftSoup
@testable import NyoraEngine

/// Offline tests: verify the Madara HTML parsing path (the core of the porting effort)
/// against a static fixture, with no network involved.
final class MadaraParsingTests: XCTestCase {

    private func makeParser() -> MangaReadOrg {
        MangaReadOrg(context: DefaultLoaderContext())
    }

    private func loadFixture(_ name: String) throws -> Document {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: name, withExtension: "html"),
            "missing fixture \(name).html"
        )
        let html = try String(contentsOf: url, encoding: .utf8)
        return try SwiftSoup.parse(html, "https://www.mangaread.org/")
    }

    func testParseMangaListExtractsEntries() throws {
        let parser = makeParser()
        let doc = try loadFixture("madara_list")
        let list = try parser.parseMangaList(doc)

        XCTAssertEqual(list.count, 2)

        let onePiece = try XCTUnwrap(list.first)
        XCTAssertEqual(onePiece.title, "One Piece")
        XCTAssertEqual(onePiece.url, "/manga/one-piece/")
        XCTAssertEqual(onePiece.publicUrl, "https://www.mangaread.org/manga/one-piece/")
        XCTAssertEqual(onePiece.coverUrl, "https://www.mangaread.org/covers/one-piece.jpg")
        XCTAssertEqual(onePiece.author, "Eiichiro Oda")
        XCTAssertEqual(Set(onePiece.tags.map(\.key)), ["action", "adventure"])
        XCTAssertTrue(onePiece.tags.contains { $0.title == "Action" }) // title-cased

        let berserk = list[1]
        XCTAssertEqual(berserk.title, "Berserk")
        // Lazy-loaded cover via data-src must be picked up.
        XCTAssertEqual(berserk.coverUrl, "https://www.mangaread.org/covers/berserk.jpg")
        XCTAssertEqual(berserk.tags.first?.key, "seinen")
    }

    func testGeneratedIdsAreStableAndDistinct() throws {
        let parser = makeParser()
        let list = try parser.parseMangaList(try loadFixture("madara_list"))
        XCTAssertNotEqual(list[0].id, list[1].id)
        // Stable across calls (persistence relies on this).
        XCTAssertEqual(list[0].id, generateUid("/manga/one-piece/"))
    }

    func testSourceRegisteredOnInit() {
        _ = makeParser()
        let resolved = SourceRegistry.shared.source(named: "MANGA_READ_ORG")
        XCTAssertEqual(resolved?.title, "MangaRead")
        XCTAssertEqual(resolved?.locale, "en")
    }

    func testRelativeAndAbsoluteUrlHelpers() {
        XCTAssertEqual("/manga/x/".toAbsoluteUrl(domain: "ex.com"), "https://ex.com/manga/x/")
        XCTAssertEqual("https://ex.com/manga/x/?p=1".toRelativeUrl(domain: "ex.com"), "/manga/x/?p=1")
        XCTAssertEqual("//cdn.ex.com/a.jpg".toAbsoluteUrl(domain: "ex.com"), "https://cdn.ex.com/a.jpg")
    }
}
