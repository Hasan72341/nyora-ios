import SwiftUI
import UniformTypeIdentifiers
import NyoraEngine

/// Backup & restore for the library file (`Application Support/Nyora/library.json`).
///
/// We operate on the file as an opaque blob — the same JSON that `LibraryStore` reads at
/// launch. Export copies it to a temp file and offers it via the share sheet so the user can
/// save it to Files. Restore picks a `.json`, validates it decodes as the expected shape, then
/// overwrites `library.json`. Because `LibraryStore` only loads at launch, the restored data
/// won't appear until the app is relaunched — the UI tells the user so.
struct BackupView: View {
    @EnvironmentObject var model: AppModel

    /// Passed in so we never call `Date()` at type-init time (deterministic, testable).
    let stamp: Date

    @State private var exportDocument: BackupDocument?
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var alert: BackupAlert?

    private static let stampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd-HHmmss"
        return f
    }()

    private var exportFilename: String {
        "Nyora-backup-\(Self.stampFormatter.string(from: stamp)).json"
    }

    var body: some View {
        List {
            Section("Current library") {
                LabeledContent("Favourites", value: "\(model.favourites.count)")
                LabeledContent("History", value: "\(model.history.count)")
                LabeledContent("Bookmarks", value: "\(model.bookmarks.count)")
            }

            Section {
                Button {
                    exportBackup()
                } label: {
                    Label("Export backup", systemImage: "square.and.arrow.up")
                }
            } footer: {
                Text("Saves your library (favourites, history, bookmarks, categories) to a file you can keep in Files or share.")
            }

            Section {
                Button {
                    showImporter = true
                } label: {
                    Label("Restore from backup", systemImage: "square.and.arrow.down")
                }
            } footer: {
                Text("Restoring replaces your current library. The app must be relaunched afterwards for the restored data to load.")
            }
        }
        .navigationTitle("Backup & Restore")
        .navigationBarTitleDisplayMode(.inline)
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: exportFilename
        ) { result in
            switch result {
            case .success:
                alert = BackupAlert(title: "Backup saved", message: "Your library backup was exported successfully.")
            case .failure(let error):
                alert = BackupAlert(title: "Export failed", message: error.localizedDescription)
            }
            exportDocument = nil
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .alert(item: $alert) { a in
            Alert(title: Text(a.title), message: Text(a.message), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: Export

    private func exportBackup() {
        guard let data = try? Data(contentsOf: BackupPaths.libraryFile) else {
            alert = BackupAlert(title: "Nothing to export", message: "No library data was found yet. Add some favourites first.")
            return
        }
        exportDocument = BackupDocument(data: data)
        showExporter = true
    }

    // MARK: Restore

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            alert = BackupAlert(title: "Import failed", message: error.localizedDescription)
        case .success(let urls):
            guard let picked = urls.first else { return }
            let needsStop = picked.startAccessingSecurityScopedResource()
            defer { if needsStop { picked.stopAccessingSecurityScopedResource() } }

            do {
                let data = try Data(contentsOf: picked)
                guard BackupValidator.isValidBackup(data) else {
                    alert = BackupAlert(
                        title: "Invalid backup",
                        message: "This file does not look like a Nyora library backup."
                    )
                    return
                }
                try BackupPaths.ensureDirectory()
                try data.write(to: BackupPaths.libraryFile, options: .atomic)
                alert = BackupAlert(
                    title: "Library restored",
                    message: "Please quit and relaunch Nyora to load the restored library."
                )
            } catch {
                alert = BackupAlert(title: "Restore failed", message: error.localizedDescription)
            }
        }
    }
}

/// Alert payload (identifiable so `.alert(item:)` can drive it).
private struct BackupAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

/// On-disk paths, mirroring `LibraryStore`'s layout.
enum BackupPaths {
    static var nyoraDirectory: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Nyora", isDirectory: true)
    }

    static var libraryFile: URL {
        nyoraDirectory.appendingPathComponent("library.json")
    }

    static func ensureDirectory() throws {
        try FileManager.default.createDirectory(at: nyoraDirectory, withIntermediateDirectories: true)
    }
}

/// Validates that imported data is shaped like a library snapshot: the top-level object must
/// carry the expected keys. We don't fully decode into the engine types (those live in the app
/// target, not here) — a structural check is enough to reject unrelated JSON files.
enum BackupValidator {
    static func isValidBackup(_ data: Data) -> Bool {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }
        let required = ["favourites", "history", "bookmarks"]
        return required.allSatisfy { object[$0] != nil }
    }
}

/// A trivial `FileDocument` wrapping the raw library bytes for `.fileExporter`.
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
