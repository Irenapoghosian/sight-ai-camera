// swift-tools-version: 5.10
import PackageDescription

/// Sight is split into small modules with one-way dependencies:
///
///   CameraFeature ──▶ CameraCapture ──▶ SightCore ◀── VisionAnalyzers
///         │                                 ▲
///         └──────────▶ DesignSystem ────────┘
///
/// The feature only knows the `CameraSource` and `FrameAnalyzer` protocols;
/// the app target plugs in the real camera and the Vision analyzers.
let package = Package(
    name: "SightKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SightCore", targets: ["SightCore"]),
        .library(name: "CameraCapture", targets: ["CameraCapture"]),
        .library(name: "VisionAnalyzers", targets: ["VisionAnalyzers"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "CameraFeature", targets: ["CameraFeature"]),
    ],
    targets: [
        // Results, geometry, performance math and the analyzer contract. No UIKit, no Vision.
        .target(name: "SightCore"),
        // AVFoundation capture session and the live preview layer.
        .target(name: "CameraCapture", dependencies: ["SightCore"]),
        // Apple Vision requests behind the `FrameAnalyzer` protocol.
        .target(name: "VisionAnalyzers", dependencies: ["SightCore"]),
        // Colors, formatters and reusable SwiftUI pieces.
        .target(name: "DesignSystem", dependencies: ["SightCore"]),
        // The camera screen, its view model and the photo result sheet.
        .target(name: "CameraFeature", dependencies: ["SightCore", "CameraCapture", "DesignSystem"]),

        .testTarget(name: "SightCoreTests", dependencies: ["SightCore"]),
        .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem"]),
        .testTarget(name: "CameraFeatureTests", dependencies: ["CameraFeature", "SightCore", "CameraCapture"]),
    ]
)
