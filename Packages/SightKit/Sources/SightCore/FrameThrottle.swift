import Foundation

/// Decides which camera frames get analyzed.
///
/// The camera delivers ~30 frames a second; analyzing all of them would heat the phone
/// and queue up stale work. A frame is let through only when the previous one is done
/// and enough time has passed.
public struct FrameThrottle: Sendable {
    public let minimumInterval: TimeInterval
    public private(set) var isBusy = false
    private var lastStart: TimeInterval?

    /// - Parameter maxRate: The most frames per second to analyze.
    public init(maxRate: Double = 15) {
        self.minimumInterval = maxRate > 0 ? 1 / maxRate : 0
    }

    /// Returns `true` and marks the throttle busy when this frame should be analyzed.
    public mutating func shouldProcess(at time: TimeInterval) -> Bool {
        guard !isBusy else { return false }
        if let lastStart, time - lastStart < minimumInterval { return false }
        lastStart = time
        isBusy = true
        return true
    }

    /// Call when the analysis of the let-through frame has finished.
    public mutating func finish() {
        isBusy = false
    }

    public mutating func reset() {
        isBusy = false
        lastStart = nil
    }
}
