import SightCore
import SwiftUI

/// A frosted card that stays readable over a moving camera image.
public struct GlassCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(.white.opacity(0.12))
            )
    }
}

/// A thin capsule filled to `value` (0…1).
public struct ConfidenceBar: View {
    private let value: Float

    public init(_ value: Float) {
        self.value = value
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.15))
                Capsule()
                    .fill(.sightGradient)
                    .frame(width: proxy.size.width * CGFloat(min(max(value, 0), 1)))
            }
        }
        .frame(height: 6)
        .animation(.snappy, value: value)
        .accessibilityHidden(true)
    }
}

/// "15 FPS · 23 ms" — how fast the on-device models are running.
public struct MetricsPill: View {
    private let metrics: PerformanceMetrics

    public init(_ metrics: PerformanceMetrics) {
        self.metrics = metrics
    }

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "bolt.fill")
                .foregroundStyle(Color.sightAccent)
            Text(SightFormat.framesPerSecond(metrics.framesPerSecond))
            Text("·").foregroundStyle(.secondary)
            Text(SightFormat.milliseconds(metrics.latencyMilliseconds))
        }
        .font(.caption.weight(.semibold).monospacedDigit())
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Performance")
        .accessibilityValue(
            "\(SightFormat.framesPerSecond(metrics.framesPerSecond)), \(SightFormat.milliseconds(metrics.latencyMilliseconds)) per frame"
        )
    }
}

/// A round icon button used over the camera image.
public struct CircleIconButton: View {
    private let systemImage: String
    private let label: String
    private let action: () -> Void

    public init(_ label: String, systemImage: String, action: @escaping () -> Void) {
        self.label = label
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
