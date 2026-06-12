import SwiftUI

// MARK: - Design System
//
// Apple-native design tokens. Uses system semantic colors and the user's
// configured accent color (Settings > Wallpaper > Accent Color). No custom
// brand colors, no gradients — flat fills following HIG.

// MARK: Color Tokens

enum DS {
    enum Color {
        static let accent = SwiftUI.Color.accentColor

        static let background = SwiftUI.Color(.systemBackground)
        static let secondaryBackground = SwiftUI.Color(.secondarySystemBackground)
        static let tertiaryBackground = SwiftUI.Color(.tertiarySystemBackground)
        static let groupedBackground = SwiftUI.Color(.systemGroupedBackground)

        static let fill = SwiftUI.Color(.secondarySystemFill)
        static let tertiaryFill = SwiftUI.Color(.tertiarySystemFill)
        static let quaternaryFill = SwiftUI.Color(.quaternarySystemFill)

        static let label = SwiftUI.Color(.label)
        static let secondaryLabel = SwiftUI.Color(.secondaryLabel)
        static let tertiaryLabel = SwiftUI.Color(.tertiaryLabel)

        static let separator = SwiftUI.Color(.separator)

        static let success = SwiftUI.Color(.systemGreen)
        static let warning = SwiftUI.Color(.systemOrange)
        static let danger = SwiftUI.Color(.systemRed)
        static let info = SwiftUI.Color(.systemBlue)

        static let onAccent = SwiftUI.Color(.systemBackground)
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
    }

    static let posterColumns = [GridItem(.adaptive(minimum: 110, maximum: 160), spacing: Spacing.md)]

    enum CoverSize {
        static let rowSmall = CGSize(width: 44, height: 66)
        static let rowMedium = CGSize(width: 56, height: 84)
        static let hero = CGSize(width: 120, height: 180)
    }

    enum Gradient {
        static let readerChrome = LinearGradient(
            colors: [SwiftUI.Color.black.opacity(0.0), SwiftUI.Color.black.opacity(0.55)],
            startPoint: .top, endPoint: .bottom)
    }
}

// MARK: - Typography

extension Font {
    /// Large display title — screens, hero banners.
    static let dsDisplay = Font.system(.title, design: .rounded).weight(.bold)
    /// Section headers in lists and grouped content.
    static let dsSectionTitle = Font.system(.title3, design: .rounded).weight(.semibold)
    /// Card and row titles.
    static let dsCardTitle = Font.system(.subheadline, design: .default).weight(.semibold)
    /// Body text for descriptions and longer content.
    static let dsBody = Font.body
    /// Supporting metadata, timestamps, subtitles.
    static let dsCaption = Font.footnote
    /// Small numeric badges, pill counts.
    static let dsBadge = Font.caption.weight(.semibold)
}

// MARK: - Section Header

struct SectionHeader<Trailing: View>: View {
    let title: String
    var subtitle: String?
    var gradientUnderline: Bool = false
    @ViewBuilder var trailing: () -> Trailing

    init(_ title: String,
         subtitle: String? = nil,
         gradientUnderline: Bool = false,
         @ViewBuilder trailing: @escaping () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.gradientUnderline = gradientUnderline
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.dsSectionTitle)
                if gradientUnderline {
                    RoundedRectangle(cornerRadius: 1, style: .continuous)
                        .fill(Color.accentColor)
                        .frame(width: 28, height: 2)
                }
                if let subtitle {
                    Text(subtitle).font(.dsCaption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: DS.Spacing.sm)
            trailing()
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.vertical, DS.Spacing.xs)
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(_ title: String, subtitle: String? = nil, gradientUnderline: Bool = false) {
        self.init(title, subtitle: subtitle, gradientUnderline: gradientUnderline) { EmptyView() }
    }
}

// MARK: - Pill / Tag

struct Pill: View {
    let text: String
    var isSelected: Bool = false
    var systemImage: String? = nil
    var gradient: Bool = false

    var body: some View {
        HStack(spacing: DS.Spacing.xs) {
            if let systemImage {
                Image(systemName: systemImage).font(.caption2)
            }
            Text(text).font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm - 2)
        .background {
            if isSelected {
                Capsule().fill(Color.accentColor)
            } else {
                Capsule().fill(DS.Color.fill)
            }
        }
        .foregroundStyle(isSelected ? DS.Color.onAccent : DS.Color.label)
    }
}

// MARK: - Card Container

struct Card<Content: View>: View {
    var padding: CGFloat = DS.Spacing.lg
    var gradientSurface: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .fill(DS.Color.secondaryBackground)
            )
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let title: String
    let value: String
    let systemImage: String
    var tint: Color = DS.Color.accent

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
            Text(value)
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)
            Text(title).font(.dsCaption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.lg)
        .background(tint.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous))
    }
}

struct NumberBadge: View {
    let text: String
    var tint: Color = DS.Color.accent

    var body: some View {
        Text(text)
            .font(.dsBadge)
            .padding(.horizontal, DS.Spacing.sm)
            .padding(.vertical, 2)
            .background(tint.opacity(0.15), in: Capsule())
            .foregroundStyle(tint)
    }
}

// MARK: - Empty State Wrapper

struct EmptyStateView<Actions: View>: View {
    let title: String
    let systemImage: String
    var message: String?
    @ViewBuilder var actions: () -> Actions

    init(_ title: String,
         systemImage: String,
         message: String? = nil,
         @ViewBuilder actions: @escaping () -> Actions) {
        self.title = title
        self.systemImage = systemImage
        self.message = message
        self.actions = actions
    }

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            if let message { Text(message) }
        } actions: {
            actions()
        }
    }
}

extension EmptyStateView where Actions == EmptyView {
    init(_ title: String, systemImage: String, message: String? = nil) {
        self.init(title, systemImage: systemImage, message: message) { EmptyView() }
    }
}

// MARK: - Skeleton

struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                .fill(DS.Color.fill)
                .aspectRatio(2.0 / 3.0, contentMode: .fit)
            RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                .fill(DS.Color.fill)
                .frame(height: 12)
                .frame(maxWidth: .infinity)
        }
        .redacted(reason: .placeholder)
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.md)
            .padding(.horizontal, DS.Spacing.lg)
            .background(Color.accentColor,
                        in: RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
            .foregroundStyle(.white)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.md)
            .padding(.horizontal, DS.Spacing.lg)
            .background(DS.Color.fill, in: RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
            .foregroundStyle(Color.accentColor)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var dsPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var dsSecondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var dsGradient: PrimaryButtonStyle { PrimaryButtonStyle() }
}

// MARK: - Header

struct GradientHeader<Trailing: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder var trailing: () -> Trailing

    init(_ title: String,
         subtitle: String? = nil,
         @ViewBuilder trailing: @escaping () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.title2.weight(.bold))
                if let subtitle {
                    Text(subtitle).font(.dsCaption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: DS.Spacing.sm)
            trailing()
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.vertical, DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.secondaryBackground)
    }
}

extension GradientHeader where Trailing == EmptyView {
    init(_ title: String, subtitle: String? = nil) {
        self.init(title, subtitle: subtitle) { EmptyView() }
    }
}

extension View {
    func dsHeaderBackground() -> some View {
        background(DS.Color.secondaryBackground)
    }
}
