import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: SessionStore
    @EnvironmentObject private var camera: CameraManager
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack { Color.black.ignoresSafeArea(); main }
                .navigationTitle("SHOT")
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showingSettings = true } label: { Image(systemName: "slider.horizontal.3") }.tint(store.accent) } }
                .sheet(isPresented: $showingSettings) { SettingsView().environmentObject(store) }
        }
        .task { await camera.configure(); camera.start() }
    }

    private var main: some View {
        VStack(spacing: 20) {
            HistogramView(values: camera.histogram, color: store.accent).frame(height: 100).padding(.horizontal)
            HStack { metric("INTERVAL", "\(Int(store.interval))s"); metric("FRAMES", "\(store.photoCount)"); metric("BATTERY", "\(Int(store.batteryLevel * 100))%") }
            Spacer()
            Button { toggle() } label: { Image(systemName: store.isRunning ? "stop.fill" : "record.circle").font(.system(size: 84)).foregroundStyle(store.accent) }
            Text(store.isRunning ? "CAPTURING" : "READY").font(.caption.monospaced()).foregroundStyle(store.accent)
        }.padding()
    }
    private func metric(_ title: String, _ value: String) -> some View { VStack { Text(value).font(.title2.monospacedDigit()); Text(title).font(.caption2.monospaced()).foregroundStyle(.secondary) }.frame(maxWidth: .infinity) }
    private func toggle() { store.isRunning.toggle(); store.sessionStarted = store.isRunning ? Date() : nil }
}

struct SettingsView: View {
    @EnvironmentObject private var store: SessionStore
    var body: some View { NavigationStack { Form { Section("Capture") { Slider(value: $store.interval, in: 20...60, step: 1); Text("Interval: \(Int(store.interval)) seconds"); Toggle("RAW / ProRAW", isOn: $store.useRAW); Toggle("HEIF fallback", isOn: $store.useHEIF) }; Section("Night safety") { Toggle("Red low-light mode", isOn: $store.nightMode) } }.scrollContentBackground(.hidden).background(Color.black).navigationTitle("Settings") } }
}
