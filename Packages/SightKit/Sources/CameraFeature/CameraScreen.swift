import CameraCapture
import DesignSystem
import PhotosUI
import SightCore
import SwiftUI
import UIKit

/// The whole app in one screen: the live camera, what Sight sees, the mode picker and a photo button.
public struct CameraScreen: View {
    @Bindable var model: CameraViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var pickedItem: PhotosPickerItem?

    public init(model: CameraViewModel) {
        self.model = model
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            cameraLayer
                .ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                Spacer()
                bottomPanel
            }
            .padding(.horizontal, 16)
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .task { await model.start() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: Task { await model.start() }
            case .background: model.stop()
            default: break
            }
        }
        .onChange(of: pickedItem) { _, item in
            loadPhoto(item)
        }
        .sheet(item: $model.photo) { _ in
            PhotoResultView(model: model)
        }
        .alert("Something went wrong", isPresented: errorIsPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
        .sensoryFeedback(.selection, trigger: model.mode)
    }

    // MARK: - Layers

    @ViewBuilder
    private var cameraLayer: some View {
        switch model.cameraState {
        case .running:
            if let session = model.captureSession {
                CameraPreview(session: session)
                    .overlay {
                        ResultOverlay(result: model.result, imageSize: model.frameSize, contentMode: .fill)
                    }
            }
        case .denied:
            PermissionView(pickedItem: $pickedItem)
        case .unavailable(let message):
            NoCameraView(message: message, pickedItem: $pickedItem)
        case .idle, .starting:
            ProgressView()
                .tint(.white)
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Text("Sight")
                .font(.title3.weight(.bold))
                .foregroundStyle(.sightGradient)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if model.cameraState == .running {
                MetricsPill(model.metrics)
            }
            PhotosPicker(selection: $pickedItem, matching: .images) {
                Image(systemName: "photo.on.rectangle")
                    .font(.body.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Analyze a photo")
            if model.cameraState == .running {
                CircleIconButton(
                    model.isPaused ? "Resume" : "Pause",
                    systemImage: model.isPaused ? "play.fill" : "pause.fill"
                ) {
                    model.togglePause()
                }
            }
        }
        .padding(.top, 8)
    }

    private var bottomPanel: some View {
        VStack(spacing: 14) {
            if model.cameraState == .running {
                ResultCard(
                    mode: model.mode,
                    result: model.result,
                    isPaused: model.isPaused,
                    copyableText: model.copyableText
                )
            }
            ModePicker(modes: model.modes, selection: modeSelection)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Helpers

    private var modeSelection: Binding<AnalysisMode> {
        Binding(get: { model.mode }, set: { model.select($0) })
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { model.errorMessage != nil },
            set: { isPresented in
                if !isPresented { model.errorMessage = nil }
            }
        )
    }

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            // Cleared so the same photo can be picked again.
            defer { pickedItem = nil }
            guard
                let data = try? await item.loadTransferable(type: Data.self),
                let image = UIImage(data: data)
            else {
                model.errorMessage = "This photo couldn't be opened."
                return
            }
            await model.analyze(photo: image)
        }
    }
}
