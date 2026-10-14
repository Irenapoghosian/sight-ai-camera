import CoreGraphics
import Foundation

/// One label from image classification, e.g. "dog" at 0.92.
public struct Classification: Equatable, Sendable, Identifiable {
    public let identifier: String
    /// 0…1
    public let confidence: Float

    public init(identifier: String, confidence: Float) {
        self.identifier = identifier
        self.confidence = confidence
    }

    public var id: String { identifier }

    /// "golden_retriever" → "Golden retriever".
    public var displayName: String { ResultRules.displayName(for: identifier) }
}

/// One line of text found in the image.
public struct RecognizedText: Equatable, Sendable {
    public let string: String
    /// 0…1
    public let confidence: Float
    /// Normalized Vision coordinates: 0…1, origin at the bottom-left of the image.
    public let boundingBox: CGRect

    public init(string: String, confidence: Float, boundingBox: CGRect) {
        self.string = string
        self.confidence = confidence
        self.boundingBox = boundingBox
    }
}

/// What an analyzer found in one image.
public enum AnalysisResult: Equatable, Sendable {
    case classifications([Classification])
    case text([RecognizedText])

    public var mode: AnalysisMode {
        switch self {
        case .classifications: .classify
        case .text: .text
        }
    }

    public var isEmpty: Bool {
        switch self {
        case .classifications(let labels): labels.isEmpty
        case .text(let lines): lines.isEmpty
        }
    }

    /// The text in reading order, ready for the clipboard. `nil` outside text mode or when nothing was read.
    public var copyableText: String? {
        guard case .text(let lines) = self else { return nil }
        let text = ResultRules.joinedText(lines)
        return text.isEmpty ? nil : text
    }
}
