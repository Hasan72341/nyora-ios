import SwiftUI

/// SCREEN 8 — Backup and restore. Mirrors pref_backup.xml.
struct BackupSettingsView: View {
    var body: some View {
        List {
            Section { SettingsHeader("Backup and restore", systemImage: "arrow.up.arrow.down.circle.fill") }

            Section {
                NavigationLink { BackupView(stamp: Date()) } label: {
                    rowLabel(title: "Create backup", systemImage: "square.and.arrow.up", value: nil)
                }
                NavigationLink { BackupView(stamp: Date()) } label: {
                    rowLabel(title: "Restore backup", systemImage: "square.and.arrow.down", value: nil)
                }
                NavigationLink { PeriodicBackupSettingsView() } label: {
                    rowLabel(title: "Periodic backups", systemImage: "clock.arrow.circlepath", value: nil)
                }
            }
        }
        .navigationTitle("Backup and restore")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// SCREEN 8a — Periodic backups. Mirrors pref_backup_periodic.xml.
struct PeriodicBackupSettingsView: View {
    @AppStorage("backup_periodic") private var enabled = false
    @AppStorage("backup_periodic_freq") private var freq: BackupFreqOption = .week
    @AppStorage("backup_periodic_trim") private var trim = true
    @AppStorage("backup_periodic_count") private var count: Double = 10
    @AppStorage("backup_periodic_tg_enabled") private var tgEnabled = false
    @AppStorage("backup_periodic_tg_chat_id") private var tgChatId = ""

    @State private var showOutputDirPicker = false
    @State private var outputDirPath: String? = resolveBookmarkedFolderPath("backup_output_dir_bookmark")

    @State private var testing = false
    @State private var testResult: TestResult?

    private enum TestResult: Identifiable {
        case success(String), failure(String)
        var id: String { switch self { case .success(let s): return "s\(s)"; case .failure(let s): return "f\(s)" } }
    }

    var body: some View {
        List {
            Section {
                ToggleRow(title: "Enable periodic backups", systemImage: "clock.arrow.circlepath", master: true, isOn: $enabled)
            }

            Section {
                ActionRow(title: "Backups output directory",
                          systemImage: "folder",
                          summary: outputDirPath ?? "Not set — tap to choose a folder") {
                    showOutputDirPicker = true
                }
                SingleSelectRow(title: "Backup frequency", selection: $freq)
                ToggleRow(title: "Delete old backups", isOn: $trim)
                SliderRow(title: "Max backups count", range: 1...32, step: 1, value: $count)
                    .disabled(!trim)
            }
            .disabled(!enabled)

            Section("Telegram integration") {
                ToggleRow(title: "Send backups to Telegram", isOn: $tgEnabled)
                Group {
                    TextEditRow(title: "Telegram chat ID", keyboard: .numbersAndPunctuation, text: $tgChatId)
                    ActionRow(title: "Open Telegram bot", systemImage: "paperplane") {
                        if let url = URL(string: "https://t.me") { UIApplication.shared.open(url) }
                    }
                    ActionRow(title: testing ? "Testing…" : "Test connection",
                              systemImage: "checkmark.shield") {
                        Task { await testConnection() }
                    }
                    .disabled(testing)
                }
                .disabled(!tgEnabled)
            }
            .disabled(!enabled)
        }
        .navigationTitle("Periodic backups")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showOutputDirPicker) {
            FolderPicker(bookmarkKey: "backup_output_dir_bookmark") { url in
                outputDirPath = resolveBookmarkedFolderPath("backup_output_dir_bookmark") ?? url.lastPathComponent
            }
            .ignoresSafeArea()
        }
        .alert(item: $testResult) { result in
            switch result {
            case .success(let msg):
                return Alert(title: Text("Connection OK"), message: Text(msg), dismissButton: .default(Text("OK")))
            case .failure(let msg):
                return Alert(title: Text("Connection failed"), message: Text(msg), dismissButton: .default(Text("OK")))
            }
        }
    }

    /// Real reachability check against Telegram's public Bot API. We can verify the chat ID
    /// is non-empty and that the Telegram API endpoint is reachable from this device; we do
    /// not have a stored bot token here, so we use the public `getMe`-style host reachability
    /// plus chat-id validation rather than faking a delivered message.
    private func testConnection() async {
        testing = true
        defer { testing = false }

        let chat = tgChatId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !chat.isEmpty else {
            testResult = .failure("Enter a Telegram chat ID first.")
            return
        }

        guard let url = URL(string: "https://api.telegram.org") else {
            testResult = .failure("Invalid endpoint.")
            return
        }
        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        req.httpMethod = "HEAD"
        do {
            let (_, response) = try await URLSession.shared.data(for: req)
            if let http = response as? HTTPURLResponse, (200..<500).contains(http.statusCode) {
                testResult = .success("Telegram API is reachable. Chat ID “\(chat)” will be used when sending backups.")
            } else {
                testResult = .failure("Unexpected response from Telegram API.")
            }
        } catch {
            testResult = .failure(error.localizedDescription)
        }
    }
}
