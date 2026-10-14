import XCTest
@testable import SightCore

final class PerformanceMeterTests: XCTestCase {

    func testFramesPerSecondCountsTheWindow() {
        var meter = PerformanceMeter(window: 2)
        for frame in 0...10 {
            meter.record(finishedAt: Double(frame) * 0.1, latency: 0.02)
        }
        XCTAssertEqual(meter.metrics.framesPerSecond, 10, accuracy: 0.001)
    }

    func testOldFramesLeaveTheWindow() {
        var meter = PerformanceMeter(window: 1)
        meter.record(finishedAt: 0, latency: 0.01)
        meter.record(finishedAt: 0.1, latency: 0.01)
        // After a long pause only the new frame is left, so there is no rate yet.
        meter.record(finishedAt: 5, latency: 0.01)
        XCTAssertEqual(meter.metrics.framesPerSecond, 0)
    }

    func testLatencyIsSmoothed() {
        var meter = PerformanceMeter(smoothing: 0.5)
        meter.record(finishedAt: 0, latency: 0.010)
        XCTAssertEqual(meter.metrics.latencyMilliseconds, 10, accuracy: 0.001)
        meter.record(finishedAt: 0.1, latency: 0.030)
        XCTAssertEqual(meter.metrics.latencyMilliseconds, 20, accuracy: 0.001)
    }

    func testResetClearsEverything() {
        var meter = PerformanceMeter()
        meter.record(finishedAt: 0, latency: 0.01)
        meter.record(finishedAt: 0.1, latency: 0.01)
        meter.reset()
        XCTAssertEqual(meter.metrics, .zero)
    }
}

final class FrameThrottleTests: XCTestCase {

    func testABusyThrottleDropsFrames() {
        var throttle = FrameThrottle(maxRate: 1000)
        XCTAssertTrue(throttle.shouldProcess(at: 0))
        XCTAssertFalse(throttle.shouldProcess(at: 1))
        throttle.finish()
        XCTAssertTrue(throttle.shouldProcess(at: 2))
    }

    func testFramesArrivingTooSoonAreDropped() {
        var throttle = FrameThrottle(maxRate: 10)
        XCTAssertTrue(throttle.shouldProcess(at: 0))
        throttle.finish()
        XCTAssertFalse(throttle.shouldProcess(at: 0.05))
        XCTAssertTrue(throttle.shouldProcess(at: 0.1))
    }

    func testResetForgetsTheLastFrame() {
        var throttle = FrameThrottle(maxRate: 1)
        XCTAssertTrue(throttle.shouldProcess(at: 0))
        throttle.reset()
        XCTAssertFalse(throttle.isBusy)
        XCTAssertTrue(throttle.shouldProcess(at: 0.1))
    }
}

final class AnalysisImageTests: XCTestCase {

    func testSidewaysOrientationsSwapWidthAndHeight() {
        XCTAssertEqual(AnalysisImage.uprightSize(width: 4, height: 3, orientation: .right), CGSize(width: 3, height: 4))
        XCTAssertEqual(AnalysisImage.uprightSize(width: 4, height: 3, orientation: .leftMirrored), CGSize(width: 3, height: 4))
        XCTAssertEqual(AnalysisImage.uprightSize(width: 4, height: 3, orientation: .down), CGSize(width: 4, height: 3))
    }
}

final class AnalysisModeTests: XCTestCase {

    func testEveryModeHasATitleAndIcon() {
        for mode in AnalysisMode.allCases {
            XCTAssertFalse(mode.title.isEmpty)
            XCTAssertFalse(mode.systemImage.isEmpty)
            XCTAssertFalse(mode.hint.isEmpty)
        }
    }
}
