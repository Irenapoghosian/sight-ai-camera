import DesignSystem
import SightCore
import SwiftUI

/// A labeled box around every detected object.
struct ObjectBoxesOverlay: View {
    let objects: [DetectedObject]
    let imageSize: CGSize
    let contentMode: OverlayGeometry.ContentMode

    var body: some View {
        GeometryReader { proxy in
            ForEach(Array(objects.enumerated()), id: \.offset) { _, object in
                let rect = OverlayGeometry.viewRect(
                    for: object.boundingBox,
                    imageSize: imageSize,
                    in: proxy.size,
                    contentMode: contentMode
                )
                ObjectBox(object: object, size: rect.size)
                    .position(x: rect.midX, y: rect.midY)
            }
        }
        .animation(.easeOut(duration: 0.15), value: objects)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct ObjectBox: View {
    let object: DetectedObject
    let size: CGSize

    var body: some View {
        let color = LabelPalette.color(for: object.label)
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .stroke(color, lineWidth: 2.5)
            .frame(width: size.width, height: size.height)
            .overlay(alignment: .topLeading) {
                Text("\(object.displayName) \(SightFormat.percent(object.confidence))")
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .foregroundStyle(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(color, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                    .fixedSize()
                    .offset(y: -20)
            }
    }
}

/// "Person ×2 · 94%" rows for the result card.
struct ObjectSummary: View {
    let objects: [DetectedObject]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(ResultRules.objectCounts(objects).prefix(4)) { entry in
                HStack(spacing: 10) {
                    Circle()
                        .fill(LabelPalette.color(for: entry.label))
                        .frame(width: 10, height: 10)
                    Text(entry.displayName)
                        .font(.subheadline.weight(.semibold))
                    if entry.count > 1 {
                        Text("×\(entry.count)")
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(SightFormat.percent(entry.bestConfidence))
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(entry.count > 1 ? "\(entry.displayName), \(entry.count)" : entry.displayName)
                .accessibilityValue(SightFormat.percent(entry.bestConfidence))
            }
        }
    }
}
