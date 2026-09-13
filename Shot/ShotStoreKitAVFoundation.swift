import Combine
import Foundation
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    static let productIDs: Set<String> = ["com.daveytodd.shot.pro.monthly", "com.daveytodd.shot.pro.yearly"]

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isPro = false
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = observeTransactionUpdates()
        Task { await refresh() }
    }

    deinit { updatesTask?.cancel() }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: Self.productIDs).sorted { $0.price < $1.price }
            var active = Set<String>()
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result, Self.productIDs.contains(transaction.productID) {
                    active.insert(transaction.productID)
                }
            }
            purchasedProductIDs = active
            isPro = !active.isEmpty
            error = nil
        } catch { caughtError in
            self.error = caughtError
        }
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            switch try await product.purchase() {
            case .success(.verified(let transaction)):
                await transaction.finish()
                await refresh()
                return true
            case .success(.unverified(_, let verificationError)):
                self.error = verificationError
                return false
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch { caughtError in
            self.error = caughtError
            return false
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refresh()
        } catch { caughtError in
            self.error = caughtError
        }
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.refresh()
                }
            }
        }
    }
}

extension SubscriptionManager {
    var monthlyProduct: Product? { products.first { $0.id == "com.daveytodd.shot.pro.monthly" } }
    var yearlyProduct: Product? { products.first { $0.id == "com.daveytodd.shot.pro.yearly" } }
}
