import CoreGraphics
import CoreVideo
import Foundation
import ImageIO

/// A camera frame or a photo, ready for an analyzer.
///
/// `@unchecked Sendable`: pixel buffers and `CGImage`s are immutable once captured,
/// and each one is handed to exactly one analyzer.
public struct AnalysisImage: @unchecked Sendable {
    public enum Source {
        case pixelBuffer(CVPixelBuffer)
        case cgImage(CGImage)
    }

    public let source: Source
    /// How the pixels must be rotated to look upright.
    public let orientation: CGImagePropertyOrientation
    /// The upright size, after `orientation` is applied. Overlays are laid out against it.
    public let size: CGSize

    public init(pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation = .up) {
        let width = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let height = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        self.source = .pixelBuffer(pixelBuffer)
        self.orientation = orientation
        self.size = Self.uprightSize(width: width, height: height, orientation: orientation)
    }

    public init(cgImage: CGImage, orientation: CGImagePropertyOrientation = .up) {
        self.source = .cgImage(cgImage)
        self.orientation = orientation
        self.size = Self.uprightSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height), orientation: orientation)
    }

    /// Orientations 5–8 turn the image on its side, so width and height swap.
    static func uprightSize(width: CGFloat, height: CGFloat, orientation: CGImagePropertyOrientation) -> CGSize {
        switch orientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            CGSize(width: height, height: width)
        default:
            CGSize(width: width, height: height)
        }
    }
}
