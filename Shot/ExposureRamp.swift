import Foundation

/// A bounded, low-pass exposure controller for long transitions.
struct ExposureRamp {
    var smoothing: Double = 0.12
    var maximumStepEV: Double = 0.20
    private(set) var currentEV: Double = 0

    mutating func update(measuredLuma: Double, targetLuma: Double = 0.38) -> Double {
        guard measuredLuma > 0, targetLuma > 0 else { return currentEV }
        let desired = log2(targetLuma / measuredLuma)
        let delta = max(-maximumStepEV, min(maximumStepEV, desired - currentEV))
        currentEV += delta * smoothing
        return currentEV
    }
}
