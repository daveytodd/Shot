import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: CaptureSessionStore
    @EnvironmentObject private var camera: CameraEngine
    @EnvironmentObject private var gimbal: DJIGimbalManager
    var body: some View { NavigationStack { ZStack { ShotTheme.background.ignoresSafeArea(); VStack(spacing: 22) { header; Spacer(); status; Button { Task { if store.isCapturing { store.stop() } else { await store.start(camera: camera, gimbal: gimbal) } } } label: { Image(systemName: store.isCapturing ? "stop.fill" : "record.circle").font(.system(size: 88)).foregroundStyle(ShotTheme.accent) }; Text(store.isCapturing ? "CAPTURING" : "READY").font(.caption.monospaced()).foregroundStyle(ShotTheme.accent); Spacer(); controls } .padding() } .navigationTitle("SHOT").toolbar { ToolbarItem(placement: .topBarTrailing) { Button { gimbal.scan() } label: { Image(systemName: gimbal.isPaired ? "figure.wave" : "antenna.radiowaves.left.and.right") } } } }.task { await camera.configure(); camera.start() } }
    private var header: some View { HStack { Label(gimbal.isPaired ? (gimbal.deviceName ?? "GIMBAL") : "HANDHELD / TRIPOD", systemImage: gimbal.isPaired ? "link" : "camera").font(.caption.monospaced()); Spacer(); Text("\(store.frameCount) FRAMES").font(.caption.monospaced()) } }
    private var status: some View { VStack { Text("SUNRISE TIMELAPSE").font(.headline.monospaced()); Text("Every \(Int(store.interval)) seconds").font(.subheadline).foregroundStyle(.secondary) } }
    private var controls: some View { HStack { Stepper("Interval \(Int(store.interval))s", value: $store.interval, in: 5...600, step: 5).font(.caption.monospaced()); Toggle("RAMP", isOn: $store.rampExposure).labelsHidden() }.tint(ShotTheme.accent) }
}
