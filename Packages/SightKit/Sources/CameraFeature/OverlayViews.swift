import DesignSystem
import SightCore
import SwiftUI

/// Outlines every piece of text Sight read, on top of the image it came from.
struct TextBoxesOverlay: View {
    let lines: [RecognizedText]
    let imageSize: CGSize
    let contentMode: OverlayGeometry.ContentMode

    var body: some View {
        GeometryReader { proxy in
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                let rect = OverlayGeometry.viewRect(
                    for: line.boundingBox,
                    imageSize: imageSize,
                    in: proxy.size,
                    contentMode: contentMode
                )
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.sightAccent.opacity(0.14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(Color.sightAccent, lineWidth: 1.5)
                    )
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            }
        }
        .animation(.easeOut(duration: 0.12), value: lines)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A capsule segmented control that reads well over the camera.
struct ModePicker: View {
    let modes: [AnalysisMode]
    @Binding var selection: AnalysisMode
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 4) {
            ForEach(modes) { mode in
                Button {
                    withAnimation(.snappy) { selection = mode }
                } label: {
                    Label(mode.title, systemImage: mode.systemImage)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .foregroundStyle(selection == mode ? Color.black : Color.white)
                        .background {
                            if selection == mode {
                                Capsule()
                                    .fill(Color.sightAccent)
                                    .matchedGeometryEffect(id: "selection", in: namespace)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == mode ? .isSelected : [])
            }
        }
        .padding(4)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
