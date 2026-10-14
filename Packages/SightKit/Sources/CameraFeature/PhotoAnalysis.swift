import ImageIO
import SightCore
import UIKit

/// A picked photo and what was found in it.
public struct PhotoAnalysis: Identifiable {
    public let id = UUID()
    public let image: UIImage
    let source: AnalysisImage
    public var result: AnalysisResult?
    public var latencyMilliseconds: Double = 0
    public var isAnalyzing = false
    public var didFail = false

    init(image: UIImage, source: AnalysisImage) {
        self.image = image
        self.source = source
    }

    /// The upright pixel size, for laying out overlays.
    public var imageSize: CGSize { source.size }
}

extension AnalysisImage {
    /// A photo with its EXIF rotation, so Vision sees it the way the user does.
    init?(uiImage: UIImage) {
        guard let cgImage = uiImage.cgImage else { return nil }
        self.init(cgImage: cgImage, orientation: CGImagePropertyOrientation(uiImage.imageOrientation))
    }
}

extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
