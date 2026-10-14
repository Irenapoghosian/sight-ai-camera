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
