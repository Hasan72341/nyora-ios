import SwiftUI

/// SCREEN 7 — Services. Mirrors pref_services.xml.
struct ServicesSettingsView: View {
    @AppStorage("related_manga") private var relatedManga = true
    @AppStorage("stats_on") private var statsOn = false
    @AppStorage("reading_time") private var readingTime = true

    var body: some View {
        List {
            Section { SettingsHeader("Services", systemImage: "puzzlepiece.fill") }

            Section {
                NavigationLink { SuggestionsSettingsView() } label: {
                    rowLabel(title: "Suggestions", systemImage: "lightbulb.fill", value: nil)
                }
                ToggleRow(title: "Related manga", isOn: $relatedManga)
                ToggleRow(title: "Reading statistics", isOn: $statsOn)
                NavigationLink { StatsView() } label: {
                    rowLabel(title: "View statistics", systemImage: "chart.bar.fill", value: nil)
                }
                .disabled(!statsOn)
                ToggleRow(title: "Estimate reading time", isOn: $readingTime)
                NavigationLink { AiTranslateSettingsView() } label: {
                    rowLabel(title: "Translate pages", systemImage: "character.bubble", value: nil)
                }
            }

            Section("Progress Tracking") {
                NavigationLink { TrackingView() } label: {
                    rowLabel(title: "AniList", systemImage: "person.2.fill", value: "Connect")
                }
                NavigationLink { TrackingView() } label: {
                    rowLabel(title: "Kitsu", systemImage: "person.2.fill", value: "Connect")
                }
                NavigationLink { TrackingView() } label: {
                    rowLabel(title: "MyAnimeList", systemImage: "person.2.fill", value: "Connect")
                }
                NavigationLink { TrackingView() } label: {
                    rowLabel(title: "Shikimori", systemImage: "person.2.fill", value: "Connect")
                }
            }
        }
        .navigationTitle("Services")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// SCREEN 7b — Suggestions settings. Mirrors pref_suggestions.xml.
struct SuggestionsSettingsView: View {
    @AppStorage("suggestions") private var enabled = false
    @AppStorage("suggestions_wifi") private var wifiOnly = false
    @AppStorage("suggestions_disabled_sources") private var includeDisabled = false
    @AppStorage("suggestions_notifications") private var notifications = false
    @AppStorage("suggestions_exclude_tags") private var excludeTags = ""
    @AppStorage("suggestions_exclude_nsfw") private var excludeNsfw = false

    var body: some View {
        List {
            Section {
                ToggleRow(title: "Enable suggestions", systemImage: "lightbulb.fill", master: true, isOn: $enabled)
            }
            Section {
                ToggleRow(title: "Wi-Fi only", isOn: $wifiOnly)
                ToggleRow(title: "Include hidden sources", isOn: $includeDisabled)
                ToggleRow(title: "Enable notifications", isOn: $notifications)
                TextEditRow(title: "Excluded genres", placeholder: "comma, separated, tags", text: $excludeTags)
                ToggleRow(title: "Hide mature content", isOn: $excludeNsfw)
            }
            .disabled(!enabled)
            Section {
                InfoRow(text: "Suggestions are computed from your library and reading history.")
            }
        }
        .navigationTitle("Suggestions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// SCREEN 7c — Translate page / AI. Mirrors pref_ai_translate.xml.
/// Reuses translateTarget where it overlaps with ai_target_lang.
struct AiTranslateSettingsView: View {
    @AppStorage("ai_translate_enabled") private var enabled = false
    @AppStorage("ai_auto_translate") private var autoTranslate = false
    @AppStorage("ai_translate_offline") private var offline = false
    @AppStorage("ai_source_lang") private var sourceLang: AiSourceLangOption = .auto
    @AppStorage("ai_target_lang") private var targetLang: AiTargetLangOption = .english
    @AppStorage("ai_endpoint") private var endpoint = "https://api.openai.com/v1"
    @AppStorage("ai_api_key") private var apiKey = ""
    @AppStorage("ai_model") private var model = "gpt-4o-mini"
    @State private var testResult: String?
    @State private var testing = false

    var body: some View {
        List {
            Section { SettingsHeader("Translate pages", systemImage: "character.bubble") }

            Section {
                ToggleRow(title: "Enable translation", isOn: $enabled)
            }
            Section {
                ToggleRow(title: "Auto translate", isOn: $autoTranslate)
                ToggleRow(title: "Offline translation", isOn: $offline)
                SingleSelectRow(title: "Source language", selection: $sourceLang)
                SingleSelectRow(title: "Target language", selection: $targetLang)
            }
            .disabled(!enabled)

            Section("Translation service") {
                TextEditRow(title: "Service URL", placeholder: "https://api.openai.com/v1", keyboard: .URL, text: $endpoint)
                TextEditRow(title: "Service key", secure: true, text: $apiKey)
                TextEditRow(title: "Model", placeholder: "gpt-4o-mini", text: $model)
                ActionRow(title: testing ? "Testing…" : "Test connection",
                          systemImage: "checkmark.shield", summary: testResult) {
                    runTest()
                }
                .disabled(testing)
            }
            .disabled(!enabled)
        }
        .navigationTitle("Translate pages")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func runTest() {
        let raw = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty, let base = URL(string: raw), base.host != nil else {
            testResult = "Please enter a valid service URL"; return
        }
        // Hit the OpenAI-compatible /models listing: confirms reachability + that the
        // API key authenticates, without spending tokens on a completion.
        let modelsURL = base.appendingPathComponent("models")
        testing = true
        testResult = nil
        Task {
            do {
                var req = URLRequest(url: modelsURL)
                req.httpMethod = "GET"
                req.timeoutInterval = 15
                if !apiKey.isEmpty { req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization") }
                let (_, response) = try await URLSession.shared.data(for: req)
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                await MainActor.run {
                    switch code {
                    case 200..<300: testResult = "Connected successfully"
                    case 401, 403: testResult = "Service key is incorrect"
                    case 404: testResult = "Service URL is not valid"
                    default: testResult = "Service returned an error"
                    }
                    testing = false
                }
            } catch {
                await MainActor.run {
                    testResult = "Couldn't connect. Check your internet and try again."
                    testing = false
                }
            }
        }
    }
}
