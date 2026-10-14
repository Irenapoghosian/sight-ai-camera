import AVFoundation
import SwiftUI
import UIKit

/// The live camera image. Fills the view and crops the edges, like the Camera app.
public struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    public init(session: AVCaptureSession) {
        self.session = session
    }

    public func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        return view
    }

    public func updateUIView(_ uiView: PreviewView, context: Context) {
        if uiView.previewLayer.session !== session {
            uiView.previewLayer.session = session
        }
    }

    /// Hosts the preview layer as a sublayer, so no layer-class casting is needed.
    public final class PreviewView: UIView {
        let previewLayer = AVCaptureVideoPreviewLayer()

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .black
            previewLayer.videoGravity = .resizeAspectFill
            layer.addSublayer(previewLayer)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) is not supported")
        }

        override public func layoutSubviews() {
            super.layoutSubviews()
            previewLayer.frame = bounds
            // Portrait, the same rotation as the analyzed frames, so overlays line up.
            if let connection = previewLayer.connection, connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
        }
    }
}
