import DesignSystem
import SightCore
import SwiftUI

/// A picked photo with what Sight found in it. Switching modes re-analyzes the same photo.
struct PhotoResultView: View {
    @Bindable var model: CameraViewModel

    var body: some View {
        NavigationStack {
            Group {
                if let photo = model.photo {
                    content(for: photo)
                }
            }
            .navigationTitle("Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { model.closePhoto() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func content(for photo: PhotoAnalysis) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(uiImage: photo.image)
                    .resizable()
                    .scaledToFit()
                    .overlay {
                        if case .text(let lines)? = photo.result {
                            TextBoxesOverlay(lines: lines, imageSize: photo.imageSize, contentMode: .fit)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .accessibilityLabel("The picked photo")

                ModePicker(modes: model.modes, selection: modeSelection)

                ResultCard(
                    mode: model.mode,
                    result: photo.result,
                    isWorking: photo.isAnalyzing,
                    didFail: photo.didFail,
                    copyableText: model.copyableText
                )

                if photo.latencyMilliseconds > 0 {
                    Label(
                        "Analyzed on device in \(SightFormat.milliseconds(photo.latencyMilliseconds))",
                        systemImage: "lock.shield"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
    }

    private var modeSelection: Binding<AnalysisMode> {
        Binding(get: { model.mode }, set: { model.select($0) })
    }
}
