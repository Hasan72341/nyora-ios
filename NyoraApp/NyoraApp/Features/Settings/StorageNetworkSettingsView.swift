import SwiftUI

/// SCREEN 4 — Storage and network (title "Network"). Mirrors pref_network.xml.
struct StorageNetworkSettingsView: View {
    @AppStorage("prefetch_content") private var prefetch: PrefetchOption = .always
    @AppStorage("pages_preload") private var preload: PreloadOption = .never
    @AppStorage("doh") private var doh: DohOption = .disabled
    @AppStorage("github_mirror") private var githubMirror: GithubMirrorOption = .keiyoushi
    @AppStorage("images_proxy_2") private var imagesProxy: ImagesProxyOption = .none
    @AppStorage("ssl_bypass") private var sslBypass = false
    @AppStorage("no_offline") private var noOffline = false
    @AppStorage("adblock") private var adblock = false

    var body: some View {
        List {
            Section { SettingsHeader("Network", systemImage: "internaldrive.fill") }

            Section("Storage usage") {
                StorageUsageBar()
                NavigationLink { DataRemovalSettingsView() } label: {
                    rowLabel(title: "Data removal", systemImage: "trash", value: nil)
                }
            }

            Section {
                SingleSelectRow(title: "Prefetch content", selection: $prefetch)
                SingleSelectRow(title: "Preload pages", selection: $preload)
                NavigationLink { ProxySettingsView() } label: {
                    rowLabel(title: "Proxy", systemImage: "network", value: nil)
                }
                SingleSelectRow(title: "DNS over HTTPS", selection: $doh)
                SingleSelectRow(title: "GitHub mirror", selection: $githubMirror)
                SingleSelectRow(title: "Images proxy", selection: $imagesProxy)
            }

            Section {
                ToggleRow(title: "Ignore SSL errors", isOn: $sslBypass)
                ToggleRow(title: "Disable connectivity check", isOn: $noOffline)
                ToggleRow(title: "Adblock", isOn: $adblock)
            }
        }
        .navigationTitle("Network")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Custom storage-usage visual (StorageUsagePreference analog). Computes REAL on-disk sizes:
/// the image/page caches, the downloads directory, and the system Caches directory.
struct StorageUsageBar: View {
    @State private var breakdown = CacheManager.StorageBreakdown()
    @State private var loaded = false

    /// (label, bytes, color) — derived from the measured breakdown.
    private var segments: [(String, Int64, Color)] {
        [
            ("Images cache", breakdown.images, .blue),
            ("Downloads", breakdown.downloads, .green),
            ("Other caches", max(0, breakdown.caches), .gray)
        ]
    }

    private var total: Int64 { segments.reduce(0) { $0 + $1.1 } }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack {
                Text(loaded ? total.formattedFileSize : "Calculating…")
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }

            GeometryReader { geo in
                HStack(spacing: 1) {
                    if total > 0 {
                        ForEach(segments, id: \.0) { name, bytes, color in
                            Rectangle()
                                .fill(color)
                                .frame(width: max(0, geo.size.width * (Double(bytes) / Double(total))))
                        }
                    } else {
                        Rectangle().fill(.quaternary)
                    }
                }
            }
            .frame(height: 14)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

            FlowLegend(segments: segments)
        }
        .padding(.vertical, DS.Spacing.xs)
        .task {
            breakdown = await CacheManager.computeStorage()
            loaded = true
        }
    }
}

private struct FlowLegend: View {
    let segments: [(String, Int64, Color)]
    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            ForEach(segments, id: \.0) { name, bytes, color in
                HStack(spacing: 4) {
                    Circle().fill(color).frame(width: 8, height: 8)
                    Text("\(name) \(bytes.formattedFileSize)")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }
}
