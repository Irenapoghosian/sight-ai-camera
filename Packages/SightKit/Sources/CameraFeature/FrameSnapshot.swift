import CoreImage
import SightCore

extension AnalysisImage {
    private static let context = CIContext()

    /// An upright copy that outlives the camera's reusable pixel buffer, for "capture a frame".
    func snapshot() -> CGImage? {
        switch source {
        case .cgImage(let image) where orientation == .up:
            return image
        case .cgImage(let image):
            return Self.render(CIImage(cgImage: image).oriented(orientation))
        case .pixelBuffer(let buffer):
            return Self.render(CIImage(cvPixelBuffer: buffer).oriented(orientation))
        }
    }

    private static func render(_ image: CIImage) -> CGImage? {
        context.createCGImage(image, from: image.extent)
    }
}
