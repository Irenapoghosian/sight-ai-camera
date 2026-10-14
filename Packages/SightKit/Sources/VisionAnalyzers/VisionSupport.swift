import CoreImage
import CoreML
import SightCore
import Vision

extension AnalysisImage {
    /// A Vision handler that sees the image upright.
    func makeRequestHandler() -> VNImageRequestHandler {
        switch source {
        case .pixelBuffer(let buffer):
            VNImageRequestHandler(cvPixelBuffer: buffer, orientation: orientation, options: [:])
        case .cgImage(let image):
            VNImageRequestHandler(cgImage: image, orientation: orientation, options: [:])
        }
    }
}

extension AnalysisImage {
    /// The image as Core Image sees it, already rotated upright.
    func uprightCIImage() -> CIImage {
        switch source {
        case .pixelBuffer(let buffer):
            CIImage(cvPixelBuffer: buffer).oriented(orientation)
        case .cgImage(let image):
            CIImage(cgImage: image).oriented(orientation)
        }
    }
}

extension VNRequest {
    /// The simulator can't create a Neural Engine or GPU context for some Vision models,
    /// so run them on the CPU there. Real devices keep Apple's choice.
    func preferCPUOnSimulator() {
        #if targetEnvironment(simulator)
        guard let devices = try? supportedComputeStageDevices[.main] else { return }
        let cpu = devices.first { device in
            if case .cpu = device { return true }
            return false
        }
        if let cpu { setComputeDevice(cpu, for: .main) }
        #endif
    }
}
