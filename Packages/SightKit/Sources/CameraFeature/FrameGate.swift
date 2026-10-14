import Foundation
import SightCore

/// The hand-off between the camera's video queue and the analysis loop.
///
/// Frames that arrive while the previous one is still being analyzed (or too soon after it)
/// are dropped right away, so the camera never waits and no stale frame is analyzed.
final class FrameGate: @unchecked Sendable {
    let frames: AsyncStream<AnalysisImage>

    private let continuation: AsyncStream<AnalysisImage>.Continuation
    private let lock = NSLock()
    private var throttle: FrameThrottle
    private let clock: @Sendable () -> TimeInterval

    init(maxRate: Double, clock: @escaping @Sendable () -> TimeInterval) {
        let (stream, streamContinuation) = AsyncStream.makeStream(of: AnalysisImage.self, bufferingPolicy: .bufferingNewest(1))
        self.frames = stream
        self.continuation = streamContinuation
        self.throttle = FrameThrottle(maxRate: maxRate)
        self.clock = clock
    }

    /// Called from the camera's queue.
    func offer(_ image: AnalysisImage) {
        let now = clock()
        let accepted = lock.withLock { throttle.shouldProcess(at: now) }
        if accepted { continuation.yield(image) }
    }

    /// Called by the analysis loop when a frame is done.
    func finish() {
        lock.withLock { throttle.finish() }
    }

    func close() {
        continuation.finish()
    }
}
