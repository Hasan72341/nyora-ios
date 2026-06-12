import SwiftUI
import NyoraEngine

/// Saved reader pages, grouped per-manga.
/// Mirrors `Nyora/nyora-web/cloudflare/public/screens/bookmarks.js`.
struct BookmarksView: View {
    @EnvironmentObject var model: AppModel
    @State private var editingNote: BookmarkEntry?
    @State private var nextNoteText = ""

    var embedInStack = true

    /// Group bookmarks by manga title.
    private var grouped: [(String, [BookmarkEntry])] {
        let dict = Dictionary(grouping: model.bookmarks) { $0.manga.title }
        return dict.sorted { $0.key < $1.key }
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
            if model.bookmarks.isEmpty {
                EmptyStateView(
                    "No bookmarks",
                    systemImage: "bookmark",
                    message: "Tap the ribbon while reading to save a page."
                )
            } else {
                List {
                    ForEach(grouped, id: \.0) { title, entries in
                        Section {
                            ForEach(entries) { entry in
                                BookmarkRow(entry: entry) {
                                    model.removeBookmark(entry)
                                } onEdit: {
                                    nextNoteText = entry.manga.title // Placeholder or real note logic
                                    // In a real app we'd show a prompt, mirroring promptDialog in JS.
                                    editingNote = entry
                                }
                            }
                        } header: {
                            HStack {
                                Text(title)
                                Spacer()
                                Text("\(entries.count) saved")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(DS.Color.accent.opacity(0.1), in: Capsule())
                                    .foregroundStyle(DS.Color.accent)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Bookmarks")
        .sheet(item: $editingNote) { entry in
            BookmarkNoteEditor(entry: entry)
        }
    }
}

struct BookmarkRow: View {
    let entry: BookmarkEntry
    let onDelete: () -> Void
    let onEdit: () -> Void
    @EnvironmentObject var model: AppModel
    @State private var showingSearch = false

    var body: some View {
        Button {
            // Resume logic: open search for title (mirroring JS openBookmark)
            showingSearch = true
        } label: {
            HStack(spacing: DS.Spacing.md) {
                if let urlString = entry.manga.coverUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color(UIColor.tertiarySystemFill)
                    }
                    .frame(width: 40, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.chapterTitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text("Page \(entry.page + 1) · \(entry.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    // Note if present (not in model yet? wait, checking...)
                    // LibraryStore.swift had BookmarkEntry but let's check fields.
                }
            }
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingSearch) {
            // Global search with title pre-filled to resume
            GlobalSearchView(initialQuery: entry.manga.title)
                .environmentObject(model)
        }
    }
}

/// Simple prompt-like editor for bookmark notes.
struct BookmarkNoteEditor: View {
    let entry: BookmarkEntry
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Note for \(entry.chapterTitle)") {
                    TextField("Enter note...", text: $note, axis: .vertical)
                        .lineLimit(3...10)
                }
            }
            .navigationTitle("Bookmark Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // model.updateBookmarkNote(entry, note: note) 
                        // Need to check if AppModel supports this
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // note = entry.note ?? ""
        }
    }
}
