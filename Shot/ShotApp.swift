import SwiftUI

@main
struct ShotApp: App {
    @StateObject private var store = SessionStore()
    @StateObject private var camera = CameraManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(camera)
                .preferredColorScheme(.dark)
        }
    }
}
