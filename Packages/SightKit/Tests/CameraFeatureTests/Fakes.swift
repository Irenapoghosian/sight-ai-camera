import AVFoundation
import CameraCapture
import CoreGraphics
import Foundation
import SightCore
import XCTest

/// A camera that starts instantly and emits frames on demand.
final class FakeCamera: CameraSource, @unchecked Sendable {
    var allowsAccess = true
    var startError: Error?
    private(set) var startCount = 0
    private(set) var stopCount = 0

    private let lock = NSLock()
    private var handler: (@Sendable (AnalysisImage) -> Void)?

    var captureSession: AVCaptureSession? { nil }

    var onFrame: (@Sendable (AnalysisImage) -> Void)? {
        get { lock.withLock { handler } }
        set { lock.withLock { handler = newValue } }
    }

    func requestAccess() async -> Bool { allowsAccess }

    func start() async throws {
        startCount += 1
        if let startError { throw startError }
    }

    func stop() {
        stopCount += 1
    }

    func emit(_ image: AnalysisImage) {
        onFrame?(image)
    }
}

/// Returns a canned result and counts its calls.
final class FakeAnalyzer: FrameAnalyzer, @unchecked Sendable {
    struct Failure: Error {}

    let mode: AnalysisMode
    private let lock = NSLock()
    private let output: AnalysisResult?
    private var callCount = 0

    /// Pass `nil` to make every analysis fail.
    init(mode: AnalysisMode, output: AnalysisResult?) {
        self.mode = mode
        self.output = output
    }

    var calls: Int { lock.withLock { callCount } }

    func analyze(_ image: AnalysisImage) async throws -> AnalysisResult {
        lock.withLock { callCount += 1 }
        guard let output else { throw Failure() }
        return output
    }
}

/// A clock that moves 10 ms every time it is read, so latencies are predictable.
final class TickingClock: @unchecked Sendable {
    private let lock = NSLock()
    private var time: TimeInterval = 0

    func now() -> TimeInterval {
        lock.withLock {
            time += 0.01
            return time
        }
    }
}

enum Fixtures {
    static let labels = AnalysisResult.classifications([Classification(identifier: "coffee_mug", confidence: 0.91)])
    static let menu = AnalysisResult.text([
        RecognizedText(string: "Espresso", confidence: 0.98, boundingBox: CGRect(x: 0.1, y: 0.6, width: 0.4, height: 0.05)),
        RecognizedText(string: "Latte", confidence: 0.97, boundingBox: CGRect(x: 0.1, y: 0.5, width: 0.3, height: 0.05)),
    ])

    static let desk = AnalysisResult.objects([
        DetectedObject(label: "cup", confidence: 0.88, boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2)),
        DetectedObject(label: "laptop", confidence: 0.93, boundingBox: CGRect(x: 0.4, y: 0.3, width: 0.5, height: 0.4)),
    ])

    static func cgImage(width: Int = 8, height: Int = 4) -> CGImage {
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        guard let image = context?.makeImage() else { preconditionFailure("Couldn't draw a test image") }
        return image
    }

    static func frame(width: Int = 8, height: Int = 4) -> AnalysisImage {
        AnalysisImage(cgImage: cgImage(width: width, height: height))
    }
}

/// Polls until `condition` holds; async results land a few milliseconds after a frame.
@MainActor
func waitUntil(
    timeout: TimeInterval = 2,
    file: StaticString = #filePath,
    line: UInt = #line,
    _ condition: () -> Bool
) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() {
        guard Date() < deadline else {
            XCTFail("Timed out waiting for the condition", file: file, line: line)
            return
        }
        try await Task.sleep(for: .milliseconds(5))
    }
}
