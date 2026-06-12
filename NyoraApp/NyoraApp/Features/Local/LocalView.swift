import SwiftUI
import UniformTypeIdentifiers

/// Local manga library: a grid of folders / archives the user imported from Files. Import via
/// `.fileImporter` (folders + CBZ/ZIP archives); tap a cover to read it; long-press to delete.
/// A folder becomes one manga (subfolders → chapters); a CBZ/ZIP archive is extracted into the
/// app's managed store as a single-chapter manga. CBR/EPUB are detected and rejected honestly.
struct LocalView: View {
    @StateObject private var store = LocalLibraryStore.shared

    @State private var importing = false
    @State private var errorMessage: String?
    @State private var showError = false

    var embedInStack = true

    private let columns = [GridItem(.adaptive(minimum: 110, maximum: 160), spacing: 12)]

    /// Content types offered in the picker. `.folder` and `.zip` are system types; CBZ/CBR/EPUB
    /// are added by dynamic UTType so the user can also select those (CBR/EPUB then produce an
    /// honest "unsupported" message rather than being silently unselectable).
    private static var importContentTypes: [UTType] {
        var types: [UTType] = [.folder, .zip]
        if let cbz = UTType("public.cbz") ?? UTType(filenameExtension: "cbz") { types.append(cbz) }
        if let cbr = UTType(filenameExtension: "cbr") { types.append(cbr) }
        types.append(.epub)
        types.append(.archive)
        return types
    }

    var body: some View {
        if embedInStack {
            NavigationStack { content }
        } else {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        Group {
            if store.items.isEmpty {
                    ContentUnavailableView {
                        Label("No Downloaded Manga", systemImage: "folder")
                    } description: {
                        Text("Import folders or comic archives from your files to read offline.")
                    } actions: {
                        Button("Import") { importing = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(store.items) { item in
                                NavigationLink {
                                    LocalReaderView(item: item, currentChapterIndex: 0)
                                } label: {
                                    cell(item)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button("Delete", systemImage: "trash", role: .destructive) {
                                        store.delete(item)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)
                    }
                }
            }
            .navigationTitle("On Device")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { importing = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .fileImporter(
                isPresented: $importing,
                allowedContentTypes: Self.importContentTypes,
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .alert("Import Failed", isPresented: $showError, presenting: errorMessage) { _ in
                Button("OK", role: .cancel) {}
            } message: { msg in
                Text(msg)
            }
    }

    private func cell(_ item: LocalManga) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .bottom) {
                LocalCoverImage(item: item)
                    .aspectRatio(2.0 / 3.0, contentMode: .fill)

                LinearGradient(
                    colors: [.black.opacity(0.0), .black.opacity(0.75)],
                    startPoint: .center, endPoint: .bottom
                )
                .frame(height: 60)
                .frame(maxHeight: .infinity, alignment: .bottom)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(subtitle(item))
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.quaternary, lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        }
        .contentShape(Rectangle())
    }

    private func subtitle(_ item: LocalManga) -> String {
        let chapters = item.chapters.count
        if chapters > 1 {
            return "\(chapters) chapters"
        }
        return "\(item.pageCount) pages"
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let picked = urls.first else { return }
            do {
                if isDirectory(picked) {
                    try store.importFolder(picked)
                } else {
                    try store.importArchive(picked)
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    /// Whether the picked URL is a directory (folder import) vs a file (archive import).
    private func isDirectory(_ url: URL) -> Bool {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        if let v = try? url.resourceValues(forKeys: [.isDirectoryKey]), let isDir = v.isDirectory {
            return isDir
        }
        // Fall back to a trailing-slash / extension heuristic.
        return url.hasDirectoryPath
    }
}
