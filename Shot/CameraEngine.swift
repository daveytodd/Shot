import AVFoundation
import SwiftUI

@MainActor final class CameraEngine: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let queue = DispatchQueue(label: "shot.camera")
    @Published private(set) var isReady = false
    @Published private(set) var authorizationDenied = false
    @Published var exposureBias: Float = 0
    func configure() async {
        guard await AVCaptureDevice.requestAccess(for: .video) else { authorizationDenied = true; return }
        queue.async { [weak self] in
            guard let self, !session.isRunning else { return }
            session.beginConfiguration(); session.sessionPreset = .photo
            defer { session.commitConfiguration() }
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back), let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input), session.canAddOutput(photoOutput) else { return }
            session.addInput(input); session.addOutput(photoOutput); isReady = true
        }
    }
    func start() { queue.async { [weak self] in self?.session.startRunning() } }
    func stop() { queue.async { [weak self] in self?.session.stopRunning() } }
    func capturePhoto(iso: Float, shutter: Double) async {
        guard let input = session.inputs.first as? AVCaptureDeviceInput else { return }
        let device = input.device
        try? device.lockForConfiguration(); defer { device.unlockForConfiguration() }
        let clampedISO = min(max(iso, device.activeFormat.minISO), device.activeFormat.maxISO)
        let duration = CMTime(seconds: shutter, preferredTimescale: 1_000_000)
        if device.activeFormat.isExposureModeSupported(.custom) { device.setExposureModeCustom(duration: duration, iso: clampedISO, completionHandler: nil) }
        photoOutput.capturePhoto(with: AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc]), delegate: self)
    }
}
extension CameraEngine: AVCapturePhotoCaptureDelegate {}
