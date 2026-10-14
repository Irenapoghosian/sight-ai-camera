import CameraCapture
import SightCore
import UIKit
import XCTest
@testable import CameraFeature

@MainActor
final class CameraViewModelTests: XCTestCase {
    private var camera = FakeCamera()
    private var classifier = FakeAnalyzer(mode: .classify, output: Fixtures.labels)
    private var reader = FakeAnalyzer(mode: .text, output: Fixtures.menu)
    private let clock = TickingClock()

    private func makeModel(photo: [AnalysisMode: any FrameAnalyzer]? = nil) -> CameraViewModel {
        let clock = self.clock
        return CameraViewModel(
            camera: camera,
            analyzers: AnalyzerSet(live: [.classify: classifier, .text: reader], photo: photo),
            maxFrameRate: 1000,
            clock: { clock.now() }
        )
    }

    // MARK: - Camera

    func testStartRunsTheCamera() async {
        let model = makeModel()
        await model.start()

        XCTAssertEqual(model.cameraState, .running)
        XCTAssertEqual(camera.startCount, 1)
        XCTAssertNotNil(camera.onFrame)
    }

    func testDeniedAccessNeverStartsTheCamera() async {
        camera.allowsAccess = false
        let model = makeModel()
        await model.start()

        XCTAssertEqual(model.cameraState, .denied)
        XCTAssertEqual(camera.startCount, 0)
    }

    func testNoCameraFallsBackToPhotosMode() async {
        camera.startError = CameraError.noCamera
        let model = makeModel()
        await model.start()

        XCTAssertEqual(model.cameraState, .unavailable(CameraError.noCamera.localizedDescription))
        XCTAssertNil(camera.onFrame)
    }

    func testStopReleasesTheCamera() async {
        let model = makeModel()
        await model.start()
        model.stop()

        XCTAssertEqual(model.cameraState, .idle)
        XCTAssertEqual(camera.stopCount, 1)
        XCTAssertNil(camera.onFrame)
    }

    // MARK: - Live analysis

    func testFramesProduceResultsAndMetrics() async throws {
        let model = makeModel()
        await model.start()

        camera.emit(Fixtures.frame(width: 8, height: 4))
        try await waitUntil { model.result != nil }

        XCTAssertEqual(model.result, Fixtures.labels)
        XCTAssertEqual(model.frameSize, CGSize(width: 8, height: 4))
        XCTAssertEqual(model.metrics.latencyMilliseconds, 10, accuracy: 0.5)
    }

    func testSwitchingModesClearsTheResultAndUsesThatModesAnalyzer() async throws {
        let model = makeModel()
        await model.start()
        camera.emit(Fixtures.frame())
        try await waitUntil { model.result != nil }

        model.select(.text)
        XCTAssertNil(model.result)
        XCTAssertEqual(model.metrics, .zero)

        camera.emit(Fixtures.frame())
        try await waitUntil { model.result != nil }
        XCTAssertEqual(model.result, Fixtures.menu)
        XCTAssertEqual(reader.calls, 1)
        XCTAssertEqual(model.copyableText, "Espresso\nLatte")
    }

    func testObjectsModeUsesTheDetector() async throws {
        let detector = FakeAnalyzer(mode: .objects, output: Fixtures.desk)
        let clock = self.clock
        let model = CameraViewModel(
            camera: camera,
            analyzers: AnalyzerSet(live: [.classify: classifier, .objects: detector, .text: reader]),
            maxFrameRate: 1000,
            clock: { clock.now() }
        )
        XCTAssertEqual(model.modes, [.classify, .objects, .text])

        await model.start()
        model.select(.objects)
        camera.emit(Fixtures.frame())
        try await waitUntil { model.result != nil }

        XCTAssertEqual(model.result, Fixtures.desk)
        XCTAssertEqual(detector.calls, 1)
        XCTAssertNil(model.copyableText)
    }

    func testPausedFramesAreNotAnalyzed() async throws {
        let model = makeModel()
        await model.start()
        model.togglePause()

        camera.emit(Fixtures.frame())
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertTrue(model.isPaused)
        XCTAssertNil(model.result)
        XCTAssertEqual(classifier.calls, 0)
    }

    func testModesFollowTheAvailableAnalyzers() {
        let model = CameraViewModel(camera: camera, analyzers: AnalyzerSet(live: [.text: reader]))

        XCTAssertEqual(model.modes, [.text])
        XCTAssertEqual(model.mode, .text)

        model.select(.classify)
        XCTAssertEqual(model.mode, .text)
    }

    // MARK: - Photos

    func testPhotosUseThePhotoAnalyzer() async {
        let accurate = FakeAnalyzer(mode: .classify, output: Fixtures.labels)
        let model = makeModel(photo: [.classify: accurate, .text: reader])

        await model.analyze(photo: UIImage(cgImage: Fixtures.cgImage()))

        XCTAssertEqual(model.photo?.result, Fixtures.labels)
        XCTAssertEqual(model.photo?.isAnalyzing, false)
        XCTAssertEqual(model.photo?.didFail, false)
        XCTAssertEqual(model.photo?.latencyMilliseconds ?? 0, 10, accuracy: 0.5)
        XCTAssertEqual(accurate.calls, 1)
        XCTAssertEqual(classifier.calls, 0)
    }

    func testAFailedPhotoSaysSo() async {
        let broken = FakeAnalyzer(mode: .classify, output: nil)
        let model = makeModel(photo: [.classify: broken])

        await model.analyze(photo: UIImage(cgImage: Fixtures.cgImage()))

        XCTAssertNil(model.photo?.result)
        XCTAssertEqual(model.photo?.didFail, true)
    }

    func testSwitchingModesReanalyzesTheOpenPhoto() async throws {
        let model = makeModel()
        await model.analyze(photo: UIImage(cgImage: Fixtures.cgImage()))
        XCTAssertEqual(model.photo?.result, Fixtures.labels)

        model.select(.text)
        try await waitUntil { model.photo?.result == Fixtures.menu }
        XCTAssertEqual(model.copyableText, "Espresso\nLatte")

        model.closePhoto()
        XCTAssertNil(model.photo)
    }

    func testRotatedPhotosAreAnalyzedUpright() throws {
        let image = UIImage(cgImage: Fixtures.cgImage(width: 8, height: 4), scale: 1, orientation: .right)
        let source = try XCTUnwrap(AnalysisImage(uiImage: image))

        XCTAssertEqual(source.orientation, .right)
        XCTAssertEqual(source.size, CGSize(width: 4, height: 8))
        XCTAssertEqual(CGImagePropertyOrientation(UIImage.Orientation.upMirrored), .upMirrored)
    }
}
