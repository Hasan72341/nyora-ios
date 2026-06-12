import SwiftUI

/// SCREEN 6 — Check for new chapters (Tracker). Mirrors pref_tracker.xml.
/// Android-only ignore_dose omitted.
struct TrackerSettingsView: View {
    @AppStorage("tracker_enabled") private var enabled = true
    @AppStorage("tracker_wifi") private var wifiOnly = false
    @AppStorage("tracker_freq") private var freq: TrackerFreqOption = .default
    @AppStorage("track_sources") private var sources = "favorites,history"
    @AppStorage("tracker_no_nsfw") private var noNsfw = false
    @AppStorage("tracker_download") private var download: TrackerDownloadOption = .never

    var body: some View {
        List {
            Section {
                ToggleRow(title: "Check for new chapters", systemImage: "bell.badge.fill", master: true, isOn: $enabled)
            }

            Section {
                ToggleRow(title: "Wi-Fi only", isOn: $wifiOnly)
                SingleSelectRow(title: "Check frequency", selection: $freq)
                MultiSelectRow<TrackSourceOption>(title: "Track sources", rawSelection: $sources)
                NavigationLink { MangaCategoriesView() } label: {
                    rowLabel(title: "Favourites categories", systemImage: "folder", value: nil)
                }
                NavigationLink { NotificationSettingsView() } label: {
                    rowLabel(title: "Notification settings", systemImage: "bell", value: nil)
                }
                ToggleRow(title: "Hide mature content notifications", isOn: $noNsfw)
                SingleSelectRow(title: "Download new chapters", selection: $download)
            }
            .disabled(!enabled)

            Section("Advanced") {
                NavigationLink { TrackerDebugInfoView() } label: {
                    rowLabel(title: "Account details", systemImage: "person.circle", value: nil)
                }
                .disabled(!enabled)
                InfoRow(text: "Background checks on iOS are managed by the system and may not run exactly on the chosen schedule.")
            }
        }
        .navigationTitle("Check for new chapters")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Real tracker state surfaced from `TrackingService.shared` (AniList account link,
/// token presence and the count of linked manga). No fabricated values.
struct TrackerDebugInfoView: View {
    @ObservedObject private var tracking = TrackingService.shared

    var body: some View {
        List {
            Section("Account") {
                LabeledContent("Signed in", value: tracking.isLoggedIn ? "Yes" : "No")
                LabeledContent("Access token", value: tracking.token?.isEmpty == false ? "Present" : "None")
                LabeledContent("Viewer", value: tracking.viewerName ?? "—")
            }
            Section("Tracked manga") {
                LabeledContent("Linked entries", value: "\(tracking.links.count)")
                ForEach(Array(tracking.links.values), id: \.id) { tracked in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(tracked.service.displayName): \(tracked.remoteTitle)").font(.body)
                        Text("Last synced: chapter \(tracked.lastSyncedProgress)")
                            .font(.dsCaption).foregroundStyle(.secondary)
                    }
                }
            }
            Section {
                InfoRow(text: "Account info is updated automatically. To link manga, open a manga's details and tap Track.")
            }
        }
        .navigationTitle("Account Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// SCREEN 6a — Notifications. Mirrors notification settings. Android-only LED
/// (notifications_light) omitted.
struct NotificationSettingsView: View {
    @AppStorage("tracker_notifications") private var enabled = true
    @AppStorage("notifications_vibrate") private var vibrate = false

    var body: some View {
        List {
            Section {
                ToggleRow(title: "Enable notifications", systemImage: "bell.fill", master: true, isOn: $enabled)
            }

            Section {
                ActionRow(title: "Notification sound", systemImage: "speaker.wave.2", summary: "Open system notification settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                }
                ToggleRow(title: "Vibration", isOn: $vibrate)
            }
            .disabled(!enabled)

            Section {
                InfoRow(text: "Manage delivery, banners and sounds in the system Settings app.")
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}
