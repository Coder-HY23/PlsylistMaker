import SwiftUI

enum InterfaceTheme: String, CaseIterable, Identifiable {
    case sky = "Sky"
    case midnight = "Midnight"

    var id: Self { self }

    var subtitle: String {
        switch self {
        case .sky:
            return "Light, clean bubbles inspired by Messages."
        case .midnight:
            return "Dark bubbles with bright iMessage-like accents."
        }
    }

    var palette: MessengerPalette {
        switch self {
        case .sky:
            return MessengerPalette(
                backgroundTop: Color(red: 0.95, green: 0.97, blue: 1.0),
                backgroundBottom: Color(red: 0.87, green: 0.93, blue: 1.0),
                surface: Color.white,
                surfaceMuted: Color(red: 0.94, green: 0.95, blue: 0.98),
                border: Color(red: 0.82, green: 0.88, blue: 0.98),
                inputBackground: Color(red: 0.97, green: 0.98, blue: 1.0),
                primary: Color(red: 0.0, green: 0.48, blue: 1.0),
                textPrimary: Color(red: 0.06, green: 0.07, blue: 0.12),
                textSecondary: Color(red: 0.37, green: 0.39, blue: 0.44),
                warning: Color(red: 1.0, green: 0.58, blue: 0.0),
                success: Color(red: 0.20, green: 0.72, blue: 0.36),
                danger: Color(red: 1.0, green: 0.27, blue: 0.23),
                isDark: false
            )
        case .midnight:
            return MessengerPalette(
                backgroundTop: Color(red: 0.10, green: 0.06, blue: 0.16),
                backgroundBottom: Color(red: 0.01, green: 0.01, blue: 0.03),
                surface: Color(red: 0.12, green: 0.09, blue: 0.18),
                surfaceMuted: Color(red: 0.19, green: 0.15, blue: 0.27),
                border: Color(red: 0.34, green: 0.25, blue: 0.53),
                inputBackground: Color(red: 0.18, green: 0.14, blue: 0.25),
                primary: Color(red: 0.63, green: 0.36, blue: 0.96),
                textPrimary: Color(red: 0.96, green: 0.97, blue: 1.0),
                textSecondary: Color(red: 0.74, green: 0.70, blue: 0.85),
                warning: Color(red: 1.0, green: 0.68, blue: 0.22),
                success: Color(red: 0.32, green: 0.83, blue: 0.50),
                danger: Color(red: 1.0, green: 0.40, blue: 0.35),
                isDark: true
            )
        }
    }
}

struct MessengerPalette {
    let backgroundTop: Color
    let backgroundBottom: Color
    let surface: Color
    let surfaceMuted: Color
    let border: Color
    let inputBackground: Color
    let primary: Color
    let textPrimary: Color
    let textSecondary: Color
    let warning: Color
    let success: Color
    let danger: Color
    let isDark: Bool

    var backgroundGradient: LinearGradient {
        LinearGradient(colors: [backgroundTop, backgroundBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct MessengerPrimaryButtonStyle: ButtonStyle {
    let palette: MessengerPalette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(palette.primary.opacity(configuration.isPressed ? 0.75 : 1.0))
            )
    }
}

struct MessengerSecondaryButtonStyle: ButtonStyle {
    let palette: MessengerPalette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(palette.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(palette.surfaceMuted.opacity(configuration.isPressed ? 0.7 : 1.0))
            )
    }
}

private struct MessengerCardModifier: ViewModifier {
    let palette: MessengerPalette
    let padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(palette.border, lineWidth: 1)
            )
    }
}

extension View {
    func messengerCard(_ palette: MessengerPalette, padding: CGFloat = 16) -> some View {
        modifier(MessengerCardModifier(palette: palette, padding: padding))
    }
}
