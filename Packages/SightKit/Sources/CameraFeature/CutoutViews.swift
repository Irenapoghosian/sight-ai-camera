import DesignSystem
import SightCore
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// The lifted subject, shown like a sticker: a white outline and a soft glow.
struct CutoutStickerView: View {
    let cutout: Cutout

    var body: some View {
        let image = Image(decorative: cutout.image.cgImage, scale: 1)
        image
            .resizable()
            .scaledToFit()
            // Four hard shadows trace a white outline around the transparent edges.
            .shadow(color: .white, radius: 0, x: 2, y: 0)
            .shadow(color: .white, radius: 0, x: -2, y: 0)
            .shadow(color: .white, radius: 0, x: 0, y: 2)
            .shadow(color: .white, radius: 0, x: 0, y: -2)
            .shadow(color: Color.sightAccent.opacity(0.5), radius: 18)
            .padding(24)
            .frame(maxWidth: .infinity, minHeight: 280)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .accessibilityElement()
            .accessibilityLabel("Lifted subject")
    }
}

/// "Subject lifted · 1 subject" and a Share button for the PNG sticker.
struct CutoutSummary: View {
    let cutout: Cutout

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Label("Subject lifted", systemImage: "scissors")
                    .font(.subheadline.weight(.semibold))
                Text(cutout.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            ShareLink(
                item: Sticker(image: cutout.image),
                preview: SharePreview("Sight sticker", image: Image(decorative: cutout.image.cgImage, scale: 1))
            ) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.sightAccent)
            .foregroundStyle(.black)
        }
    }
}

/// Shown on the camera in still-only modes: Cutout needs one sharp frame, not a stream.
struct CapturePrompt: View {
    let mode: AnalysisMode
    let capture: () -> Void

    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                Image(systemName: mode.systemImage)
                    .font(.title3)
                    .foregroundStyle(Color.sightAccent)
                Text(mode.hint)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                Button(action: capture) {
                    Image(systemName: "camera.circle.fill")
                        .font(.system(size: 44))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.black, Color.sightAccent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Capture")
                .accessibilityHint(mode.hint)
            }
        }
    }
}

/// The cutout as a PNG with transparency, for the share sheet ("Save Image", Messages…).
struct Sticker: Transferable, @unchecked Sendable {
    let image: CutoutImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { sticker in
            guard let data = UIImage(cgImage: sticker.image.cgImage).pngData() else {
                throw CocoaError(.fileWriteUnknown)
            }
            return data
        }
    }
}
