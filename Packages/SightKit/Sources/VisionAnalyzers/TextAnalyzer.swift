import SightCore
import Vision

/// Reads printed and handwritten text, fully on device.
public struct TextAnalyzer: FrameAnalyzer {
    /// `fast` keeps up with the live camera; `accurate` is for still photos.
    public enum Accuracy: Sendable {
        case fast
        case accurate
    }

    public let mode: AnalysisMode = .text
    private let accuracy: Accuracy

    public init(accuracy: Accuracy = .fast) {
        self.accuracy = accuracy
    }

    public func analyze(_ image: AnalysisImage) async throws -> AnalysisResult {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = accuracy == .fast ? .fast : .accurate
        request.usesLanguageCorrection = accuracy == .accurate
        if accuracy == .accurate {
            request.automaticallyDetectsLanguage = true
        }
        request.preferCPUOnSimulator()
        try image.makeRequestHandler().perform([request])

        let lines = (request.results ?? []).compactMap { observation -> SightCore.RecognizedText? in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            return SightCore.RecognizedText(
                string: candidate.string,
                confidence: candidate.confidence,
                boundingBox: observation.boundingBox
            )
        }
        return .text(ResultRules.filteredText(lines))
    }
}
