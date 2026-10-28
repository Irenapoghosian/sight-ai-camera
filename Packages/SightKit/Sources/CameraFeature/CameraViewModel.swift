import AVFoundation
import CameraCapture
import Foundation
import Observation
import SightCore
import UIKit

/// Drives the camera screen: permission, the live analysis loop, metrics and photo analysis.
@MainActor
@Observable
public final class CameraViewModel {

    public enum CameraState: Equatable {
        case idle
        case starting
        case running
        case denied
        case unavailable(String)
    }

    public private(set) var mode: AnalysisMode
    /// The latest live result, and the size of the frame it describes.
    public private(set) var result: AnalysisResult?
    public private(set) var frameSize: CGSize = .zero
    public private(set) var metrics = PerformanceMetrics.zero
    public private(set) var cameraState = CameraState.idle
    /// Freezes the results (the preview keeps moving) so they can be read or copied.
    public private(set) var isPaused = false
    public var photo: PhotoAnalysis?
    public var errorMessage: String?

    public let modes: [AnalysisMode]

    private let camera: any CameraSource
    private let analyzers: AnalyzerSet
    private let maxFrameRate: Double
    private let clock: @Sendable () -> TimeInterval
    @ObservationIgnored private var meter = PerformanceMeter()
    @ObservationIgnored private var gate: FrameGate?
    @ObservationIgnored private var loop: Task<Void, Never>?
    /// The newest camera frame, kept for "capture a frame" in still-only modes like Cutout.
    @ObservationIgnored private(set) var latestFrame: AnalysisImage?

    public init(
        camera: any CameraSource,
        analyzers: AnalyzerSet,
        maxFrameRate: Double = 15,
        clock: @escaping @Sendable () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
    ) {
        self.camera = camera
        self.analyzers = analyzers
        self.maxFrameRate = maxFrameRate
        self.clock = clock
        self.modes = analyzers.modes
        self.mode = analyzers.modes.first ?? .classify
    }

    public var captureSession: AVCaptureSession? { camera.captureSession }

    /// `false` for modes such as Cutout that work on a captured frame or a photo instead.
    public var isLiveMode: Bool { analyzers.isLive(mode) }

    /// The FPS pill and the pause button only mean something while frames are analyzed live;
    /// in still-only modes like Cutout they would just read "0 FPS".
    public var showsLiveControls: Bool { cameraState == .running && isLiveMode }

    /// The text to put on the clipboard: from the photo when one is open, otherwise from the camera.
    public var copyableText: String? {
        if let photo { return photo.result?.copyableText }
        return result?.copyableText
    }

    // MARK: - Camera

    public func start() async {
        guard cameraState != .running, cameraState != .starting else { return }
        cameraState = .starting

        guard await camera.requestAccess() else {
            cameraState = .denied
            return
        }

        let gate = FrameGate(maxRate: maxFrameRate, clock: clock)
        camera.onFrame = { image in gate.offer(image) }
        do {
            try await camera.start()
        } catch {
            camera.onFrame = nil
            cameraState = .unavailable(error.localizedDescription)
            return
        }

        // `stop()` may have been called while the camera was starting.
        guard cameraState == .starting else {
            camera.onFrame = nil
            camera.stop()
            return
        }

        self.gate = gate
        cameraState = .running
        runLoop(gate)
    }

    public func stop() {
        camera.onFrame = nil
        camera.stop()
        gate?.close()
        loop?.cancel()
        gate = nil
        loop = nil
        latestFrame = nil
        if cameraState == .running || cameraState == .starting {
            cameraState = .idle
        }
    }

    public func select(_ newMode: AnalysisMode) {
        guard newMode != mode, modes.contains(newMode) else { return }
        mode = newMode
        result = nil
        meter.reset()
        metrics = .zero
        if photo != nil {
            Task { await analyzeCurrentPhoto() }
        }
    }

    public func togglePause() {
        isPaused.toggle()
        if !isPaused {
            meter.reset()
        }
    }

    // MARK: - Photos

    public func analyze(photo image: UIImage) async {
        guard let source = AnalysisImage(uiImage: image) else {
            errorMessage = "This photo couldn't be read."
            return
        }
        photo = PhotoAnalysis(image: image, source: source)
        await analyzeCurrentPhoto()
    }

    /// Freezes the current camera frame and analyzes it like a picked photo.
    public func captureFrame() async {
        guard let frame = latestFrame, let snapshot = frame.snapshot() else {
            errorMessage = "The camera isn't ready yet. Try again in a moment."
            return
        }
        photo = PhotoAnalysis(image: UIImage(cgImage: snapshot), source: AnalysisImage(cgImage: snapshot))
        await analyzeCurrentPhoto()
    }

    public func closePhoto() {
        photo = nil
    }

    private func analyzeCurrentPhoto() async {
        guard var current = photo, let analyzer = analyzers.photo[mode] else { return }
        let requestedMode = mode
        current.result = nil
        current.didFail = false
        current.isAnalyzing = true
        photo = current

        let started = clock()
        let output = try? await analyzer.analyze(current.source)

        // The user may have closed the sheet or switched modes meanwhile.
        guard photo?.id == current.id, mode == requestedMode else { return }
        current.result = output
        current.didFail = output == nil
        current.isAnalyzing = false
        current.latencyMilliseconds = (clock() - started) * 1000
        photo = current
    }

    // MARK: - Live loop

    private func runLoop(_ gate: FrameGate) {
        loop?.cancel()
        loop = Task { [weak self] in
            for await image in gate.frames {
                await self?.process(image)
                gate.finish()
            }
        }
    }

    private func process(_ image: AnalysisImage) async {
        latestFrame = image
        guard !isPaused, let analyzer = analyzers.live[mode] else { return }
        let requestedMode = mode
        let started = clock()

        // A dropped frame is fine: the next one arrives a few milliseconds later.
        guard let output = try? await analyzer.analyze(image) else { return }
        guard mode == requestedMode, !isPaused, !Task.isCancelled else { return }

        let finished = clock()
        meter.record(finishedAt: finished, latency: finished - started)
        result = output
        frameSize = image.size
        metrics = meter.metrics
    }
}
