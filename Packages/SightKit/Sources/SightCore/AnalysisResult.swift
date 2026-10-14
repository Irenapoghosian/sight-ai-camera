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

/// One object found in the image, e.g. "cup" at 0.87 with its box.
public struct DetectedObject: Equatable, Sendable {
    public let label: String
    /// 0…1
    public let confidence: Float
    /// Normalized Vision coordinates: 0…1, origin at the bottom-left of the image.
    public let boundingBox: CGRect

    public init(label: String, confidence: Float, boundingBox: CGRect) {
        self.label = label
        self.confidence = confidence
        self.boundingBox = boundingBox
    }

    /// "diningtable" → "Dining table".
    public var displayName: String { ResultRules.displayName(for: label) }
}

/// A `CGImage` that can travel between threads and be compared.
///
/// `@unchecked Sendable`: a `CGImage` is immutable. Two values are equal when they hold
/// the very same image, which is all the UI needs to know whether to redraw.
public struct CutoutImage: @unchecked Sendable, Equatable {
    public let cgImage: CGImage

    public init(_ cgImage: CGImage) {
        self.cgImage = cgImage
    }

    public static func == (lhs: CutoutImage, rhs: CutoutImage) -> Bool {
        lhs.cgImage === rhs.cgImage
    }
}

/// The subject (or subjects) lifted off the background, cropped to fit, on transparency.
public struct Cutout: Equatable, Sendable {
    public let image: CutoutImage
    public let subjectCount: Int

    public init(image: CutoutImage, subjectCount: Int) {
        self.image = image
        self.subjectCount = subjectCount
    }

    /// "1 subject", "3 subjects"
    public var summary: String {
        subjectCount == 1 ? "1 subject" : "\(subjectCount) subjects"
    }
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
    case objects([DetectedObject])
    case text([RecognizedText])
    /// `nil` when no subject stands out from the background.
    case cutout(Cutout?)

    public var mode: AnalysisMode {
        switch self {
        case .classifications: .classify
        case .objects: .objects
        case .text: .text
        case .cutout: .cutout
        }
    }

    public var isEmpty: Bool {
        switch self {
        case .classifications(let labels): labels.isEmpty
        case .objects(let objects): objects.isEmpty
        case .text(let lines): lines.isEmpty
        case .cutout(let cutout): cutout == nil
        }
    }

    /// The text in reading order, ready for the clipboard. `nil` outside text mode or when nothing was read.
    public var copyableText: String? {
        guard case .text(let lines) = self else { return nil }
        let text = ResultRules.joinedText(lines)
        return text.isEmpty ? nil : text
    }
}
