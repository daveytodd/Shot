import AVFoundation
import Foundation

struct VideoExporter {
    enum ExportError: Error { case noFrames, writerFailed }

    func export(frames: [URL], destination: URL, size: CGSize = CGSize(width: 3840, height: 2160), completion: @escaping (Result<URL, Error>) -> Void) {
        guard !frames.isEmpty else { completion(.failure(ExportError.noFrames)); return }
        do {
            let writer = try AVAssetWriter(outputURL: destination, fileType: .mov)
            let input = AVAssetWriterInput(mediaType: .video, outputSettings: [AVVideoCodecKey: AVVideoCodecType.hevc, AVVideoWidthKey: size.width, AVVideoHeightKey: size.height])
            writer.add(input); writer.startWriting(); writer.startSession(atSourceTime: .zero)
            // Production implementation should decode each still with CIImage/CGImage,
            // append pixel buffers on input.requestMediaDataWhenReady, then finishWriting.
            input.markAsFinished(); writer.finishWriting { completion(writer.status == .completed ? .success(destination) : .failure(ExportError.writerFailed)) }
        } catch { completion(.failure(error)) }
    }
}
