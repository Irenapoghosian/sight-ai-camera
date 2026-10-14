import DesignSystem
import SightCore
import SwiftUI
import UIKit

/// What Sight found, shown the same way for the camera and for photos.
struct ResultCard: View {
    let mode: AnalysisMode
    let result: AnalysisResult?
    var isPaused = false
    var isWorking = false
    var didFail = false
    var copyableText: String?

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                if isPaused {
                    Label("Paused", systemImage: "pause.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.sightAccent)
                }
                content
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch result {
        case .classifications(let labels)? where !labels.isEmpty:
            ClassificationList(labels: labels)
        case .objects(let objects)? where !objects.isEmpty:
            ObjectSummary(objects: objects)
        case .text(let lines)? where !lines.isEmpty:
            TextSummary(lines: lines, copyableText: copyableText)
        default:
            placeholder
        }
    }

    private var placeholder: some View {
        HStack(spacing: 10) {
            if isWorking {
                ProgressView()
            } else {
                Image(systemName: didFail ? "exclamationmark.triangle" : mode.systemImage)
                    .foregroundStyle(Color.sightAccent)
            }
            Text(placeholderText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(minHeight: 32)
    }

    private var placeholderText: String {
        if isWorking { return "Looking…" }
        if didFail { return "This image couldn't be analyzed." }
        if result == nil { return mode.hint }
        switch mode {
        case .classify: return "Nothing recognized yet"
        case .objects: return "No objects found yet"
        case .text: return "No text found yet"
        }
    }
}

/// The top labels with their confidence.
struct ClassificationList: View {
    let labels: [Classification]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(labels) { label in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(label.displayName)
                            .font(label.id == labels.first?.id ? Font.headline : Font.subheadline)
                        Spacer()
                        Text(SightFormat.percent(label.confidence))
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    ConfidenceBar(label.confidence)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label.displayName)
                .accessibilityValue(SightFormat.percent(label.confidence))
            }
        }
    }
}

/// How much text was found, a preview of it and a Copy button.
struct TextSummary: View {
    let lines: [RecognizedText]
    let copyableText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(lines.count == 1 ? "1 line" : "\(lines.count) lines", systemImage: "text.alignleft")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if let copyableText {
                    CopyTextButton(text: copyableText)
                }
            }
            Text(copyableText ?? "")
                .font(.callout)
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
    }
}

/// Copies to the clipboard and confirms with a checkmark and a tap.
struct CopyTextButton: View {
    let text: String
    @State private var copies = 0
    @State private var showsCheckmark = false

    var body: some View {
        Button {
            UIPasteboard.general.string = text
            copies += 1
            showsCheckmark = true
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                showsCheckmark = false
            }
        } label: {
            Label(showsCheckmark ? "Copied" : "Copy", systemImage: showsCheckmark ? "checkmark" : "doc.on.doc")
                .font(.subheadline.weight(.semibold))
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.sightAccent)
        .foregroundStyle(.black)
        .sensoryFeedback(.success, trigger: copies)
    }
}
