import Foundation

/// What the camera is looking for. Each mode is served by one `FrameAnalyzer`.
public enum AnalysisMode: String, CaseIterable, Identifiable, Sendable {
    /// What is in the picture: "dog", "laptop", "sky"… (Vision image classification).
    case classify
    /// Where things are: a box around every person, cup, laptop… (Core ML object detection).
    case objects
    /// Printed and handwritten text (Vision text recognition).
    case text
    /// The main subject lifted off its background, as a sticker (Vision subject lifting). Stills only.
    case cutout

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .classify: "Classify"
        case .objects: "Objects"
        case .text: "Text"
        case .cutout: "Cutout"
        }
    }

    /// SF Symbol shown in the mode picker.
    public var systemImage: String {
        switch self {
        case .classify: "sparkles"
        case .objects: "viewfinder"
        case .text: "text.viewfinder"
        case .cutout: "scissors"
        }
    }

    /// One line under the picker so a first-time user knows what to point at.
    public var hint: String {
        switch self {
        case .classify: "Point at anything to see what it is"
        case .objects: "Point at people, pets or things on a desk"
        case .text: "Point at a sign, a page or a label"
        case .cutout: "Capture a frame or pick a photo to lift its subject"
        }
    }
}
