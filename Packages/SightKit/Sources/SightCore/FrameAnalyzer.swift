import Foundation

/// Turns one image into a result. Implementations must be safe to call off the main thread.
public protocol FrameAnalyzer: Sendable {
    var mode: AnalysisMode { get }
    func analyze(_ image: AnalysisImage) async throws -> AnalysisResult
}
