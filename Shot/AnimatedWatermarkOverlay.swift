import SwiftUI

struct AnimatedWatermarkOverlay: View {
    enum Corner { case topLeading, topTrailing, bottomLeading, bottomTrailing }
    var interval: TimeInterval = 4
    var size: CGFloat = 34
    @State private var corner: Corner = .bottomTrailing

    var body: some View {
        GeometryReader { proxy in
            ShotDLogo(size: size)
                .padding(16)
                .position(position(in: proxy.size))
                .animation(.easeInOut(duration: 0.45), value: cornerKey)
        }
        .allowsHitTesting(false)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { return }
                withAnimation { corner = nextCorner }
            }
        }
    }

    private var cornerKey: Int {
        switch corner { case .topLeading: 0; case .topTrailing: 1; case .bottomTrailing: 2; case .bottomLeading: 3 }
    }
    private var nextCorner: Corner {
        switch corner { case .topLeading: .topTrailing; case .topTrailing: .bottomTrailing; case .bottomTrailing: .bottomLeading; case .bottomLeading: .topLeading }
    }
    private func position(in size: CGSize) -> CGPoint {
        let inset = self.size / 2 + 16
        switch corner {
        case .topLeading: return CGPoint(x: inset, y: inset)
        case .topTrailing: return CGPoint(x: size.width - inset, y: inset)
        case .bottomLeading: return CGPoint(x: inset, y: size.height - inset)
        case .bottomTrailing: return CGPoint(x: size.width - inset, y: size.height - inset)
        }
    }
}

struct ShotDLogo: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .fill(Color.orange)
            Path { path in
                let w = size; let inset = w * 0.25
                path.move(to: CGPoint(x: inset, y: inset)); path.addLine(to: CGPoint(x: w * 0.53, y: inset))
                path.addCurve(to: CGPoint(x: w * 0.53, y: w - inset), control1: CGPoint(x: w * 0.92, y: inset), control2: CGPoint(x: w * 0.92, y: w - inset))
                path.addLine(to: CGPoint(x: inset, y: w - inset)); path.closeSubpath()
            }
            .stroke(Color.black, style: StrokeStyle(lineWidth: size * 0.11, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.28), radius: 3)
        .accessibilityLabel("Shot watermark")
    }
}
