import SwiftUI
import NyoraEngine

/// Source management screen (nyora-android sources settings). Lists every installed source
/// with an enable toggle and a pin button, and supports drag-to-reorder. Order/pin/disable
/// state is persisted by `SourcePrefs.shared`.
struct SourceManagementView: View {
    @EnvironmentObject var model: AppModel
    @StateObject private var prefs = SourcePrefs.shared
    @State private var editMode: EditMode = .inactive

    /// Sources arranged for display in this editor: pinned first, then the rest, honoring the
    /// saved custom order. Disabled sources are still shown here (so they can be re-enabled),
    /// unlike Explore which hides them.
    private var orderedSources: [MangaParserSource] {
        let all = model.sources
        let ordered = applyCustomOrder(all)
        let pinned = ordered.filter { prefs.isPinned($0.name) }
        let rest = ordered.filter { !prefs.isPinned($0.name) }
        return pinned + rest
    }

    private func applyCustomOrder(_ sources: [MangaParserSource]) -> [MangaParserSource] {
        guard !prefs.customOrder.isEmpty else { return sources }
        let rank = Dictionary(uniqueKeysWithValues: prefs.customOrder.enumerated().map { ($0.element, $0.offset) })
        return sources.enumerated().sorted { lhs, rhs in
            let l = rank[lhs.element.name] ?? Int.max
            let r = rank[rhs.element.name] ?? Int.max
            if l != r { return l < r }
            return lhs.offset < rhs.offset
        }.map { $0.element }
    }

    var body: some View {
        Group {
            if model.sources.isEmpty {
                ContentUnavailableView("No Sources", systemImage: "safari",
                                       description: Text("No browsing sources are installed."))
            } else {
                List {
                    Section {
                        ForEach(orderedSources, id: \.name) { source in
                            SourceManagementRow(source: source, prefs: prefs)
                        }
                        .onMove(perform: move)
                    } header: {
                        Text("Sources")
                    } footer: {
                        Text("Pinned sources surface first in Explore. Turn a source off to hide it from browsing and search. Drag to reorder.")
                    }
                }
                .listStyle(.insetGrouped)
                .environment(\.editMode, $editMode)
            }
        }
        .navigationTitle("Manage Sources")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !model.sources.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Enable All") {
                        prefs.enableAll()
                    }
                    .disabled(prefs.disabled.isEmpty)
                }
            }
        }
    }

    private func move(from offsets: IndexSet, to destination: Int) {
        var names = orderedSources.map(\.name)
        names.move(fromOffsets: offsets, toOffset: destination)
        prefs.setCustomOrder(names)
    }
}

/// One row: source identity, an enable toggle, and a pin toggle button.
private struct SourceManagementRow: View {
    let source: MangaParserSource
    @ObservedObject var prefs: SourcePrefs

    var body: some View {
        HStack(spacing: 12) {
            Button {
                prefs.togglePin(source.name)
            } label: {
                Image(systemName: prefs.isPinned(source.name) ? "pin.fill" : "pin")
                    .foregroundStyle(prefs.isPinned(source.name) ? Color.accentColor : .secondary)
            }
            .buttonStyle(.borderless)

            VStack(alignment: .leading, spacing: 2) {
                Text(source.title).font(.body.weight(.medium))
                HStack(spacing: 6) {
                    Text((source.locale ?? "multi").uppercased())
                    Text("·")
                    Text(source.contentType.rawValue.capitalized)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { prefs.isEnabled(source.name) },
                set: { prefs.setEnabled($0, for: source.name) }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 2)
    }
}
