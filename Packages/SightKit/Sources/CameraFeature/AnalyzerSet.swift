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

    /// Every mode with an analyzer, in picker order. Some (Cutout) only work on stills.
    public var modes: [AnalysisMode] {
        AnalysisMode.allCases.filter { live[$0] != nil || photo[$0] != nil }
    }

    /// Whether the mode runs on the live camera, or needs a captured frame or a photo.
    public func isLive(_ mode: AnalysisMode) -> Bool {
        live[mode] != nil
    }
}
