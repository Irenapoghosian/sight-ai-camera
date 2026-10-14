import XCTest
@testable import DesignSystem

final class SightFormatTests: XCTestCase {
    private let english = Locale(identifier: "en_US")

    func testPercentIsRoundedAndClamped() {
        XCTAssertEqual(SightFormat.percent(0.873, locale: english), "87%")
        XCTAssertEqual(SightFormat.percent(1.4, locale: english), "100%")
        XCTAssertEqual(SightFormat.percent(-0.2, locale: english), "0%")
    }

    func testFramesPerSecond() {
        XCTAssertEqual(SightFormat.framesPerSecond(14.6), "15 FPS")
        XCTAssertEqual(SightFormat.framesPerSecond(0), "0 FPS")
    }

    func testLabelColorsAreStableAndInRange() {
        let index = LabelPalette.index(for: "person")
        XCTAssertEqual(LabelPalette.index(for: "person"), index)
        XCTAssertTrue(LabelPalette.colors.indices.contains(index))
        XCTAssertTrue(LabelPalette.colors.indices.contains(LabelPalette.index(for: "")))
    }

    func testMilliseconds() {
        XCTAssertEqual(SightFormat.milliseconds(23.4), "23 ms")
        XCTAssertEqual(SightFormat.milliseconds(0.4), "<1 ms")
        XCTAssertEqual(SightFormat.milliseconds(0), "– ms")
    }
}
