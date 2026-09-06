import Foundation
import StoreKit
import SwiftUI

@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()
    static let proProductID = "com.daveytodd.shot.pro"

    @Published private(set) var proProduct: Product?
    @Published private(set) var isPro = false
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = Task { await observeTransactions() }
        Task { await loadProducts(); await refreshEntitlements() }
    }

    deinit { updatesTask?.cancel() }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do { proProduct = try await Product.products(for: [Self.proProductID]).first }
        catch { errorMessage = "Unable to load Pro purchase options." }
    }

    func purchasePro() async {
        guard let product = proProduct else { return }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                isPro = true
            case .userCancelled, .pending: break
            @unknown default: break
            }
        } catch { errorMessage = "Purchase could not be completed." }
    }

    func restorePurchases() async { await refreshEntitlements() }

    func refreshEntitlements() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == Self.proProductID { isPro = transaction.revocationDate == nil }
        }
    }

    private func observeTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == Self.proProductID { isPro = transaction.revocationDate == nil }
            await transaction.finish()
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result { case .verified(let value): return value; case .unverified: throw StoreError.failedVerification }
    }

    private enum StoreError: Error { case failedVerification }
}

/// Ad-provider-neutral integration point. Add Google Mobile Ads, AppLovin, etc.
/// behind this API without ever placing an ad view in the live capture hierarchy.
@MainActor
final class AdManager: ObservableObject {
    @Published private(set) var isLoaded = false
    @Published private(set) var isShowing = false

    func prepareReviewAd() { isLoaded = true }
    func showInterstitialIfAvailable() { guard isLoaded else { return }; isShowing = true; isLoaded = false }
    func dismiss() { isShowing = false }
}

struct BannerAdPlaceholder: View {
    let isPro: Bool
    var body: some View {
        if !isPro {
            VStack(spacing: 4) {
                Text("ADVERTISEMENT").font(.caption2.monospaced()).foregroundStyle(.secondary)
                Text("Banner provider hook — review/export only").font(.caption).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity).frame(height: 50).background(Color(red: 0.06, green: 0.06, blue: 0.06))
        }
    }
}

struct ProUnlockView: View {
    @StateObject private var store = StoreManager.shared
    var body: some View {
        VStack(spacing: 12) {
            Label("Shot Pro", systemImage: "sparkles").font(.headline)
            Text("Remove ads and unlock ProRes export, full batch RAW ZIP, and custom curve presets.").font(.subheadline).multilineTextAlignment(.center).foregroundStyle(.secondary)
            if let product = store.proProduct {
                Button("Unlock Pro — \(product.displayPrice)") { Task { await store.purchasePro() } }.buttonStyle(.borderedProminent)
            } else { ProgressView() }
            Button("Restore Purchases") { Task { await store.restorePurchases() } }.font(.caption)
        }.padding().background(Color(red: 0.06, green: 0.06, blue: 0.06)).clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
