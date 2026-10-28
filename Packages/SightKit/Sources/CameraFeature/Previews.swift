#if DEBUG
import AVFoundation
import CameraCapture
import SightCore
import SwiftUI

/// A camera that never starts a session, so Canvas can screenshot the chrome and cards.
private final class PreviewCamera: CameraSource, @unchecked Sendable {
    var captureSession: AVCaptureSession? { nil }
    var onFrame: (@Sendable (AnalysisImage) -> Void)?
    func requestAccess() async -> Bool { true }
    func start() async throws {}
    func stop() {}
}

private struct PreviewAnalyzer: FrameAnalyzer {
    let mode: AnalysisMode
    func analyze(_: AnalysisImage) async throws -> AnalysisResult { PreviewData.result(for: mode) }
}

private enum PreviewData {
    static func result(for mode: AnalysisMode) -> AnalysisResult {
        switch mode {
        case .classify:
            .classifications([
                Classification(identifier: "coffee_mug", confidence: 0.91),
                Classification(identifier: "cup", confidence: 0.64),
                Classification(identifier: "dining_table", confidence: 0.41),
            ])
        case .objects:
            .objects([
                DetectedObject(label: "cup", confidence: 0.88, boundingBox: CGRect(x: 0.12, y: 0.18, width: 0.22, height: 0.2)),
                DetectedObject(label: "laptop", confidence: 0.93, boundingBox: CGRect(x: 0.38, y: 0.28, width: 0.5, height: 0.42)),
            ])
        case .text:
            .text([
                RecognizedText(string: "Sight", confidence: 0.99, boundingBox: CGRect(x: 0.1, y: 0.62, width: 0.5, height: 0.08)),
                RecognizedText(string: "On-device AI camera", confidence: 0.96, boundingBox: CGRect(x: 0.1, y: 0.5, width: 0.7, height: 0.06)),
            ])
        case .cutout:
            .cutout(nil)
        }
    }
}

@MainActor
private func previewModel(mode: AnalysisMode) -> CameraViewModel {
    let live: [AnalysisMode: any FrameAnalyzer] = [
        .classify: PreviewAnalyzer(mode: .classify),
        .objects: PreviewAnalyzer(mode: .objects),
        .text: PreviewAnalyzer(mode: .text),
    ]
    var photo = live
    photo[.cutout] = PreviewAnalyzer(mode: .cutout)
    let model = CameraViewModel(camera: PreviewCamera(), analyzers: AnalyzerSet(live: live, photo: photo))
    model.select(mode)
    model.previewLive(result: live[mode] == nil ? nil : PreviewData.result(for: mode))
    return model
}

#Preview("Classify") {
    CameraScreen(model: previewModel(mode: .classify))
}

#Preview("Objects") {
    CameraScreen(model: previewModel(mode: .objects))
}

#Preview("Text") {
    CameraScreen(model: previewModel(mode: .text))
}

#Preview("Cutout") {
    CameraScreen(model: previewModel(mode: .cutout))
}
#endif
