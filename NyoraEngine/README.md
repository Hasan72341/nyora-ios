# NyoraEngine (Swift / iOS)

A native Swift port of the Nyora manga-source engine, targeting iOS 15+ / macOS 12+.
This replaces the JVM helper used by the macOS/Windows/Linux ports (which cannot run on
iOS — no JVM, no JIT, no subprocesses) with pure Swift + system frameworks.

## Why a rewrite, not a port-of-the-port

The other Nyora platforms reuse `nyora-helper.jar` (GraalVM JS + Nyora Kotlin parsers on
the JVM). iOS forbids all three pillars of that approach. So the engine is reimplemented:

| JVM piece                | Swift replacement            |
|--------------------------|------------------------------|
| OkHttp + CookieJar       | `URLSession` + `HTTPCookieStorage` (`WebClient`) |
| jsoup (HTML/CSS parsing) | **SwiftSoup**                |
| GraalVM JS               | **JavaScriptCore** (system framework, JIT-allowed) |
| Nyora Kotlin parsers   | this package (`Sites/…`)     |

## Architecture (mirrors `org.koitharu.nyora.parsers`)

```
Sources/NyoraEngine/
  Model/      Manga, MangaChapter, MangaPage, MangaTag, enums, MangaListFilter*, MangaParserSource + SourceRegistry
  Config/     ConfigKey, MangaSourceConfig (+ InMemoryConfig)
  Context/    MangaLoaderContext (protocol) + DefaultLoaderContext (URLSession + JavaScriptCore evaluateJs)
  Network/    WebClient (GET/POST → Data / SwiftSoup Document / JSON)
  Core/       MangaParser, AbstractMangaParser, PagedMangaParser, Paginator
  Util/       generateUid, URL helpers, SwiftSoup extensions, date parsing
  Sites/      template parsers + concrete sources
```

## Status

**Foundation + first template: DONE and compiling for iOS device (arm64) and macOS.**

- [x] Core model, config, context, network, base classes
- [x] `MadaraParser` template — list (AJAX + non-AJAX), details, sync/AJAX chapters, pages
- [x] Concrete source `MangaReadOrg` (proof of the subclass pattern)
- [x] Offline parsing tests (`swift test`, 4 passing) against a static HTML fixture
- [ ] Madara `chapter-protector` AES path (CryptoAES helper) — stubbed, throws clearly
- [ ] Remaining templates: MangaReader, WpComics, MangaBox, ZeistManga, GalleryAdults, MadTheme, …
- [ ] ~1,300 concrete sources (mostly mechanical template subclasses)

## The remaining work, honestly

Nyora is **3,659 classes**; ~1,331 are site parsers. This package ports the *framework*
and *one* of the ~30 templates. The bulk of the remaining sources are short template
subclasses (domain + pageSize + a few selector overrides — see `MangaReadOrg.swift`), so
they are highly parallelizable, but they must each be checked against the live site and the
upstream Kotlin source, and then maintained against upstream churn forever.

## Build / test

```sh
swift build                                            # macOS host
swift test                                             # offline parsing tests
swift build --triple arm64-apple-ios15.0 \
  --sdk "$(xcrun --sdk iphoneos --show-sdk-path)"      # iOS device
```
