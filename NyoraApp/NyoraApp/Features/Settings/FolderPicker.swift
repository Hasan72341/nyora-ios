import SwiftUI
import UniformTypeIdentifiers

/// A UIKit document picker (folders only) wrapped for SwiftUI. On selection it persists a
/// security-scoped bookmark under the given UserDefaults key and reports the picked URL.
/// This is the real iOS mechanism for letting the user choose an output directory, since
/// the app is sandboxed and cannot present an arbitrary filesystem path.
struct FolderPicker: UIViewControllerRepresentable {
    /// UserDefaults key under which the security-scoped bookmark Data is stored.
    let bookmarkKey: String
    var onPick: (URL) -> Void = { _ in }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: FolderPicker
        init(_ parent: FolderPicker) { self.parent = parent }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            // Persist a security-scoped bookmark so the folder remains accessible later.
            let didAccess = url.startAccessingSecurityScopedResource()
            defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
            if let data = try? url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil) {
                UserDefaults.standard.set(data, forKey: parent.bookmarkKey)
            }
            parent.onPick(url)
        }
    }
}

/// Resolves the human-readable path of a folder previously picked & bookmarked under `key`.
/// Returns nil when nothing has been chosen yet.
func resolveBookmarkedFolderPath(_ key: String) -> String? {
    guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
    var stale = false
    guard let url = try? URL(resolvingBookmarkData: data, options: [], relativeTo: nil, bookmarkDataIsStale: &stale) else { return nil }
    // Show the user-facing folder name + last container for context.
    let comps = url.pathComponents
    if comps.count >= 2 {
        return comps.suffix(2).joined(separator: "/")
    }
    return url.lastPathComponent
}
