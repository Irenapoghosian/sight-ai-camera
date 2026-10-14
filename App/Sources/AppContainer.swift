import CameraCapture
import CameraFeature
import SightCore
import VisionAnalyzers

/// The composition root: the only place that knows the concrete camera and analyzers.
@MainActor
final class AppContainer {
    let cameraModel: CameraViewModel

    init(camera: any CameraSource, analyzers: AnalyzerSet) {
        cameraModel = CameraViewModel(camera: camera, analyzers: analyzers)
    }

    static func live() -> AppContainer {
        AppContainer(
            camera: CameraService(),
            analyzers: AnalyzerSet(
                // Fast enough to keep up with the camera.
                live: [
                    .classify: ClassificationAnalyzer(),
                    .text: TextAnalyzer(accuracy: .fast),
                ],
                // A still photo can afford the slower, more accurate text model.
                photo: [
                    .classify: ClassificationAnalyzer(),
                    .text: TextAnalyzer(accuracy: .accurate),
                ]
            )
        )
    }
}
