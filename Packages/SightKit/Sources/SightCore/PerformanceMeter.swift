import Foundation

/// What the metrics pill shows.
public struct PerformanceMetrics: Equatable, Sendable {
    /// Analyzed frames per second (not the camera's frame rate).
    public var framesPerSecond: Double
    /// How long one analysis takes, smoothed.
    public var latencyMilliseconds: Double

    public init(framesPerSecond: Double = 0, latencyMilliseconds: Double = 0) {
        self.framesPerSecond = framesPerSecond
        self.latencyMilliseconds = latencyMilliseconds
    }

    public static let zero = PerformanceMetrics()
}

/// Measures throughput over a sliding window and smooths latency so the numbers don't flicker.
public struct PerformanceMeter: Sendable {
    public private(set) var metrics = PerformanceMetrics.zero

    private let window: TimeInterval
    private let smoothing: Double
    private var timestamps: [TimeInterval] = []

    /// - Parameters:
    ///   - window: Seconds of history used for frames per second.
    ///   - smoothing: Weight of each new latency sample (exponential moving average), 0…1.
    public init(window: TimeInterval = 1, smoothing: Double = 0.2) {
        self.window = window
        self.smoothing = smoothing
    }

    /// Call once per finished analysis.
    public mutating func record(finishedAt time: TimeInterval, latency: TimeInterval) {
        timestamps.append(time)
        timestamps.removeAll { $0 < time - window }

        if timestamps.count > 1, let first = timestamps.first, time > first {
            metrics.framesPerSecond = Double(timestamps.count - 1) / (time - first)
        } else {
            metrics.framesPerSecond = 0
        }

        let sample = latency * 1000
        if metrics.latencyMilliseconds == 0 {
            metrics.latencyMilliseconds = sample
        } else {
            metrics.latencyMilliseconds += smoothing * (sample - metrics.latencyMilliseconds)
        }
    }

    public mutating func reset() {
        timestamps.removeAll()
        metrics = .zero
    }
}
