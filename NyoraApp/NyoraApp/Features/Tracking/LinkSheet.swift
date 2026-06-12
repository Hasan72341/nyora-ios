import SwiftUI
import NyoraEngine

/// Sheet that picks a tracker service, searches it by title, and links a chosen result to
/// the given manga. Presented from MangaDetailView's "Track" button.
struct LinkSheet: View {
    let manga: Manga

    @StateObject private var tracking = TrackingService.shared
    @Environment(\.dismiss) private var dismiss

    /// Currently selected service tab (defaults to the first signed-in one).
    @State private var service: TrackerService = .aniList
    @State private var query: String = ""
    @State private var results: [TrackerMedia] = []
    @State private var searching = false
    @State private var error: String?
    @State private var lastSearchedService: TrackerService?

    var body: some View {
        NavigationStack {
            Group {
                if !tracking.isLoggedIn {
                    notLoggedIn
                } else {
                    content
                }
            }
            .navigationTitle("Track")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task {
            // Default to the first signed-in service.
            if let first = TrackerService.allCases.first(where: { tracking.isSignedIn($0) }) {
                service = first
            }
            query = manga.title
            await refresh()
        }
    }

    private var signedInServices: [TrackerService] {
        TrackerService.allCases.filter { tracking.isSignedIn($0) }
    }

    @ViewBuilder private var content: some View {
        VStack(spacing: 0) {
            if signedInServices.count > 1 {
                Picker("Service", selection: $service) {
                    ForEach(signedInServices) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: service) { _, _ in Task { await refresh() } }
            }
            if let existing = tracking.links[tracking.linkKey(service, manga.id)] {
                alreadyLinked(existing)
            } else {
                searchList
            }
        }
    }

    private var notLoggedIn: some View {
        ContentUnavailableView {
            Label("Not signed in", systemImage: "person.crop.circle.badge.xmark")
        } description: {
            Text("Sign in to a tracker in More → Services → Tracking to link manga.")
        }
    }

    private func alreadyLinked(_ tracked: TrackedManga) -> some View {
        List {
            Section(service.displayName) {
                LabeledContent("Linked to", value: tracked.remoteTitle)
                LabeledContent("Synced progress", value: "Chapter \(tracked.lastSyncedProgress)")
                Button("Unlink", role: .destructive) {
                    tracking.unlink(service, manga.id)
                }
            }
        }
    }

    private var searchList: some View {
        List {
            if let error {
                Section { Text(error).font(.footnote).foregroundStyle(.red) }
            }
            if searching && results.isEmpty {
                Section { HStack { Spacer(); ProgressView(); Spacer() } }
            } else if results.isEmpty {
                Section {
                    ContentUnavailableView("No matches", systemImage: "magnifyingglass",
                                           description: Text("Try a different search term."))
                }
            } else {
                Section("Results") {
                    ForEach(results) { media in
                        Button { link(media) } label: { resultRow(media) }
                            .buttonStyle(.plain)
                    }
                }
            }
        }
        .searchable(text: $query, prompt: "Search \(service.displayName) manga")
        .onSubmit(of: .search) { Task { await refresh() } }
    }

    private func resultRow(_ media: TrackerMedia) -> some View {
        HStack(spacing: 12) {
            RemoteImage(url: media.coverUrl.flatMap(URL.init(string:)))
                .aspectRatio(2.0/3.0, contentMode: .fill)
                .frame(width: 44, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            Text(media.title).font(.subheadline)
            Spacer()
            Image(systemName: "link").foregroundStyle(.blue)
        }
        .contentShape(Rectangle())
    }

    private func link(_ media: TrackerMedia) {
        tracking.link(MangaRef(manga), service: service, media: media)
        dismiss()
    }

    private func refresh() async {
        lastSearchedService = service
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { results = []; return }
        searching = true; error = nil
        do {
            results = try await tracking.search(service, title: q)
        } catch {
            self.error = (error as? TrackerOAuthError)?.errorDescription ?? error.localizedDescription
            results = []
        }
        searching = false
    }
}
