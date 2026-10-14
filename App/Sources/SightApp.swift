import CameraFeature
import SwiftUI

@main
struct SightApp: App {
    /// Built once at launch; owns the camera and the analyzers.
    @State private var container = AppContainer.live()

    var body: some Scene {
        WindowGroup {
            CameraScreen(model: container.cameraModel)
        }
    }
}
