import Foundation

/// What the camera is looking for. Each mode is served by one `FrameAnalyzer`.
public enum AnalysisMode: String, CaseIterable, Identifiable, Sendable {
    /// What is in the picture: "dog", "laptop", "sky"… (Vision image classification).
    case classify
    /// Printed and handwritten text (Vision text recognition).
    case text

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .classify: "Classify"
        case .text: "Text"
        }
    }

    /// SF Symbol shown in the mode picker.
    public var systemImage: String {
        switch self {
        case .classify: "sparkles"
        case .text: "text.viewfinder"
        }
    }

    /// One line under the picker so a first-time user knows what to point at.
    public var hint: String {
        switch self {
        case .classify: "Point at anything to see what it is"
        case .text: "Point at a sign, a page or a label"
        }
    }
}
