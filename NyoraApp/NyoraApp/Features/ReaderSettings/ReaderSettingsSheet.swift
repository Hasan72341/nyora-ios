import SwiftUI
import NyoraEngine

/// Bottom sheet presented from the reader's top bar. Binds to the same `@AppStorage`-backed
/// reader preferences (plus the reader's transient `translateOn` state), so changes here take
/// effect live. Distinct from `ReaderSettingsView` (the Settings tab) because the reader also
/// needs to drive `mode`, `translateOn`, `targetLang`, and `useAppleIntelligence`.
struct ReaderSettingsSheet: View {
    @Binding var mode: ReaderMode
    @Binding var direction: ReadingDirection
    @Binding var pageFit: PageFit
    @Binding var background: ReaderBackground
    @Binding var keepScreenOn: Bool
    @Binding var translateOn: Bool
    @Binding var targetLang: String
    @Binding var useAppleIntelligence: Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Mode", selection: $mode) {
                        ForEach(ReaderMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    if mode == .paged {
                        Picker("Direction", selection: $direction) {
                            ForEach(ReadingDirection.allCases) { Text($0 == .ltr ? "LTR" : "RTL").tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }

                    Picker("Page fit", selection: $pageFit) {
                        ForEach(PageFit.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Reading").font(.dsSectionTitle)
                }

                Section {
                    HStack {
                        Text("Background")
                        Spacer()
                        HStack(spacing: DS.Spacing.md) {
                            ForEach(ReaderBackground.allCases) { bg in
                                Circle()
                                    .fill(bg.color)
                                    .frame(width: 28, height: 28)
                                    .overlay(Circle().stroke(DS.Color.separator, lineWidth: 0.5))
                                    .overlay(Circle().stroke(DS.Color.accent, lineWidth: background == bg ? 2.5 : 0))
                                    .onTapGesture { background = bg }
                                    .accessibilityLabel(bg.label)
                            }
                        }
                    }

                    Toggle("Keep screen on", isOn: $keepScreenOn)
                        .tint(DS.Color.accent)
                } header: {
                    Text("Appearance").font(.dsSectionTitle)
                }

                Section {
                    Toggle("Translate pages", isOn: $translateOn)
                        .tint(DS.Color.accent)

                    Picker("Translate to", selection: $targetLang) {
                        ForEach(TranslationConfig.supportedLanguages.filter { $0 != "AUTO" }, id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(!translateOn)

                    Toggle("Apple Intelligence refine", isOn: $useAppleIntelligence)
                        .tint(DS.Color.accent)
                        .disabled(!translateOn)
                } header: {
                    Text("Translation").font(.dsSectionTitle)
                } footer: {
                    Text("Refines machine-translated text on-device using Apple Intelligence. Requires a supported device.")
                }
            }
            .navigationTitle("Reader settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
