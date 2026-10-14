import AVFoundation
import SightCore

/// Owns the `AVCaptureSession`. Session work runs on `sessionQueue`; frames arrive on `videoQueue`.
///
/// Adapted from Lumen's camera: the same queues, rotation and recovery, minus photo capture,
/// which Sight doesn't need.
public final class CameraService: NSObject, CameraSource, @unchecked Sendable {

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.irenapoghosyan.sight.session")
    private let videoQueue = DispatchQueue(label: "com.irenapoghosyan.sight.video", qos: .userInitiated)
    private let videoOutput = AVCaptureVideoDataOutput()
    private var isConfigured = false
    private var observers: [NSObjectProtocol] = []

    private let callbackLock = NSLock()
    private var frameHandler: (@Sendable (AnalysisImage) -> Void)?

    override public init() {
        super.init()
    }

    deinit {
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
    }

    public var captureSession: AVCaptureSession? { session }

    public var onFrame: (@Sendable (AnalysisImage) -> Void)? {
        get { callbackLock.withLock { frameHandler } }
        set { callbackLock.withLock { frameHandler = newValue } }
    }

    // MARK: - Permission

    public func requestAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return true
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .video)
        default: return false
        }
    }

    // MARK: - Lifecycle

    public func start() async throws {
        try await onSessionQueue { [self] in
            if !isConfigured {
                try configureSession()
                observeSession()
                isConfigured = true
            }
            if !session.isRunning { session.startRunning() }
        }
    }

    public func stop() {
        sessionQueue.async { [self] in
            if session.isRunning { session.stopRunning() }
        }
    }

    // MARK: - Configuration (sessionQueue only)

    private func configureSession() throws {
        // The simulator has no camera, so this is where it lands in Photos mode.
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraError.noCamera
        }
        let input = try AVCaptureDeviceInput(device: device)

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        // 720p is plenty for Vision and keeps every analysis fast.
        if session.canSetSessionPreset(.hd1280x720) { session.sessionPreset = .hd1280x720 }

        guard session.canAddInput(input) else { throw CameraError.configurationFailed }
        session.addInput(input)

        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        // Never queue old frames: results should describe what the camera sees now.
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        guard session.canAddOutput(videoOutput) else { throw CameraError.configurationFailed }
        session.addOutput(videoOutput)

        // Deliver frames upright for a phone held in portrait, matching the preview.
        if let connection = videoOutput.connection(with: .video), connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }

        try device.lockForConfiguration()
        if device.isFocusModeSupported(.continuousAutoFocus) { device.focusMode = .continuousAutoFocus }
        if device.isExposureModeSupported(.continuousAutoExposure) { device.exposureMode = .continuousAutoExposure }
        device.unlockForConfiguration()
    }

    /// Media services can be reset by the system; restart instead of leaving a frozen preview.
    private func observeSession() {
        observers.append(NotificationCenter.default.addObserver(
            forName: AVCaptureSession.runtimeErrorNotification,
            object: session,
            queue: nil
        ) { [weak self] _ in
            self?.sessionQueue.async {
                guard let self, !self.session.isRunning else { return }
                self.session.startRunning()
            }
        })
    }

    private func onSessionQueue(_ work: @escaping () throws -> Void) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async {
                continuation.resume(with: Result { try work() })
            }
        }
    }
}

// MARK: - Frames

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let onFrame, let pixelBuffer = sampleBuffer.imageBuffer else { return }
        onFrame(AnalysisImage(pixelBuffer: pixelBuffer))
    }
}
