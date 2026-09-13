import AVFoundation
import CoreImage
import CoreMedia
import Foundation

/// Captures synchronized frames from the back wide and front TrueDepth cameras.
/// The manager emits either a BeReal-style composite or a picture-in-picture frame.
final class DualCameraTimelapseManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    enum Composition { case bereal, pictureInPicture }
    enum CameraError: Error { case unavailable, cannotAddInput, cannotAddOutput, notConfigured }

    let session = AVCaptureMultiCamSession()
    private let queue = DispatchQueue(label: "shot.dual-camera.capture")
    private let context = CIContext()
    private var backOutput: AVCaptureVideoDataOutput?
    private var frontOutput: AVCaptureVideoDataOutput?
    private var latestBack: CMSampleBuffer?
    private var latestFront: CMSampleBuffer?
    private var frameHandler: ((CVPixelBuffer, CMTime) -> Void)?
    private(set) var composition: Composition = .pictureInPicture

    func configure(composition: Composition = .pictureInPicture) throws {
        self.composition = composition
        guard AVCaptureMultiCamSession.isMultiCamSupported else { throw CameraError.unavailable }
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        guard let back = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let front = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front) else {
            throw CameraError.unavailable
        }
        let backInput = try AVCaptureDeviceInput(device: back)
        let frontInput = try AVCaptureDeviceInput(device: front)
        guard session.canAddInput(backInput), session.canAddInput(frontInput) else { throw CameraError.cannotAddInput }
        session.addInputWithNoConnections(backInput); session.addInputWithNoConnections(frontInput)

        let backOutput = makeOutput(); let frontOutput = makeOutput()
        guard session.canAddOutput(backOutput), session.canAddOutput(frontOutput) else { throw CameraError.cannotAddOutput }
        session.addOutputWithNoConnections(backOutput); session.addOutputWithNoConnections(frontOutput)
        guard let backPort = backInput.ports.first(where: { $0.mediaType == .video }),
              let frontPort = frontInput.ports.first(where: { $0.mediaType == .video }),
              let backConnection = AVCaptureConnection(inputPorts: [backPort], output: backOutput),
              let frontConnection = AVCaptureConnection(inputPorts: [frontPort], output: frontOutput) else { throw CameraError.cannotAddInput }
        guard session.canAddConnection(backConnection), session.canAddConnection(frontConnection) else { throw CameraError.cannotAddInput }
        session.addConnection(backConnection); session.addConnection(frontConnection)
        self.backOutput = backOutput; self.frontOutput = frontOutput
    }

    private func makeOutput() -> AVCaptureVideoDataOutput {
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: queue)
        return output
    }

    func start() { queue.async { if !self.session.isRunning { self.session.startRunning() } } }
    func stop() { queue.async { if self.session.isRunning { self.session.stopRunning() } } }

    func captureNextFrame(handler: @escaping (CVPixelBuffer, CMTime) -> Void) {
        queue.async { self.frameHandler = handler }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if output === backOutput { latestBack = sampleBuffer } else if output === frontOutput { latestFront = sampleBuffer }
        guard let back = latestBack, let front = latestFront,
              abs(CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(back) - CMSampleBufferGetPresentationTimeStamp(front))) < 0.1,
              let image = composite(back: back, front: front) else { return }
        frameHandler?(image, CMSampleBufferGetPresentationTimeStamp(back)); frameHandler = nil
        latestBack = nil; latestFront = nil
    }

    private func composite(back: CMSampleBuffer, front: CMSampleBuffer) -> CVPixelBuffer? {
        guard let backBuffer = CMSampleBufferGetImageBuffer(back), let frontBuffer = CMSampleBufferGetImageBuffer(front) else { return nil }
        let backImage = CIImage(cvPixelBuffer: backBuffer)
        let frontImage = CIImage(cvPixelBuffer: frontBuffer)
        let target = CGRect(x: 0, y: 0, width: backImage.extent.width, height: backImage.extent.height)
        let transformedFront: CIImage
        switch composition {
        case .bereal:
            transformedFront = frontImage.transformed(by: CGAffineTransform(scaleX: 0.28, y: 0.28).translatedBy(x: target.width * 2.55, y: target.height * 2.55))
        case .pictureInPicture:
            transformedFront = frontImage.transformed(by: CGAffineTransform(scaleX: 0.28, y: 0.28).translatedBy(x: target.width * 2.55, y: target.height * 2.55))
        }
        let result = backImage.composited(over: transformedFront)
        var buffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault, Int(target.width), Int(target.height), kCVPixelFormatType_32BGRA, nil, &buffer)
        if let buffer { context.render(result.cropped(to: target), to: buffer) }
        return buffer
    }
}
