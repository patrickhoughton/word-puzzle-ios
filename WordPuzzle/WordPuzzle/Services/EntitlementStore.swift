import Foundation
import Observation
import StoreKit

enum StoreError: Error {
    case failedVerification
    case productUnavailable
}

/// CONTEXT D-07: @Observable final class, matching the WordList convention from Phase 1.
/// MON-04: `isPremium` is derived from Transaction.currentEntitlements every time it is
/// refreshed. There is deliberately NO cached-flag-based premium storage anywhere
/// in this type — a cached flag is exactly what MON-04 forbids as a source of truth.
@Observable
final class EntitlementStore {

    /// CONTEXT D-04 (locked). Must match WordPuzzle.storekit and the App Store Connect
    /// product record byte-for-byte.
    static let unlimitedProductID = "com.patrickhoughton.wordpuzzle.unlimited"

    private(set) var isPremium: Bool = false
    private(set) var unlimitedProduct: Product?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = listenForTransactionUpdates()
    }

    deinit {
        // RESEARCH Pitfall 6: Transaction.updates never completes on its own. Without
        // this cancel the task (and this store) leak, and entitlement state bleeds
        // between test cases.
        updatesTask?.cancel()
    }

    // MARK: - Entitlement check (MON-04)

    /// D-08: called from `.task` on the WindowGroup so `isPremium` is authoritative on
    /// every app launch before any view renders meaningful content.
    func refreshEntitlements() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if transaction.productID == Self.unlimitedProductID {
                unlocked = true
            }
        }
        isPremium = unlocked
    }

    // MARK: - Product loading (MON-02)

    /// Resolves the non-consumable from StoreKit. Phase 4's paywall reads
    /// `unlimitedProduct.displayPrice` to show the localized price.
    func loadProduct() async {
        unlimitedProduct = try? await Product.products(for: [Self.unlimitedProductID]).first
    }

    // MARK: - Purchase (MON-02)

    /// Buys the unlimited unlock. Phase 4's paywall CTA calls this.
    /// Loads the product on demand if it has not been fetched yet.
    func purchaseUnlimited() async throws {
        if unlimitedProduct == nil {
            await loadProduct()
        }
        guard let product = unlimitedProduct else {
            throw StoreError.productUnavailable
        }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await refreshEntitlements()
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Restore (MON-03)

    /// Guideline 3.1.1 requires a visible Restore Purchases action. Phase 4's paywall
    /// button calls this. Uses AppStore.sync() — NOT the deprecated StoreKit 1
    /// the deprecated StoreKit 1 payment-queue restore API.
    func restore() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
    }

    // MARK: - Private

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        // NOTE: deliberately `Task { }`, not `Task.detached { }` as in the research
        // snippet. This class is MainActor-isolated (the app target sets
        // SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor), so an unstructured `Task`
        // inherits MainActor isolation and can touch `isPremium` and `checkVerified`
        // without actor-isolation diagnostics. A detached task cannot.
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                guard let transaction = try? self.checkVerified(result) else { continue }
                await transaction.finish()
                await self.refreshEntitlements()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}
