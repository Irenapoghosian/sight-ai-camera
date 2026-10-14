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
        XCTAssertTrue(AnalysisResult.text([]).isEmpty)
    }

    // MARK: - Helpers

    private func text(_ string: String, confidence: Float = 1, minX: CGFloat = 0, minY: CGFloat = 0) -> RecognizedText {
        RecognizedText(string: string, confidence: confidence, boundingBox: CGRect(x: minX, y: minY, width: 0.3, height: 0.05))
    }
}
