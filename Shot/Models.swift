import Foundation
import SwiftUI

@MainActor final class SessionStore: ObservableObject {
    @Published var interval: Double = 30
    @Published var durationMinutes: Double = 120
    @Published var nightMode = true
    @Published var useRAW = true
    @Published var useProRAW = true
    @Published var useHEIF = true
    @Published var isRunning = false
    @Published var photoCount = 0
    @Published var sessionStarted: Date?
    @Published var batteryLevel: Float = 1
    @Published var estimatedStorageGB: Double = 0

    var accent: Color { nightMode ? .red : .orange }
}

struct HistogramView: View {
    let values: [CGFloat]
    var color: Color = .red
    var body: some View {
        GeometryReader { proxy in
            Path { path in
                guard values.count > 1 else { return }
                let step = proxy.size.width / CGFloat(values.count - 1)
                path.move(to: CGPoint(x: 0, y: proxy.size.height))
                for (index, value) in values.enumerated() {
                    path.addLine(to: CGPoint(x: CGFloat(index) * step, y: proxy.size.height * (1 - value)))
                }
                path.addLine(to: CGPoint(x: proxy.size.width, y: proxy.size.height))
                path.closeSubpath()
            }.fill(color.opacity(0.28))
        }
        .overlay(Rectangle().stroke(color.opacity(0.45), lineWidth: 1))
    }
}
