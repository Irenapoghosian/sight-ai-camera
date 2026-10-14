import CameraCapture
import CameraFeature
import SightCore
import VisionAnalyzers

/// The composition root: the only place that knows the concrete camera, analyzers and models.
@MainActor
final class AppContainer {
    let cameraModel: CameraViewModel

    init(camera: any CameraSource, analyzers: AnalyzerSet) {
        cameraModel = CameraViewModel(camera: camera, analyzers: analyzers)
    }

    /// Apple's YOLOv3 Tiny comes in three sizes; whichever is in `App/Resources` is used.
    static let objectModelNames = ["YOLOv3Tiny", "YOLOv3TinyFP16", "YOLOv3TinyInt8LUT"]

    static func live() -> AppContainer {
        var live: [AnalysisMode: any FrameAnalyzer] = [
            .classify: ClassificationAnalyzer(),
            .text: TextAnalyzer(accuracy: .fast),
        ]
        var photo: [AnalysisMode: any FrameAnalyzer] = [
            .classify: ClassificationAnalyzer(),
            // A still photo can afford the slower, more accurate text model.
            .text: TextAnalyzer(accuracy: .accurate),
        ]

        // Objects mode appears only when the model is bundled.
        if let url = ModelLoader.compiledModelURL(named: objectModelNames) {
            let detector = ObjectDetectionAnalyzer { try ModelLoader.load(url) }
            live[.objects] = detector
            photo[.objects] = detector
        }

        return AppContainer(camera: CameraService(), analyzers: AnalyzerSet(live: live, photo: photo))
    }
}
