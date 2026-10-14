import DesignSystem
import PhotosUI
import SwiftUI
import UIKit

/// Shown when camera access is turned off.
struct PermissionView: View {
    @Binding var pickedItem: PhotosPickerItem?
    @Environment(\.openURL) private var openURL

    var body: some View {
        StatusMessage(
            systemImage: "camera.fill",
            title: "Camera access is off",
            message: "Sight analyzes the camera image on your iPhone. Nothing is uploaded."
        ) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.sightAccent)
            .foregroundStyle(.black)

            PhotosPicker("Choose a photo instead", selection: $pickedItem, matching: .images)
                .tint(Color.sightAccent)
        }
    }
}

/// Shown on the simulator and on devices without a camera: Sight still works with photos.
struct NoCameraView: View {
    let message: String
    @Binding var pickedItem: PhotosPickerItem?

    var body: some View {
        StatusMessage(systemImage: "photo.on.rectangle.angled", title: "Photos mode", message: message) {
            PhotosPicker(selection: $pickedItem, matching: .images) {
                Label("Choose a photo", systemImage: "photo")
                    .font(.headline)
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.sightAccent)
            .foregroundStyle(.black)
        }
    }
}

struct StatusMessage<Actions: View>: View {
    let systemImage: String
    let title: String
    let message: String
    @ViewBuilder let actions: Actions

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.sightGradient)
            Text(title)
                .font(.title2.weight(.bold))
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            VStack(spacing: 12) {
                actions
            }
            .padding(.top, 8)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
