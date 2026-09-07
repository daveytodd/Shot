import Foundation
import SwiftUI

@MainActor final class CaptureSessionStore: ObservableObject {
    @Published var interval: TimeInterval = 30
    @Published var duration: TimeInterval = 90 * 60
    @Published var frameCount = 0
    @Published var isCapturing = false
    @Published var startedAt: Date?
    @Published var useRAW = false
    @Published var rampExposure = true
    @Published var iso: Float = 100
    @Published var shutter: Double = 1.0 / 60.0
    @Published var error: String?
    var timer: Task<Void, Never>?
    func start(camera: CameraEngine, gimbal: DJIGimbalManager) async {
        guard !isCapturing else { return }; isCapturing = true; startedAt = .now; frameCount = 0
        timer = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled && isCapturing {
                await camera.capturePhoto(iso: iso, shutter: shutter)
                frameCount += 1
                if gimbal.isPaired { await gimbal.advanceSweep() }
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }
    func stop() { isCapturing = false; timer?.cancel(); timer = nil }
}
