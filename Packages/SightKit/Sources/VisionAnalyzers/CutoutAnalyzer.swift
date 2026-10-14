import CoreImage
import SightCore
import Vision

/// Lifts the subject off its background, like long-pressing a photo in the Photos app.
///
/// Uses Vision's foreground instance mask (iOS 17), so no model ships with the app.
/// It is meant for stills: one lift takes a few hundred milliseconds.
public final class CutoutAnalyzer: FrameAnalyzer, @unchecked Sendable {
    public let mode: AnalysisMode = .cutout

    /// Thread-safe and expensive to create, so one is shared by every call.
    private let context = CIContext()

    public init() {}

    public func analyze(_ image: AnalysisImage) async throws -> AnalysisResult {
        // Hand Vision an upright image, so the lifted subject comes back upright too.
        let handler = VNImageRequestHandler(ciImage: image.uprightCIImage(), options: [:])
        let request = VNGenerateForegroundInstanceMaskRequest()
        request.preferCPUOnSimulator()
        try handler.perform([request])

        guard let observation = request.results?.first, !observation.allInstances.isEmpty else {
            return .cutout(nil)
        }

        let masked = try observation.generateMaskedImage(
            ofInstances: observation.allInstances,
            from: handler,
            croppedToInstancesExtent: true
        )
        let lifted = CIImage(cvPixelBuffer: masked)
        guard let cgImage = context.createCGImage(lifted, from: lifted.extent) else {
            return .cutout(nil)
        }
        return .cutout(SightCore.Cutout(
            image: SightCore.CutoutImage(cgImage),
            subjectCount: observation.allInstances.count
        ))
    }
}
