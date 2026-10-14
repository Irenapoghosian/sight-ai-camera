import SwiftUI

public extension Color {
    /// Sight's accent: a bright cyan that reads well over any camera image.
    static let sightAccent = Color(red: 0.18, green: 0.86, blue: 0.96)
    /// Second accent for gradients and the text overlay.
    static let sightViolet = Color(red: 0.55, green: 0.42, blue: 1.0)
}

public extension ShapeStyle where Self == LinearGradient {
    static var sightGradient: LinearGradient {
        LinearGradient(colors: [.sightAccent, .sightViolet], startPoint: .leading, endPoint: .trailing)
    }
}

/// A stable color per object label, so every "cup" box is the same color in every frame.
public enum LabelPalette {
    public static let colors: [Color] = [
        .sightAccent,
        .sightViolet,
        Color(red: 1.0, green: 0.62, blue: 0.24),
        Color(red: 0.35, green: 0.9, blue: 0.5),
        Color(red: 1.0, green: 0.4, blue: 0.6),
        Color(red: 1.0, green: 0.86, blue: 0.3),
    ]

    /// Index into `colors`. Swift's `hashValue` changes on every launch, so this sums the
    /// characters instead.
    public static func index(for label: String) -> Int {
        label.unicodeScalars.reduce(0) { ($0 + Int($1.value)) % 997 } % colors.count
    }

    public static func color(for label: String) -> Color {
        colors[index(for: label)]
    }
}
