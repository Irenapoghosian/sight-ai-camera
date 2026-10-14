import SightCore
import SwiftUI

/// Boxes for objects or text, drawn over the image the result came from.
struct ResultOverlay: View {
    let result: AnalysisResult?
    let imageSize: CGSize
    let contentMode: OverlayGeometry.ContentMode

    var body: some View {
        switch result {
        case .objects(let objects)?:
            ObjectBoxesOverlay(objects: objects, imageSize: imageSize, contentMode: contentMode)
        case .text(let lines)?:
            TextBoxesOverlay(lines: lines, imageSize: imageSize, contentMode: contentMode)
        case .classifications?, nil:
            EmptyView()
        }
    }
}
