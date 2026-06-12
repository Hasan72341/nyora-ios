import Foundation
import SwiftUI
import NyoraEngine

/// User preferences for source management — which sources are disabled, pinned, and the
/// optional custom ordering. Mirrors nyora-android's sources settings. Persisted to its own
/// `sourcePrefs.json` in Application Support/Nyora (never touches library.json), following
/// the same simple JSON-snapshot pattern as `LibraryStore` / `DownloadManager`.
///
/// Sources are identified by their stable `MangaParserSource.name` (the engine's source key).
@MainActor
final class SourcePrefs: ObservableObject {
    static let shared = SourcePrefs()

    /// Names of sources the user has hidden from Explore.
    @Published private(set) var disabled: Set<String> = []
    /// Names of sources pinned to the top of Explore (in `customOrder` order).
    @Published private(set) var pinned: Set<String> = []
    /// Optional full custom ordering of source names (drag-to-reorder). Sources missing from
    /// this list fall back to their natural order after the listed ones.
    @Published private(set) var customOrder: [String] = []

    private let queue = DispatchQueue(label: "nyora.sourceprefsstore")

    // MARK: Paths (mirrors LibraryStore/DownloadManager)

    private static let baseDir: URL = {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Nyora", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private let stateURL = SourcePrefs.baseDir.appendingPathComponent("sourcePrefs.json")

    // MARK: Persistence

    /// Backward-compatible snapshot — missing keys decode to defaults.
    private struct Snapshot: Codable {
        var disabled: [String] = []
        var pinned: [String] = []
        var customOrder: [String] = []

        init() {}
        init(disabled: [String], pinned: [String], customOrder: [String]) {
            self.disabled = disabled
            self.pinned = pinned
            self.customOrder = customOrder
        }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            disabled = try c.decodeIfPresent([String].self, forKey: .disabled) ?? []
            pinned = try c.decodeIfPresent([String].self, forKey: .pinned) ?? []
            customOrder = try c.decodeIfPresent([String].self, forKey: .customOrder) ?? []
        }
    }

    private init() {
        if let data = try? Data(contentsOf: stateURL),
           let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            disabled = Set(decoded.disabled)
            pinned = Set(decoded.pinned)
            customOrder = decoded.customOrder
        }
    }

    private func persist() {
        let snap = Snapshot(disabled: Array(disabled), pinned: Array(pinned), customOrder: customOrder)
        queue.async { [stateURL] in
            if let data = try? JSONEncoder().encode(snap) {
                try? data.write(to: stateURL, options: .atomic)
            }
        }
    }

    // MARK: Enable / disable

    func isEnabled(_ name: String) -> Bool { !disabled.contains(name) }

    func setEnabled(_ enabled: Bool, for name: String) {
        if enabled {
            disabled.remove(name)
        } else {
            disabled.insert(name)
        }
        persist()
    }

    func enableAll() {
        disabled.removeAll()
        persist()
    }

    func setSourcesEnabledExclusive(_ enabledSources: Set<MangaParserSource>) {
        let enabledNames = Set(enabledSources.map(\.name))
        let allSources = SourceRegistry.shared.all
        disabled = Set(allSources.filter { !enabledNames.contains($0.name) }.map(\.name))
        persist()
    }

    // MARK: Pinning

    func isPinned(_ name: String) -> Bool { pinned.contains(name) }

    func setPinned(_ isPinned: Bool, for name: String) {
        if isPinned {
            pinned.insert(name)
        } else {
            pinned.remove(name)
        }
        persist()
    }

    func togglePin(_ name: String) {
        if pinned.contains(name) {
            pinned.remove(name)
        } else {
            pinned.insert(name)
        }
        persist()
    }

    // MARK: Custom order (drag-to-reorder)

    /// Persist a new full ordering of source names (as produced by `onMove`).
    func setCustomOrder(_ names: [String]) {
        customOrder = names
        persist()
    }

    // MARK: Ordering for Explore

    /// Returns the visible, ordered sources: enabled only, pinned first, each group honoring
    /// the custom order (then natural order for anything not yet ordered).
    func orderedSources(from sources: [MangaParserSource]) -> [MangaParserSource] {
        let enabled = sources.filter { isEnabled($0.name) }
        let orderedEnabled = sortByCustomOrder(enabled)
        let pinnedGroup = orderedEnabled.filter { isPinned($0.name) }
        let rest = orderedEnabled.filter { !isPinned($0.name) }
        return pinnedGroup + rest
    }

    /// Stable sort by `customOrder`; sources absent from it keep their incoming relative order
    /// and sort after any listed sources.
    private func sortByCustomOrder(_ sources: [MangaParserSource]) -> [MangaParserSource] {
        guard !customOrder.isEmpty else { return sources }
        let rank = Dictionary(uniqueKeysWithValues: customOrder.enumerated().map { ($0.element, $0.offset) })
        return sources.enumerated().sorted { lhs, rhs in
            let l = rank[lhs.element.name] ?? Int.max
            let r = rank[rhs.element.name] ?? Int.max
            if l != r { return l < r }
            return lhs.offset < rhs.offset   // stable for unranked items
        }.map { $0.element }
    }
}
