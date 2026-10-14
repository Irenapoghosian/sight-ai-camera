import SightCore
import Vision

/// "What is this?" — Apple's built-in image classifier (1,300+ labels), fully on device.
public struct ClassificationAnalyzer: FrameAnalyzer {
    public let mode: AnalysisMode = .classify
    private let minimumConfidence: Float
    private let limit: Int

    public init(minimumConfidence: Float = 0.1, limit: Int = 3) {
        self.minimumConfidence = minimumConfidence
        self.limit = limit
    }

    public func analyze(_ image: AnalysisImage) async throws -> AnalysisResult {
        let request = VNClassifyImageRequest()
        request.preferCPUOnSimulator()
        try image.makeRequestHandler().perform([request])

        let labels = (request.results ?? []).map {
            SightCore.Classification(identifier: $0.identifier, confidence: $0.confidence)
        }
        return .classifications(ResultRules.topClassifications(labels, minimumConfidence: minimumConfidence, limit: limit))
    }
}
