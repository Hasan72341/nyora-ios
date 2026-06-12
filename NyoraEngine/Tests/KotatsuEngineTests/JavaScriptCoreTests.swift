import XCTest
@testable import NyoraEngine

/// Verifies the JavaScriptCore-backed `evaluateJs` — the iOS replacement for GraalVM JS
/// that JS-based Nyora sources rely on. Proves JS actually executes and returns values
/// to Swift, including the kind of work real JS sources do (deobfuscation, JSON, base64).
final class JavaScriptCoreTests: XCTestCase {

    private func makeContext() -> DefaultLoaderContext { DefaultLoaderContext() }

    func testArithmetic() async throws {
        let ctx = makeContext()
        let result = try await ctx.evaluateJs("1 + 2 * 3")
        XCTAssertEqual(result, "7")
    }

    func testStringAndFunctions() async throws {
        let ctx = makeContext()
        let script = """
        (function () {
            var parts = ['ya', 'mada'];
            return parts.join('').toUpperCase();
        })();
        """
        let result = try await ctx.evaluateJs(script)
        XCTAssertEqual(result, "YAMADA")
    }

    func testJsonRoundTrip() async throws {
        let ctx = makeContext()
        // Real JS sources commonly build a JSON page array and hand it back as a string.
        let script = """
        JSON.stringify(['p1.jpg', 'p2.jpg', 'p3.jpg'].map(function (u, i) {
            return { page: i + 1, url: 'https://cdn.example.com/' + u };
        }));
        """
        let json = try await ctx.evaluateJs(script)
        let data = try XCTUnwrap(json.data(using: .utf8))
        let parsed = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        XCTAssertEqual(parsed?.count, 3)
        XCTAssertEqual(parsed?[1]["url"] as? String, "https://cdn.example.com/p2.jpg")
        XCTAssertEqual(parsed?[2]["page"] as? Int, 3)
    }

    func testBase64DeobfuscationPattern() async throws {
        let ctx = makeContext()
        // Mimics the "decode an obfuscated blob then extract image URLs" pattern used by
        // several JS sources (atob is provided by JavaScriptCore).
        let payload = #"eyJpbWFnZXMiOlsiYS5qcGciLCJiLmpwZyJdfQ=="#  // {"images":["a.jpg","b.jpg"]}
        let script = """
        (function () {
            var decoded = atob('\(payload)');
            var obj = JSON.parse(decoded);
            return obj.images.join(',');
        })();
        """
        let result = try await ctx.evaluateJs(script)
        XCTAssertEqual(result, "a.jpg,b.jpg")
    }

    func testThrownJsErrorSurfacesAsParserError() async throws {
        let ctx = makeContext()
        do {
            _ = try await ctx.evaluateJs("throw new Error('boom from source');")
            XCTFail("expected a thrown JS error")
        } catch let ParserError.js(message) {
            XCTAssertTrue(message.contains("boom from source"), "got: \(message)")
        }
    }

    func testReferenceErrorIsCaught() async throws {
        let ctx = makeContext()
        do {
            _ = try await ctx.evaluateJs("nonexistentFunction();")
            XCTFail("expected a reference error")
        } catch ParserError.js {
            // expected
        }
    }
}
