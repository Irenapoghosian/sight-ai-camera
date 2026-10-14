import CoreGraphics
import XCTest
@testable import SightCore

final class ResultRulesTests: XCTestCase {

    func testTopClassificationsAreSortedFilteredAndLimited() {
        let labels = [
            Classification(identifier: "cat", confidence: 0.30),
            Classification(identifier: "dog", confidence: 0.92),
            Classification(identifier: "noise", confidence: 0.05),
            Classification(identifier: "animal", confidence: 0.85),
            Classification(identifier: "pet", confidence: 0.60),
        ]

        let top = ResultRules.topClassifications(labels, minimumConfidence: 0.1, limit: 3)

        XCTAssertEqual(top.map(\.identifier), ["dog", "animal", "pet"])
    }

    func testNothingAboveTheThresholdGivesAnEmptyList() {
        let labels = [Classification(identifier: "blur", confidence: 0.02)]
        XCTAssertTrue(ResultRules.topClassifications(labels).isEmpty)
    }

    func testDisplayNamesAreReadable() {
        XCTAssertEqual(ResultRules.displayName(for: "golden_retriever"), "Golden retriever")
        XCTAssertEqual(ResultRules.displayName(for: "sky"), "Sky")
        XCTAssertEqual(ResultRules.displayName(for: ""), "")
    }

    func testDarknetLabelsReadNaturally() {
        XCTAssertEqual(ResultRules.displayName(for: "tvmonitor"), "TV")
        XCTAssertEqual(ResultRules.displayName(for: "diningtable"), "Dining table")
        XCTAssertEqual(ResultRules.displayName(for: "cell phone"), "Cell phone")
    }

    func testTopObjectsAreSortedFilteredAndLimited() {
        let objects = [
            object("cup", 0.5),
            object("person", 0.9),
            object("ghost", 0.1),
            object("laptop", 0.7),
        ]

        let top = ResultRules.topObjects(objects, minimumConfidence: 0.35, limit: 2)

        XCTAssertEqual(top.map(\.label), ["person", "laptop"])
    }

    func testObjectsAreCountedPerLabel() {
        let objects = [
            object("cup", 0.6),
            object("person", 0.8),
            object("cup", 0.9),
            object("laptop", 0.95),
        ]

        let counts = ResultRules.objectCounts(objects)

        // Most frequent first; ties go to the more confident label.
        XCTAssertEqual(counts.map(\.label), ["cup", "laptop", "person"])
        XCTAssertEqual(counts.first?.count, 2)
        XCTAssertEqual(counts.first?.bestConfidence, 0.9)
        XCTAssertEqual(counts.first?.displayName, "Cup")
    }

    func testFilteredTextDropsBlankAndUnsureLines() {
        let lines = [
            text("OPEN", confidence: 0.9),
            text("   ", confidence: 0.9),
            text("smudge", confidence: 0.1),
        ]
        XCTAssertEqual(ResultRules.filteredText(lines).map(\.string), ["OPEN"])
    }

    func testTextIsReadTopToBottomThenLeftToRight() {
        // Vision's origin is bottom-left: y = 0.8 is above y = 0.5.
        let lines = [
            text("world", minX: 0.5, minY: 0.8),
            text("second line", minX: 0.1, minY: 0.5),
            text("Hello", minX: 0.1, minY: 0.81),
        ]

        XCTAssertEqual(ResultRules.readingOrder(lines).map(\.string), ["Hello", "world", "second line"])
        XCTAssertEqual(ResultRules.joinedText(lines), "Hello world\nsecond line")
    }

    func testCopyableTextOnlyExistsForText() {
        XCTAssertEqual(AnalysisResult.text([text("Menu", minX: 0.1, minY: 0.5)]).copyableText, "Menu")
        XCTAssertNil(AnalysisResult.text([]).copyableText)
        XCTAssertNil(AnalysisResult.classifications([Classification(identifier: "cup", confidence: 1)]).copyableText)
    }

    func testResultKnowsItsMode() {
        XCTAssertEqual(AnalysisResult.classifications([]).mode, .classify)
        XCTAssertEqual(AnalysisResult.text([]).mode, .text)
        XCTAssertEqual(AnalysisResult.objects([]).mode, .objects)
        XCTAssertTrue(AnalysisResult.objects([]).isEmpty)
        XCTAssertNil(AnalysisResult.objects([object("cup", 1)]).copyableText)
        XCTAssertTrue(AnalysisResult.text([]).isEmpty)
    }

    func testCutoutsAreComparedByImageAndSummarized() throws {
        let first = try makeImage()
        let second = try makeImage()

        XCTAssertEqual(CutoutImage(first), CutoutImage(first))
        XCTAssertNotEqual(CutoutImage(first), CutoutImage(second))
        XCTAssertEqual(Cutout(image: CutoutImage(first), subjectCount: 1).summary, "1 subject")
        XCTAssertEqual(Cutout(image: CutoutImage(first), subjectCount: 3).summary, "3 subjects")

        XCTAssertEqual(AnalysisResult.cutout(nil).mode, .cutout)
        XCTAssertTrue(AnalysisResult.cutout(nil).isEmpty)
        XCTAssertFalse(AnalysisResult.cutout(Cutout(image: CutoutImage(first), subjectCount: 1)).isEmpty)
    }

    // MARK: - Helpers

    private func makeImage() throws -> CGImage {
        let context = try XCTUnwrap(CGContext(
            data: nil, width: 2, height: 2, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        return try XCTUnwrap(context.makeImage())
    }

    private func object(_ label: String, _ confidence: Float) -> DetectedObject {
        DetectedObject(label: label, confidence: confidence, boundingBox: CGRect(x: 0.2, y: 0.2, width: 0.3, height: 0.3))
    }

    private func text(_ string: String, confidence: Float = 1, minX: CGFloat = 0, minY: CGFloat = 0) -> RecognizedText {
        RecognizedText(string: string, confidence: confidence, boundingBox: CGRect(x: minX, y: minY, width: 0.3, height: 0.05))
    }
}
