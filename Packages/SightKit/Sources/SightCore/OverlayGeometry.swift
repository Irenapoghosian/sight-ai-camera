import CoreGraphics

/// Maps Vision's normalized boxes onto the view that shows the image.
public enum OverlayGeometry {

    /// How the image is scaled into the view.
    public enum ContentMode: Sendable {
        /// Fills the view and crops the overflow (the live camera preview).
        case fill
        /// Fits inside the view with letterboxing (a photo).
        case fit
    }

    /// - Parameters:
    ///   - normalizedRect: Vision coordinates, 0…1 with the origin at the bottom-left.
    ///   - imageSize: The upright image size.
    ///   - viewSize: The size of the view showing the image, centered.
    /// - Returns: The rectangle in view coordinates (origin top-left).
    public static func viewRect(
        for normalizedRect: CGRect,
        imageSize: CGSize,
        in viewSize: CGSize,
        contentMode: ContentMode
    ) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0, viewSize.width > 0, viewSize.height > 0 else { return .zero }

        let scaleX = viewSize.width / imageSize.width
        let scaleY = viewSize.height / imageSize.height
        let scale = contentMode == .fill ? max(scaleX, scaleY) : min(scaleX, scaleY)

        let shown = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let offset = CGPoint(x: (viewSize.width - shown.width) / 2, y: (viewSize.height - shown.height) / 2)

        return CGRect(
            x: offset.x + normalizedRect.minX * shown.width,
            y: offset.y + (1 - normalizedRect.maxY) * shown.height,
            width: normalizedRect.width * shown.width,
            height: normalizedRect.height * shown.height
        )
    }
}
