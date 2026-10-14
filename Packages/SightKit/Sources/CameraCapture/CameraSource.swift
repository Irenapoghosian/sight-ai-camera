import AVFoundation
import SightCore

/// What the camera screen needs from a camera. `CameraService` is the real one;
/// tests use a fake that emits frames on demand.
public protocol CameraSource: AnyObject, Sendable {
    /// The session behind the live preview, or `nil` when there is nothing to show.
    var captureSession: AVCaptureSession? { get }
    /// Called on a background queue for every frame, already upright.
    var onFrame: (@Sendable (AnalysisImage) -> Void)? { get set }

    func requestAccess() async -> Bool
    func start() async throws
    func stop()
}

public enum CameraError: LocalizedError, Equatable {
    case noCamera
    case configurationFailed

    public var errorDescription: String? {
        switch self {
        case .noCamera: "This device has no camera. Pick a photo instead."
        case .configurationFailed: "The camera couldn't be set up."
        }
    }
}
