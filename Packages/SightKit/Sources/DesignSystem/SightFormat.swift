import Foundation

/// Number formatting for the result cards and the metrics pill.
public enum SightFormat {

    /// 0.873 → "87%"
    public static func percent(_ confidence: Float, locale: Locale = .current) -> String {
        let clamped = Double(min(max(confidence, 0), 1))
        return clamped.formatted(.percent.precision(.fractionLength(0)).locale(locale))
    }

    /// 14.6 → "15 FPS"
    public static func framesPerSecond(_ value: Double) -> String {
        "\(Int(value.rounded())) FPS"
    }

    /// 23.4 → "23 ms", 0.4 → "<1 ms"
    public static func milliseconds(_ value: Double) -> String {
        guard value > 0 else { return "– ms" }
        return value < 1 ? "<1 ms" : "\(Int(value.rounded())) ms"
    }
}
