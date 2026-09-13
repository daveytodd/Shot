import SwiftUI

@main
struct ShotApp: App {
    @StateObject private var session = CaptureSessionStore()
    @StateObject private var camera = CameraEngine()
    @StateObject private var gimbal = DJIGimbalManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session).environmentObject(camera).environmentObject(gimbal)
                .preferredColorScheme(.dark).tint(ShotTheme.accent)
        }
    }
}

enum ShotTheme {
    static let background = Color.black
    static let surface = Color(white: 0.07)
    static let accent = Color(red: 0.98, green: 0.72, blue: 0.22)
}
