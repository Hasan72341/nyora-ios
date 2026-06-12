import XCTest
@testable import NyoraEngine

final class BatchVerifyTests: XCTestCase {

    func testNewlyPortedSources() async throws {
        let sourcesToTest = [
            "RAMAREADER", "DEATHTOLLSCANS", "NYXSCANS", 
            "ONMA", "MANGA_DENIZI", "NETTRUYENHE",
            "TYRANTSCANS", "DUOSCANLATORS", "HECKSCANS"
        ]
        
        let catalog = SourceCatalog()
        
        for sourceName in sourcesToTest {
            guard let parser = catalog.parser(for: sourceName) else {
                print("⚠️ Parser not found for \(sourceName), skipping")
                continue
            }
            
            print("=== Testing \(sourceName) ===")
            do {
                let list = try await parser.getList(page: 1, order: parser.defaultSortOrder, filter: .empty)
                print("✅ List fetched: \(list.count) items")
                guard let first = list.first else {
                    print("⚠️ List is empty, skipping details")
                    continue
                }
                
                print("   First item: \(first.title)")
                let details = try await parser.getDetails(first)
                let chapters = details.chapters ?? []
                print("✅ Details fetched: chapters=\(chapters.count), tags=\(details.tags.count)")
                
                if let firstChapter = chapters.first {
                    let pages = try await parser.getPages(firstChapter)
                    print("✅ Pages fetched for chapter '\(firstChapter.name)': \(pages.count) pages")
                } else {
                    print("⚠️ No chapters found to fetch pages")
                }
                
            } catch {
                let msg = (error as? ParserError)?.description ?? error.localizedDescription
                print("❌ ERROR in \(sourceName): \(msg)")
            }
        }
    }
}
