import SightCore

/// The analyzers for each mode: fast ones for the live camera and, optionally,
/// slower, more accurate ones for still photos.
public struct AnalyzerSet: Sendable {
    public var live: [AnalysisMode: any FrameAnalyzer]
    public var photo: [AnalysisMode: any FrameAnalyzer]

    public init(live: [AnalysisMode: any FrameAnalyzer], photo: [AnalysisMode: any FrameAnalyzer]? = nil) {
        self.live = live
        self.photo = photo ?? live
    }

    /// Modes that have a live analyzer, in picker order.
    public var modes: [AnalysisMode] {
        AnalysisMode.allCases.filter { live[$0] != nil }
    }
}
