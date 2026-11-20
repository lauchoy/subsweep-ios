import Foundation
import Observation
import StoreKit

@Observable
@MainActor
final class ProStore {
    static let productID = "com.lauchoy.subsweep.pro"

    private(set) var isPro: Bool
    private(set) var product: Product?
    var purchaseError: String?
    private let unlockedKey = "subsweep.pro.unlocked"
    private var updatesTask: Task<Void, Never>?

    init(forcePro: Bool = false) {
        isPro = forcePro || UserDefaults.standard.bool(forKey: unlockedKey)
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await transaction.finish()
                    await self?.refresh()
                }
            }
        }
    }

    var displayPrice: String { product?.displayPrice ?? "$4.99" }

    func load() async {
        product = try? await Product.products(for: [Self.productID]).first
        await refresh()
    }

    func refresh() async {
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement, transaction.productID == Self.productID {
                unlock()
                return
            }
        }
    }

    func purchase() async {
        purchaseError = nil
        if product == nil { await load() }
        guard let product else {
            #if targetEnvironment(simulator)
            // Simulator builds installed outside Xcode have no StoreKit config or sandbox,
            // so testers would be stuck at the free limit. scripts/check_device_build.sh proves this is compiled out.
            UserDefaults.standard.set(true, forKey: "subsweep.pro.simulatorFallbackUnlock")
            unlock()
            #else
            purchaseError = "The store isn't available right now. Try again later."
            #endif
            return
        }
        do {
            switch try await product.purchase() {
            case .success(.verified(let transaction)):
                await transaction.finish()
                unlock()
            case .success(.unverified):
                purchaseError = "The purchase couldn't be verified."
            default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    func restore() async {
        purchaseError = nil
        do {
            try await AppStore.sync()
        } catch StoreKitError.userCancelled {
            purchaseError = "Restore cancelled."
            return
        } catch {
            purchaseError = "Couldn't reach the App Store. Try again later."
            return
        }
        await refresh()
        if !isPro { purchaseError = "No SubSweep Pro purchase found for this Apple Account." }
    }

    /// Used by UI tests so the paywall can be exercised without a store sandbox.
    func unlockForTesting() { unlock() }

    private func unlock() {
        isPro = true
        UserDefaults.standard.set(true, forKey: unlockedKey)
    }
}
