import CoreGraphics
import XCTest
@testable import SightCore

final class OverlayGeometryTests: XCTestCase {

    func testTheWholeImageFillsAViewOfTheSameShape() {
        let rect = OverlayGeometry.viewRect(
            for: CGRect(x: 0, y: 0, width: 1, height: 1),
            imageSize: CGSize(width: 720, height: 1280),
            in: CGSize(width: 360, height: 640),
            contentMode: .fill
        )
        XCTAssertEqual(rect, CGRect(x: 0, y: 0, width: 360, height: 640))
    }

    func testVisionYAxisIsFlipped() {
        // A box at the bottom of the image in Vision space ends up at the bottom of the view.
        let rect = OverlayGeometry.viewRect(
            for: CGRect(x: 0, y: 0, width: 0.5, height: 0.25),
            imageSize: CGSize(width: 100, height: 100),
            in: CGSize(width: 100, height: 100),
            contentMode: .fit
        )
        XCTAssertEqual(rect, CGRect(x: 0, y: 75, width: 50, height: 25))
    }

    func testFitLetterboxesAWideImage() {
        // 200×100 in a 100×100 view → shown at 100×50, centered vertically.
        let rect = OverlayGeometry.viewRect(
            for: CGRect(x: 0, y: 0, width: 1, height: 1),
            imageSize: CGSize(width: 200, height: 100),
            in: CGSize(width: 100, height: 100),
            contentMode: .fit
        )
        XCTAssertEqual(rect, CGRect(x: 0, y: 25, width: 100, height: 50))
    }

    func testFillCropsAWideImage() {
        // 200×100 filling a 100×100 view → shown at 200×100, half of it off-screen.
        let rect = OverlayGeometry.viewRect(
            for: CGRect(x: 0.5, y: 0, width: 0.25, height: 1),
            imageSize: CGSize(width: 200, height: 100),
            in: CGSize(width: 100, height: 100),
            contentMode: .fill
        )
        XCTAssertEqual(rect, CGRect(x: 50, y: 0, width: 50, height: 100))
    }

    func testEmptySizesGiveAnEmptyRect() {
        let rect = OverlayGeometry.viewRect(
            for: CGRect(x: 0, y: 0, width: 1, height: 1),
            imageSize: .zero,
            in: CGSize(width: 100, height: 100),
            contentMode: .fit
        )
        XCTAssertEqual(rect, .zero)
    }
}
