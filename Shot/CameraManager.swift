import AVFoundation
import Combine
import CoreImage
import UIKit

@MainActor final class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var device: AVCaptureDevice?
    private var ramp = ExposureRamp()
    @Published private(set) var isConfigured = false
    @Published private(set) var isRunning = false
    @Published private(set) var histogram = Array(repeating: CGFloat(0), count: 64)
    @Published private(set) var lastError: String?

    func configure() async {
        guard !isConfigured else { return }
        session.beginConfiguration(); defer { session.commitConfiguration() }
        session.sessionPreset = .photo
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            lastError = "No rear camera available"; return
        }
        device = camera
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) { session.addInput(input) }
            if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }
            if session.canAddOutput(videoOutput) {
                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "shot.histogram"))
                session.addOutput(videoOutput)
            }
            isConfigured = true
        } catch { lastError = error.localizedDescription }
    }

    func start() { guard isConfigured, !session.isRunning else { return }; session.startRunning(); isRunning = true }
    func stop() { guard session.isRunning else { return }; session.stopRunning(); isRunning = false }

    func capture(useRAW: Bool, useProRAW: Bool, completion: @escaping (Result<AVCapturePhoto, Error>) -> Void) {
        let settings: AVCapturePhotoSettings
        if useProRAW, photoOutput.isAppleProRAWEnabled,
           let format = photoOutput.availableRawPhotoPixelFormatTypes.first {
            settings = AVCapturePhotoSettings(rawPixelFormatType: format)
        } else if useRAW, let format = photoOutput.availableRawPhotoPixelFormatTypes.first {
            settings = AVCapturePhotoSettings(rawPixelFormatType: format)
        } else {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        }
        photoOutput.capturePhoto(with: settings, delegate: PhotoDelegate(completion: completion))
    }

    func applyExposureCompensation(_ ev: Float) {
        guard let device else { return }
        do { try device.lockForConfiguration(); defer { device.unlockForConfiguration() }; device.setExposureTargetBias(ev) }
        catch { lastError = error.localizedDescription }
    }
}

private final class PhotoDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    let completion: (Result<AVCapturePhoto, Error>) -> Void
    init(completion: @escaping (Result<AVCapturePhoto, Error>) -> Void) { self.completion = completion }
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error { completion(.failure(error)) } else { completion(.success(photo)) }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ci = CIImage(cvPixelBuffer: buffer)
        let extent = ci.extent
        let context = CIContext()
        guard let avg = context.createCGImage(ci, from: extent)?.dataProvider?.data else { return }
        let bytes = CFDataGetBytePtr(avg); let length = CFDataGetLength(avg)
        guard let bytes, length > 0 else { return }
        let sample = min(1, max(0, Double(bytes[0]) / 255))
        Task { @MainActor in self.histogram = (0..<64).map { CGFloat(max(0, sample - Double($0) / 128)) } }
    }
}
