import XCTest
@testable import NyoraEngine

/// Live network diagnostic — NOT a unit test. Run explicitly to see what each source
/// actually returns (data / network error / Cloudflare wall / parse mismatch).
///   swift test --filter LiveDiagnosticTests
final class LiveDiagnosticTests: XCTestCase {

    func testBrowseEachSource() async throws {
        let catalog = SourceCatalog()
        for src in catalog.sources {
            guard let parser = catalog.parser(for: src.name) else { continue }
            let order = parser.defaultSortOrder
            do {
                let list = try await parser.getList(page: 1, order: order, filter: .empty)
                print("✅ \(src.title): \(list.count) items; first = \(list.first?.title ?? "—")")
            } catch {
                let msg = (error as? ParserError)?.description ?? error.localizedDescription
                print("❌ \(src.title): \(msg)")
            }
        }
    }

    func testReadChainMangaRead() async throws {
        let catalog = SourceCatalog()
        let parser = catalog.parser(for: "MANGA_READ_ORG")!
        let list = try await parser.getList(page: 1, order: parser.defaultSortOrder, filter: .empty)
        print("list: \(list.count)")
        let detailed = try await parser.getDetails(list[0])
        print("details: \(detailed.title) — chapters=\(detailed.chapters?.count ?? 0), tags=\(detailed.tags.count)")
        guard let ch = detailed.chapters?.first else { print("no chapters"); return }
        let pages = try await parser.getPages(ch)
        print("pages in '\(ch.name)': \(pages.count); first=\(pages.first?.url ?? "—")")
    }

    func testReadChainMangaDex() async throws {
        let parser = SourceCatalog().parser(for: "MANGADEX")!
        let list = try await parser.getList(page: 1, order: .popularity, filter: .empty)
        let detailed = try await parser.getDetails(list[0])
        print("MD details: \(detailed.title) — chapters=\(detailed.chapters?.count ?? 0), tags=\(detailed.tags.count), authors=\(detailed.authors.count)")
        guard let ch = detailed.chapters?.first else { print("no chapters"); return }
        let pages = try await parser.getPages(ch)
        print("MD pages in '\(ch.name)': \(pages.count); first=\(pages.first?.url ?? "—")")
    }

    func testMangaDexPagesHosted() async throws {
        let parser = SourceCatalog().parser(for: "MANGADEX")!
        // Walk popular titles until one has a chapter with API-hosted pages (skips licensed/external).
        let list = try await parser.getList(page: 1, order: .updated, filter: .empty)
        for m in list.prefix(6) {
            let d = try await parser.getDetails(m)
            guard let ch = d.chapters?.first else { continue }
            let pages = try await parser.getPages(ch)
            if !pages.isEmpty {
                print("MD hosted: '\(d.title)' ch '\(ch.name)' -> \(pages.count) pages; first=\(pages.first!.url)")
                return
            }
        }
        print("none of the sampled titles had hosted pages")
    }

    func testChaptersEachSource() async throws {
        let catalog = SourceCatalog()
        for src in catalog.sources {
            guard let parser = catalog.parser(for: src.name) else { continue }
            do {
                let list = try await parser.getList(page: 1, order: parser.defaultSortOrder, filter: .empty)
                guard let first = list.first else { print("· \(src.title): empty list"); continue }
                let d = try await parser.getDetails(first)
                print("· \(src.title): '\(d.title)' chapters=\(d.chapters?.count ?? 0)")
            } catch {
                print("· \(src.title): ERROR \((error as? ParserError)?.description ?? error.localizedDescription)")
            }
        }
    }

    func testFullChainAll() async throws {
        let catalog = SourceCatalog()
        for src in catalog.sources {
            guard let parser = catalog.parser(for: src.name) else { continue }
            do {
                let list = try await parser.getList(page: 1, order: parser.defaultSortOrder, filter: .empty)
                guard let first = list.first else { print("· \(src.title): EMPTY list"); continue }
                let d = try await parser.getDetails(first)
                let ch = d.chapters?.first
                let pages = ch != nil ? (try? await parser.getPages(ch!)) ?? [] : []
                print("· \(src.title): chapters=\(d.chapters?.count ?? 0), firstChapterPages=\(pages.count)")
            } catch {
                print("· \(src.title): ERROR \((error as? ParserError)?.description ?? error.localizedDescription)")
            }
        }
    }

    func testTimeDetails() async throws {
        let parser = SourceCatalog().parser(for: "MANGA_READ_ORG")!
        let list = try await parser.getList(page: 1, order: .popularity, filter: .empty)
        let t0 = Date()
        let d = try await parser.getDetails(list[0])
        let dt = Date().timeIntervalSince(t0)
        print(String(format: "getDetails('%@') %d chapters in %.2fs", d.title, d.chapters?.count ?? 0, dt))
    }
}
