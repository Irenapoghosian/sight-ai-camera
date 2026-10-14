import CoreML
import Foundation
import SightCore
import Vision

/// "Where is everything?" — runs a Core ML object detector (YOLOv3 Tiny in the app) through Vision.
///
/// The model is injected, so this works with any detector whose pipeline ends in
/// non-maximum suppression (it returns `VNRecognizedObjectObservation`s). It is loaded
/// on first use, off the main thread, so launching the app stays instant.
public final class ObjectDetectionAnalyzer: FrameAnalyzer, @unchecked Sendable {
    public let mode: AnalysisMode = .objects

    private let loadModel: @Sendable () throws -> MLModel
    private let minimumConfidence: Float
    private let limit: Int
    private let lock = NSLock()
    private var visionModel: VNCoreMLModel?

    public init(
        minimumConfidence: Float = 0.35,
        limit: Int = 12,
        loadModel: @escaping @Sendable () throws -> MLModel
    ) {
        self.minimumConfidence = minimumConfidence
        self.limit = limit
        self.loadModel = loadModel
    }

    public func analyze(_ image: AnalysisImage) async throws -> AnalysisResult {
        let request = VNCoreMLRequest(model: try model())
        // Squash the whole frame into the model's square input, so boxes cover the full image.
        request.imageCropAndScaleOption = .scaleFill
        request.preferCPUOnSimulator()
        try image.makeRequestHandler().perform([request])

        let objects = (request.results ?? []).compactMap { result -> SightCore.DetectedObject? in
            guard
                let observation = result as? VNRecognizedObjectObservation,
                let best = observation.labels.first
            else { return nil }
            return SightCore.DetectedObject(label: best.identifier, confidence: best.confidence, boundingBox: observation.boundingBox)
        }
        return .objects(ResultRules.topObjects(objects, minimumConfidence: minimumConfidence, limit: limit))
    }

    /// Loaded once; later calls reuse it.
    private func model() throws -> VNCoreMLModel {
        try lock.withLock {
            if let visionModel { return visionModel }
            let loaded = try VNCoreMLModel(for: loadModel())
            visionModel = loaded
            return loaded
        }
    }
}

/// Finds and loads Core ML models compiled into the app.
public enum ModelLoader {
    /// The URL of the first compiled model (`.mlmodelc`) found with one of `names`.
    public static func compiledModelURL(named names: [String], in bundle: Bundle = .main) -> URL? {
        names.lazy.compactMap { bundle.url(forResource: $0, withExtension: "mlmodelc") }.first
    }

    /// Loads a compiled model. The simulator has no Neural Engine, so it runs there on the CPU.
    public static func load(_ url: URL) throws -> MLModel {
        let configuration = MLModelConfiguration()
        #if targetEnvironment(simulator)
        configuration.computeUnits = .cpuOnly
        #endif
        return try MLModel(contentsOf: url, configuration: configuration)
    }
}
