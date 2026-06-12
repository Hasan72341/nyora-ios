import SwiftUI

// MARK: - Settings shared building blocks
//
// Reusable, dependency-light pieces for the native Settings tree.
// Uses flat system colors following Apple HIG — no custom gradients.

// MARK: Settings Header

struct SettingsHeader: View {
    let title: String
    let subtitle: String?
    let systemImage: String

    init(_ title: String, subtitle: String? = nil, systemImage: String) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: DS.Spacing.lg) {
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.title3.weight(.bold))
                if let subtitle {
                    Text(subtitle).font(.dsCaption).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, DS.Spacing.sm)
    }
}

// MARK: Tinted leading icon for nav rows

struct SettingsRowIcon: View {
    let systemImage: String
    var tint: Color = DS.Color.accent

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(tint, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

// MARK: - Generic option protocol

/// A single-select option backed by a String raw value (matches Android entryValues).
protocol SettingsOption: CaseIterable, Identifiable, RawRepresentable, Hashable where RawValue == String {
    var label: String { get }
}

extension SettingsOption {
    var id: String { rawValue }
}

// MARK: - Single-select picker screen (ListPreference -> checkmark list)

/// A checkmark list that mirrors Android's ListPreference dialog. Binds to an
/// @AppStorage-backed enum value passed in as a Binding.
struct SingleSelectScreen<Option: SettingsOption>: View {
    let title: String
    let footer: String?
    @Binding var selection: Option

    init(_ title: String, footer: String? = nil, selection: Binding<Option>) {
        self.title = title
        self.footer = footer
        self._selection = selection
    }

    var body: some View {
        List {
            Section(footer: footer.map(Text.init) ?? Text("")) {
                ForEach(Array(Option.allCases)) { option in
                    Button {
                        selection = option
                    } label: {
                        HStack {
                            Text(option.label).foregroundStyle(DS.Color.label)
                            Spacer()
                            if option == selection {
                                Image(systemName: "checkmark")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(DS.Color.accent)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Inline summary-style nav row that pushes a `SingleSelectScreen`.
struct SingleSelectRow<Option: SettingsOption>: View {
    let title: String
    var systemImage: String?
    var footer: String?
    @Binding var selection: Option

    var body: some View {
        NavigationLink {
            SingleSelectScreen(title, footer: footer, selection: $selection)
        } label: {
            rowLabel(title: title, systemImage: systemImage, value: selection.label)
        }
    }
}

// MARK: - Multi-select screen (MultiSelectListPreference -> checkbox list)

/// A checkbox list mirroring Android's MultiSelectListPreference. Selection stored
/// as a comma-joined string in @AppStorage for parity-friendly persistence.
struct MultiSelectScreen<Option: SettingsOption>: View {
    let title: String
    let footer: String?
    @Binding var rawSelection: String   // comma-joined raw values

    private var selected: Set<String> {
        Set(rawSelection.split(separator: ",").map(String.init))
    }

    private func toggle(_ option: Option) {
        var set = selected
        if set.contains(option.rawValue) { set.remove(option.rawValue) }
        else { set.insert(option.rawValue) }
        rawSelection = Array(Option.allCases)
            .map(\.rawValue)
            .filter { set.contains($0) }
            .joined(separator: ",")
    }

    var body: some View {
        List {
            Section(footer: footer.map(Text.init) ?? Text("")) {
                ForEach(Array(Option.allCases)) { option in
                    Button {
                        toggle(option)
                    } label: {
                        HStack {
                            Text(option.label).foregroundStyle(DS.Color.label)
                            Spacer()
                            if selected.contains(option.rawValue) {
                                Image(systemName: "checkmark")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(DS.Color.accent)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Nav row that summarizes a multi-select as comma-joined labels.
struct MultiSelectRow<Option: SettingsOption>: View {
    let title: String
    var systemImage: String?
    var footer: String?
    @Binding var rawSelection: String

    private var summary: String {
        let set = Set(rawSelection.split(separator: ",").map(String.init))
        let labels = Array(Option.allCases).filter { set.contains($0.rawValue) }.map(\.label)
        return labels.isEmpty ? "None" : labels.joined(separator: ", ")
    }

    var body: some View {
        NavigationLink {
            MultiSelectScreen<Option>(title: title, footer: footer, rawSelection: $rawSelection)
        } label: {
            rowLabel(title: title, systemImage: systemImage, value: summary)
        }
    }
}

// MARK: - Text edit row (EditTextPreference)

/// A row that pushes a single TextField/SecureField editor sheet.
struct TextEditRow: View {
    let title: String
    var systemImage: String?
    var placeholder: String = ""
    var secure: Bool = false
    var keyboard: UIKeyboardType = .default
    @Binding var text: String

    @State private var showEditor = false

    private var displayValue: String {
        if text.isEmpty { return "Not set" }
        return secure ? String(repeating: "•", count: min(text.count, 12)) : text
    }

    var body: some View {
        Button {
            showEditor = true
        } label: {
            rowLabel(title: title, systemImage: systemImage, value: displayValue)
        }
        .sheet(isPresented: $showEditor) {
            TextEditSheet(title: title, placeholder: placeholder, secure: secure, keyboard: keyboard, text: $text)
        }
    }
}

struct TextEditSheet: View {
    let title: String
    let placeholder: String
    let secure: Bool
    let keyboard: UIKeyboardType
    @Binding var text: String
    @Environment(\.dismiss) private var dismiss
    @State private var draft: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if secure {
                        SecureField(placeholder, text: $draft)
                    } else {
                        TextField(placeholder, text: $draft)
                            .keyboardType(keyboard)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { text = draft; dismiss() }
                }
            }
            .onAppear { draft = text }
        }
    }
}

// MARK: - Slider row (SliderPreference)

struct SliderRow: View {
    let title: String
    var systemImage: String?
    let range: ClosedRange<Double>
    var step: Double = 1
    var unit: String = ""
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            HStack {
                if let systemImage { SettingsRowIcon(systemImage: systemImage) }
                Text(title)
                Spacer()
                Text("\(Int(value))\(unit)")
                    .font(.dsCaption.weight(.semibold))
                    .foregroundStyle(DS.Color.accent)
            }
            Slider(value: $value, in: range, step: step)
                .tint(DS.Color.accent)
        }
    }
}

// MARK: - Action row (plain Preference)

/// A tappable action row with optional summary, e.g. "Clear cache", "Create backup".
struct ActionRow: View {
    let title: String
    var systemImage: String?
    var summary: String?
    var role: ButtonRole?
    let action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            HStack(spacing: DS.Spacing.md) {
                if let systemImage { SettingsRowIcon(systemImage: systemImage, tint: role == .destructive ? DS.Color.danger : DS.Color.accent) }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).foregroundStyle(role == .destructive ? DS.Color.danger : DS.Color.label)
                    if let summary {
                        Text(summary).font(.dsCaption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - Info row (non-selectable footer-style row)

struct InfoRow: View {
    let text: String
    var systemImage: String = "info.circle"

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.sm) {
            Image(systemName: systemImage).foregroundStyle(DS.Color.accent)
            Text(text).font(.dsCaption).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Toggle row with optional gradient master-header styling

/// A toggle that, when `master` is true, renders as a prominent gradient header
/// switch (mirrors Android's preference_toggle_header).
struct ToggleRow: View {
    let title: String
    var systemImage: String?
    var summary: String?
    var master: Bool = false
    @Binding var isOn: Bool

    var body: some View {
        if master {
            Toggle(isOn: $isOn) {
                HStack(spacing: DS.Spacing.md) {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.headline)
                        if let summary { Text(summary).font(.dsCaption).foregroundStyle(.secondary) }
                    }
                }
            }
            .tint(DS.Color.accent)
        } else {
            Toggle(isOn: $isOn) {
                rowLabelContent(title: title, systemImage: systemImage, summary: summary)
            }
            .tint(DS.Color.accent)
        }
    }
}

// MARK: - Shared row label helpers

@ViewBuilder
func rowLabel(title: String, systemImage: String?, value: String?) -> some View {
    HStack(spacing: DS.Spacing.md) {
        if let systemImage { SettingsRowIcon(systemImage: systemImage) }
        Text(title).foregroundStyle(DS.Color.label)
        Spacer(minLength: DS.Spacing.sm)
        if let value {
            Text(value)
                .font(.dsCaption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}

@ViewBuilder
func rowLabelContent(title: String, systemImage: String?, summary: String?) -> some View {
    HStack(spacing: DS.Spacing.md) {
        if let systemImage { SettingsRowIcon(systemImage: systemImage) }
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
            if let summary { Text(summary).font(.dsCaption).foregroundStyle(.secondary) }
        }
    }
}
