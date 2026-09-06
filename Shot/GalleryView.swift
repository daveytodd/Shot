import SwiftUI

struct GalleryView: View {
    @StateObject private var store = StoreManager.shared
    @StateObject private var ads = AdManager()
    @State private var showingProResNotice = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Text("REVIEW & EXPORT").font(.caption.monospaced()).foregroundStyle(.red)
                    RoundedRectangle(cornerRadius: 8).fill(Color(red: 0.05, green: 0.05, blue: 0.05)).frame(height: 220).overlay(Text("SESSION PREVIEW").font(.caption.monospaced()).foregroundStyle(.secondary))
                    BannerAdPlaceholder(isPro: store.isPro)
                    HStack {
                        Button("Export HEVC") { }
                        Button("Export ProRes") { guard store.isPro else { showingProResNotice = true; return } }
                    }.buttonStyle(.bordered)
                    Button("Export RAW frames as ZIP") { guard store.isPro else { showingProResNotice = true; return } }.buttonStyle(.bordered)
                    if !store.isPro { ProUnlockView() }
                }.padding()
            }.background(Color.black).navigationTitle("Gallery")
        }
        .task { ads.prepareReviewAd() }
        .alert("Shot Pro required", isPresented: $showingProResNotice) { Button("OK", role: .cancel) {} } message: { Text("Upgrade to unlock ProRes export, full batch RAW ZIP, and custom curve presets.") }
    }
}
